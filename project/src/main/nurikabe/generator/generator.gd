class_name Generator

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS
const NEIGHBOR_DIRS_WITH_SELF: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS_WITH_SELF

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

const INITIAL_OPEN_ISLAND_EDGE_WEIGHT: float = 1.5
const INITIAL_OPEN_ISLAND_CORNER_WEIGHT: float = 0.25
const INITIAL_OPEN_ISLAND_INTERIOR_WEIGHT: float = 0.5

const TARGET_BREAK_IN_COUNT: int = 2
const TARGET_MUTATE_STEPS: int = 10
const ALMOST_FILLED_THRESHOLD: int = 10
const MAX_STUCK_COUNT: int = 25

const UNKNOWN_REASON: Placement.Reason = Placement.Reason.UNKNOWN

## break-in techniques
const INITIAL_OPEN_ISLAND: Placement.Reason = Placement.Reason.INITIAL_OPEN_ISLAND

## standard techniques
const ISLAND_GUIDE: Placement.Reason = Placement.Reason.ISLAND_GUIDE
const ISLAND_EXPANSION: Placement.Reason = Placement.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Placement.Reason = Placement.Reason.ISLAND_MOAT
const SEALED_ISLAND_CLUE: Placement.Reason = Placement.Reason.SEALED_ISLAND_CLUE
const WALL_GUIDE: Placement.Reason = Placement.Reason.WALL_GUIDE

## advanced techniques
const ISLAND_BUFFER: Placement.Reason = Placement.Reason.ISLAND_BUFFER

## repair techniques
const FIX_TINY_SPLIT_WALL: Placement.Reason = Placement.Reason.FIX_TINY_SPLIT_WALL
const FIX_UNCLUED_ISLAND: Placement.Reason = Placement.Reason.FIX_UNCLUED_ISLAND

## mutation techniques
const MUTATION: Placement.Reason = Placement.Reason.MUTATION

const MAX_CHECKPOINT_RETRIES: int = 2
const MAX_GENERATION_FACTOR: float = 0.9
const BIFURCATION_CHANCE: float = 0.3

## Exponent controlling bias toward priority expansion of small islands.[br]
## 	0.0 = expand all islands[br]
## 	1.0 = bias expansion toward smaller islands[br]
## 	2.0 = heavily bias expansion towards smaller islands
const PRIORITY_EXPANSION_SMALL_ISLAND_BIAS: float = 0.8

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var board: GeneratorBoard:
	set(value):
		board = value
		solver.board = board.solver_board
var log_enabled: bool = false
var placements: PlacementBatch = PlacementBatch.new()
var solver: Solver = Solver.new()
var step_count: int = 0
var mutate_steps: int = 0
var difficulty: float = 0.5

var _break_in_count: int = 0
var _rng_ops: RngOps = RngOps.new(rng)
var _successfully_mutated: bool = false

var _priority_techniques: TechniqueScheduler = TechniqueScheduler.new([
	{"callable": generate_open_island_expansion, "weight": 1.0},
	{"callable": generate_all_sealed_mystery_island_clues, "weight": 1.0},
	{"callable": generate_all_sealed_unclued_island_clues, "weight": 1.0},
])

var _basic_techniques: TechniqueScheduler = TechniqueScheduler.new([
	{"callable": generate_open_island_moat, "weight": 0.1},
	{"callable": generate_wall_guide, "weight": 1.0},
	{"callable": generate_island_guide, "weight": 1.0},
	{"callable": generate_island_buffer, "weight": 0.5},
])

var _advanced_techniques: TechniqueScheduler = TechniqueScheduler.new([
])

var _recovery_techniques: TechniqueScheduler = TechniqueScheduler.new([
	{"callable": fix_tiny_split_wall, "weight": 1.0},
	{"callable": fix_all_unclued_islands, "weight": 1.0},
])

var _checkpoint_stack: Array[Dictionary] = []
var _event_log: Array[String] = []
var _mutator: PuzzleMutator

func _init() -> void:
	solver.set_generation_strategy()
	for scheduler: TechniqueScheduler in [
			_priority_techniques, _basic_techniques, _advanced_techniques, _recovery_techniques]:
		scheduler.rng = rng


func consume_events() -> Array[String]:
	var result: Array[String] = _event_log
	_event_log = []
	return result


func clear() -> void:
	placements.clear()
	solver.clear()
	if solver.board:
		solver.board.clear()
	step_count = 0
	mutate_steps = 0
	
	_checkpoint_stack.clear()
	_break_in_count = 0
	_event_log.clear()
	_successfully_mutated = false
	
	if _mutator:
		_mutator.cleanup()
		_mutator = null


func step_until_done() -> void:
	var stuck_state: Dictionary[String, Variant] = {}
	
	while true:
		step()
		
		if check_stuck(stuck_state):
			break
		
		if not is_done():
			continue
		var validation_result: SolverBoard.ValidationResult \
				= board.solver_board.validate(SolverBoard.VALIDATE_STRICT)
		if validation_result.error_count == 0:
			# filled with no validation errors
			break


func check_stuck(stuck_state: Dictionary[String, Variant]) -> bool:
	if not stuck_state.has("steps"):
		stuck_state["steps"] = 0
	if not stuck_state.has("min_empty_cells"):
		stuck_state["min_empty_cells"] = 999999
	if not stuck_state.has("stuck_count"):
		stuck_state["stuck_count"] = 0
	
	var result: bool = false
	
	stuck_state["steps"] += 1
	if stuck_state["steps"] >= max_steps():
		result = true
	elif board.empty_cells.size() < stuck_state["min_empty_cells"]:
		stuck_state["stuck_count"] = 0
		stuck_state["min_empty_cells"] = board.empty_cells.size()
	elif _successfully_mutated:
		stuck_state["stuck_count"] = 0
	else:
		stuck_state["stuck_count"] += 1
		@warning_ignore("integer_division")
		if stuck_state["stuck_count"] > MAX_STUCK_COUNT / 2:
			_log_event("stuck (%s/%s)" % [stuck_state["stuck_count"], MAX_STUCK_COUNT])
		if stuck_state["stuck_count"] > MAX_STUCK_COUNT:
			result = true
	
	return result


func max_steps() -> int:
	@warning_ignore("narrowing_conversion")
	return solver.board.cells.size() * MAX_GENERATION_FACTOR


func is_done() -> bool:
	return board.is_filled() and not has_validation_errors() and mutate_steps >= TARGET_MUTATE_STEPS


func step() -> void:
	_successfully_mutated = false
	
	var allow_bifurcation: bool = rng.randf() < BIFURCATION_CHANCE
	var solver_pass: Solver.SolverPass = \
			Solver.SolverPass.BIFURCATION if allow_bifurcation else Solver.SolverPass.GLOBAL
	
	# mess with the clues, and run the solver
	attempt_generation_step()
	apply_changes()
	step_solver_until_done(solver_pass)
	
	if mutate_steps >= 1:
		# mutating; checkpoints no longer apply
		pass
	elif not has_validation_errors():
		# no errors; push the checkpoint and add more clues
		push_checkpoint()
	else:
		# errors; try our recovery techniques on the next loop, but roll back if they keep failing
		if not has_remaining_retries():
			while not has_remaining_retries():
				pop_checkpoint()
			load_checkpoint()
			step_solver_until_done(solver_pass)
		if not _checkpoint_stack.is_empty():
			_checkpoint_stack.back()["retry_count"] += 1
			if log_enabled:
				_log_event("retry %s/%s" % [_checkpoint_stack.back()["retry_count"], MAX_CHECKPOINT_RETRIES])
	step_count += 1


func step_solver_until_done(solver_pass: Solver.SolverPass = Solver.SolverPass.BIFURCATION) -> void:
	while true:
		if has_validation_errors():
			break
		solver.step(solver_pass)
		if not solver.deductions.has_changes():
			break
		apply_solver_changes()
	apply_solver_changes()


func apply_solver_changes() -> void:
	if log_enabled:
		for i in solver.deductions.deductions.size():
			var deduction: Deduction = solver.deductions.deductions[i]
			_log_event("%s %s" % [board.version + i, str(deduction)])
	
	solver.apply_changes()


func has_validation_errors() -> bool:
	return solver.board.validate(SolverBoard.VALIDATE_SIMPLE).error_count > 0


func has_remaining_retries() -> bool:
	return _checkpoint_stack.is_empty() or _checkpoint_stack.back()["retry_count"] < MAX_CHECKPOINT_RETRIES


func attempt_generation_step() -> void:
	if mutate_steps >= 1 or board.solver_board.empty_cells.size() <= ALMOST_FILLED_THRESHOLD:
		attempt_mutation_step()
	else:
		attempt_construction_step()


func attempt_construction_step() -> void:
	if not placements.has_changes() and _break_in_count < TARGET_BREAK_IN_COUNT:
		generate_break_in()
	
	if not placements.has_changes() and has_validation_errors():
		for recovery_technique: Callable in _recovery_techniques.next_cycle():
			recovery_technique.call()
			if placements.has_changes():
				break
	
	if not placements.has_changes():
		for priority_technique: Callable in _priority_techniques.next_cycle():
			priority_technique.call()
			if placements.has_changes():
				break
	
	if not placements.has_changes():
		for advanced_technique: Callable in _advanced_techniques.next_cycle():
			advanced_technique.call()
			if placements.has_changes():
				break
	
	if not placements.has_changes():
		for basic_technique: Callable in _basic_techniques.next_cycle():
			basic_technique.call()
			if placements.has_changes():
				break


func generate_wall_guide() -> void:
	var open_walls: Array[CellGroup] = board.walls.filter(func(wall: CellGroup) -> bool:
			return wall.liberties.size() == 2)
	if open_walls.is_empty():
		return
	
	_rng_ops.shuffle(open_walls)
	for open_wall: CellGroup in open_walls:
		var shuffled_liberties: Array[Vector2i] = open_wall.liberties.duplicate()
		_rng_ops.shuffle(shuffled_liberties)
		for liberty: Vector2i in shuffled_liberties:
			# bifurcate; add the clue and see if there is a contradiction
			var temp_solver: Solver = _create_temp_solver()
			temp_solver.board.set_clue(liberty, CELL_MYSTERY_CLUE)
			temp_solver.deduce_all_island_dividers()
			temp_solver.apply_changes()
			var validation_result: String = temp_solver.board.validate_local([liberty])
			temp_solver.board.cleanup()
			if "j" in validation_result:
				# new clue connects to an existing clue
				continue
			if "s" in validation_result:
				# new clue splits a wall
				continue
			
			add_placement(liberty, CELL_MYSTERY_CLUE, WALL_GUIDE)
			break
		if placements.has_changes():
			break


func generate_island_guide() -> void:
	var open_islands: Array[CellGroup] = board.islands.filter(func(wall: CellGroup) -> bool:
			return wall.liberties.size() == 2)
	if open_islands.is_empty():
		return
	
	_rng_ops.shuffle(open_islands)
	for open_island: CellGroup in open_islands:
		var guide_cells: Array[Vector2i] = find_island_guide_cell_candidates(open_island)
		if not guide_cells:
			continue
		
		var guide_cell: Vector2i = _rng_ops.pick_random(guide_cells)
		add_placement(guide_cell, CELL_MYSTERY_CLUE, ISLAND_GUIDE)
		break


func generate_island_buffer() -> void:
	var open_islands: Array[CellGroup] = board.islands.filter(func(wall: CellGroup) -> bool:
			return wall.liberties.size() == 2)
	if open_islands.is_empty():
		return
	
	_rng_ops.shuffle(open_islands)
	for open_island: CellGroup in open_islands:
		for diagonal_dir: Vector2i in NEIGHBOR_DIRS:
			var diagonal: Vector2i = open_island.liberties.front() + diagonal_dir
			if diagonal.distance_to(open_island.liberties[1]) != 1:
				continue
			if board.get_cell(diagonal) != CELL_EMPTY:
				continue
			if open_island.clue == 0 or open_island.clue == -1:
				continue
			attempt_island_buffer_from(open_island, diagonal)
			if placements.has_changes():
				break
		if placements.has_changes():
			break


func attempt_island_buffer_from(island: CellGroup, diagonal: Vector2i, dir_priority: Array[Vector2i] = []) -> void:
	if dir_priority.is_empty():
		dir_priority = NEIGHBOR_DIRS.duplicate()
		_rng_ops.shuffle(dir_priority)
	
	for neighbor_dir: Vector2i in dir_priority:
		var neighbor: Vector2i = diagonal + neighbor_dir
		if board.get_cell(neighbor) != CELL_EMPTY:
			continue
		if _has_neighbor_island(neighbor):
			continue
		if board.solver_board.get_island_chain_map().has_chain_conflict(neighbor, 1):
			continue
		
		add_placement(neighbor, CELL_MYSTERY_CLUE, ISLAND_BUFFER, [island.root])
		add_given_change(diagonal, CELL_WALL, ISLAND_BUFFER, [island.root])
		var clue_cell: Vector2i = _find_clue_cell(island)
		add_clue_minimum_change(clue_cell, island.size() + 1)
		break


func generate_open_island_expansion() -> void:
	var open_islands: Array[CellGroup] = []
	
	# find islands with unfulfilled clue minimums
	for cell: Vector2i in board.clue_minimums:
		var island: CellGroup = board.get_island_for_cell(cell)
		if island.liberties.size() == 1 \
				and island.size() < board.clue_minimums[cell] \
				and not island in open_islands:
			open_islands.append(island)
	
	# find small islands which can expand
	if open_islands.is_empty():
		open_islands = board.islands.filter(func(island: CellGroup) -> bool:
				if island.liberties.size() != 1:
					return false
				return rng.randf() < pow(1.0 / island.size(), PRIORITY_EXPANSION_SMALL_ISLAND_BIAS))
	
	if open_islands:
		var open_island: CellGroup = _rng_ops.pick_random(open_islands)
		add_given_change(open_island.liberties[0], CELL_ISLAND, ISLAND_EXPANSION)


func generate_open_island_moat() -> void:
	var mystery_islands: Array[CellGroup] = board.islands.filter(func(island: CellGroup) -> bool:
			return island.clue == CELL_MYSTERY_CLUE)
	if not mystery_islands:
		return
	
	# larger islands are chosen more frequently
	var weights_array: Array[float] = []
	for i in mystery_islands.size():
		weights_array.append(mystery_islands.size() - 1)
	_rng_ops.shuffle_weighted(mystery_islands, weights_array)
	var mystery_island: CellGroup = mystery_islands[0]
	
	var clue_cell: Vector2i = _find_clue_cell(mystery_island)
	var new_wall_cells: Array[Vector2i] = mystery_island.liberties.duplicate()
	
	# bifurcate; set the clue and see if there is a contradiction
	var temp_solver: Solver = _create_temp_solver()
	temp_solver.board.set_clue(clue_cell, mystery_island.size())
	temp_solver.deduce_island(temp_solver.board.get_island_for_cell(clue_cell))
	var local_cells: Array[Vector2i] = new_wall_cells.duplicate()
	local_cells.append(clue_cell)
	var validation_result: String = temp_solver.board.validate_local(local_cells)
	temp_solver.board.cleanup()
	
	if "p" in validation_result:
		pass
	else:
		add_placement(clue_cell, mystery_island.size(), ISLAND_MOAT)
		for liberty: Vector2i in new_wall_cells:
			add_placement(liberty, CELL_WALL, ISLAND_MOAT)


func generate_all_sealed_mystery_island_clues() -> void:
	for island: CellGroup in board.islands:
		if not island.liberties.is_empty() or island.clue != CELL_MYSTERY_CLUE:
			continue
		
		var clue_cell: Vector2i = _find_clue_cell(island)
		add_placement(clue_cell, island.size(), SEALED_ISLAND_CLUE)


func generate_all_sealed_unclued_island_clues() -> void:
	for island: CellGroup in board.islands:
		if not island.liberties.is_empty() or island.clue != -1:
			continue
		
		var clue_cell: Vector2i = _rng_ops.pick_random(island.cells)
		add_placement(clue_cell, island.size(), SEALED_ISLAND_CLUE)


## Adds a new clue cell constrained to expand through a single open liberty. Most Nurikabe puzzles begin with at least
## one such forced expansion.
func generate_break_in() -> void:
	for _mercy in 10:
		# island_plan keys:
		# - seed_cell: Vector2i
		# - open_liberty: Vector2i
		# - supporting_clues: Dictionary[Vector2i, bool]
		var island_plan: Dictionary[String, Variant] = {}
		_select_initial_open_island_candidate(island_plan)
		_plan_initial_open_island_walls(island_plan)
		
		if island_plan.has("seed_cell") and island_plan.has("supporting_clues"):
			add_placement(island_plan["seed_cell"], CELL_MYSTERY_CLUE, INITIAL_OPEN_ISLAND)
			placements.placements.back().break_in = true
			for other_clue: Vector2i in island_plan["supporting_clues"]:
				add_placement(other_clue, CELL_MYSTERY_CLUE, ISLAND_GUIDE)
			break


func apply_changes() -> void:
	if log_enabled:
		for i in placements.size():
			var placement: Placement = placements.placements[i]
			_log_event("%s %s" % [board.version + i, str(placement)])
		for i in placements.clue_minimum_changes.size():
			var clue_minimum_change: Dictionary[String, Variant] = placements.clue_minimum_changes[i]
			_log_event("clue_minimum %s -> %s" % [clue_minimum_change["pos"], clue_minimum_change["value"]])
	
	for placement: Placement in placements.placements:
		if NurikabeUtils.is_clue(placement.value):
			board.set_clue(placement.pos, placement.value)
		elif placement.given:
			if placement.value == CELL_EMPTY:
				board.unset_given(placement.pos)
			else:
				board.set_given(placement.pos, placement.value)
		elif board.has_clue(placement.pos) and placement.value == CELL_ISLAND:
			board.set_clue(placement.pos, 0)
		else:
			board.set_cell(placement.pos, placement.value)
		if placement.break_in:
			_break_in_count += 1
	for clue_minimum_change: Dictionary[String, Variant] in placements.clue_minimum_changes:
		var pos: Vector2i = clue_minimum_change["pos"]
		var value: int = clue_minimum_change["value"]
		if value == 0:
			board.clue_minimums.erase(pos)
		else:
			board.clue_minimums[pos] = value
	placements.clear()


func push_checkpoint() -> void:
	_checkpoint_stack.append({
		"break_in_count": _break_in_count,
		"clues": board.clues.duplicate(),
		"givens": board.givens.duplicate(),
		"clue_minimums": board.clue_minimums.duplicate(),
		"retry_count": 0,
	})


func load_checkpoint() -> void:
	var occupied_cells: Array[Vector2i] = board.cells.keys()
	board.clear()
	placements.clear()
	solver.clear()
	if not _checkpoint_stack.is_empty():
		for cell: Vector2i in occupied_cells:
			board.set_cell(cell, CELL_EMPTY)
		var new_clues: Dictionary[Vector2i, int] = _checkpoint_stack.back()["clues"]
		for clue: Vector2i in new_clues:
			board.set_clue(clue, new_clues[clue])
		var new_givens: Dictionary[Vector2i, int] = _checkpoint_stack.back()["givens"]
		for given: Vector2i in new_givens:
			board.set_given(given, new_givens[given])
		var new_clue_minimums: Dictionary[Vector2i, int] = _checkpoint_stack.back()["clue_minimums"]
		board.clue_minimums = new_clue_minimums.duplicate()
		var new_break_in_count: int = _checkpoint_stack.back()["break_in_count"]
		_break_in_count = new_break_in_count
	else:
		_break_in_count = 0
	
	if log_enabled:
		_log_event("%s loaded checkpoint #%s" % [board.version, _checkpoint_stack.size()])


func pop_checkpoint() -> void:
	if not _checkpoint_stack.is_empty():
		_checkpoint_stack.pop_back()


func add_placement(pos: Vector2i, value: int,
		reason: Placement.Reason = Placement.Reason.UNKNOWN,
		sources: Array[Vector2i] = []) -> void:
	placements.add_placement(pos, value, reason, sources)


func add_given_change(pos: Vector2i, value: int,
		reason: Placement.Reason = Placement.Reason.UNKNOWN,
		sources: Array[Vector2i] = []) -> void:
	placements.add_placement(pos, value, reason, sources)
	placements.placements.back().given = true


func add_clue_minimum_change(pos: Vector2i, value: int) -> void:
	placements.add_clue_minimum_change(pos, value)


func find_island_guide_cell_candidates(island: CellGroup) -> Array[Vector2i]:
	var guide_cell_candidates: Dictionary[Vector2i, bool] = {}
	for liberty: Vector2i in island.liberties:
		for neighbor_dir in NEIGHBOR_DIRS:
			var guide_cell_candidate: Vector2i = liberty + neighbor_dir
			if not board.get_cell(guide_cell_candidate) == CELL_EMPTY:
				# guide cell must be empty
				continue
			if _has_neighbor_island(guide_cell_candidate):
				# guide cell can't be next to any other islands
				continue
			if board.solver_board.get_island_chain_map().has_chain_conflict(guide_cell_candidate, 1):
				# guide cell can't form a chain
				continue
			var remaining_liberties: Array[Vector2i] = []
			for remaining_liberty: Vector2i in island.liberties:
				if remaining_liberty.distance_to(guide_cell_candidate) > 1:
					remaining_liberties.append(remaining_liberty)
			if remaining_liberties.is_empty():
				# guide cell can't constrain the island to 0 liberties
				continue
			guide_cell_candidates[guide_cell_candidate] = true
	return guide_cell_candidates.keys()


func fix_tiny_split_wall() -> void:
	var validation_result: SolverBoard.ValidationResult \
			= solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	if validation_result.split_walls.size() != 1:
		return
	
	var split_wall_cell: Vector2i = validation_result.split_walls[0]
	var islands: Array[CellGroup] = _get_neighbor_islands(split_wall_cell)
	_rng_ops.shuffle(islands)
	islands.sort_custom(func(a: CellGroup, b: CellGroup) -> bool:
		return a.size() < b.size())
	var erased_island: CellGroup = islands[0]
	var clue_cell: Vector2i = _find_clue_cell(erased_island)
	var temp_solver: Solver = _create_temp_solver()
	temp_solver.board.groups_need_rebuild = true
	temp_solver.board.clues.erase(clue_cell)
	for cell: Vector2i in board.cells:
		if temp_solver.board.get_cell(cell) == CELL_WALL:
			temp_solver.board.set_cell(cell, CELL_EMPTY)
	for cell: Vector2i in erased_island.cells:
		temp_solver.board.set_cell(cell, CELL_EMPTY)
	temp_solver.step_until_done(Solver.SolverPass.GLOBAL)
	while true:
		temp_solver.step()
		if not solver.deductions.has_changes():
			break
		temp_solver.apply_changes()
	validation_result = temp_solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	
	if validation_result.error_count > 0:
		temp_solver.board.cleanup()
		return
	
	for cell: Vector2i in board.cells:
		if board.get_cell(cell) != temp_solver.board.get_cell(cell):
			add_placement(cell, temp_solver.board.get_cell(cell), FIX_TINY_SPLIT_WALL, [split_wall_cell])
			if board.has_clue(cell) and not temp_solver.board.has_clue(cell):
				add_clue_minimum_change(cell, 0)
	temp_solver.board.cleanup()


func fix_all_unclued_islands() -> void:
	var validation_result: SolverBoard.ValidationResult \
			= solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	if validation_result.unclued_islands.size() == 0:
		return
	
	var unclued_islands: Array[CellGroup] = []
	for cell: Vector2i in validation_result.unclued_islands:
		var unclued_island: CellGroup = board.get_island_for_cell(cell)
		if not unclued_islands.has(unclued_island):
			unclued_islands.append(unclued_island)
	
	for unclued_island: CellGroup in unclued_islands:
		var unclued_island_cells: Array[Vector2i] = \
				GeneratorUtils.best_clue_cells_for_unclued_island(board.solver_board, unclued_island)
		var unclued_island_cell: Vector2i = _rng_ops.pick_random(unclued_island_cells)
		add_placement(unclued_island_cell, unclued_island.size(), FIX_UNCLUED_ISLAND)


func attempt_mutation_step() -> void:
	if _mutator == null:
		# initialize the mutator and strip generator-only constraints
		if board.givens or board.clue_minimums:
			for given: Vector2i in board.givens:
				add_given_change(given, CELL_EMPTY, MUTATION)
			for clue_minimum: Vector2i in board.clue_minimums:
				add_clue_minimum_change(clue_minimum, 0)
		var prepared_board: SolverBoard = prepare_board_for_mutation()
		_mutator = PuzzleMutator.new(prepared_board)
		prepared_board.cleanup()
		_mutator.rng = rng
	_mutator.difficulty = difficulty
	
	# advance the mutator one step
	_mutator.step()
	mutate_steps += 1
	var mutated_board: SolverBoard = _mutator.get_best_board()
	
	# apply the results
	for cell: Vector2i in board.cells:
		if mutated_board.has_clue(cell) and mutated_board.get_clue(cell) != board.get_clue(cell):
			add_placement(cell, mutated_board.get_clue(cell), MUTATION)
		elif mutated_board.get_cell(cell) != board.get_cell(cell):
			add_placement(cell, mutated_board.get_cell(cell), MUTATION)
		elif board.has_clue(cell) and not mutated_board.has_clue(cell):
			add_placement(cell, CELL_ISLAND, MUTATION)
	solver.metrics = _mutator.get_best_solver().metrics.duplicate(true)
	
	if placements.size() > 0:
		_successfully_mutated = true
		_log_event("fitness->%0.1f" % [_mutator.get_best_fitness()])


func prepare_board_for_mutation() -> SolverBoard:
	# expand islands to fill their liberties
	var prepared_board: SolverBoard = board.solver_board.get_flooded_board()
	
	# renumber islands to match their size
	for island: CellGroup in prepared_board.islands:
		if island.clue == 0:
			continue
		if island.clue == island.size():
			continue
		var clue_cells: Array[Vector2i] = island.cells.filter(func(cell: Vector2i) -> bool:
			return prepared_board.has_clue(cell))
		for cell: Vector2i in clue_cells:
			prepared_board.set_clue(cell, island.size())
	
	return prepared_board


func _create_temp_solver() -> Solver:
	var temp_solver: Solver = Solver.new()
	temp_solver.set_generation_strategy()
	temp_solver.board = board.solver_board.duplicate()
	return temp_solver


func _find_clue_cell(island: CellGroup) -> Vector2i:
	return board.solver_board.find_clue_cell(island)


func _get_neighbor_islands(cell: Vector2i) -> Array[CellGroup]:
	var neighbor_islands: Array[CellGroup] = []
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if board.get_cell(neighbor) != CELL_ISLAND:
			continue
		var neighbor_island: CellGroup = board.solver_board.get_island_for_cell(neighbor)
		if not neighbor_islands.has(neighbor_island):
			neighbor_islands.append(neighbor_island)
	return neighbor_islands


func _has_neighbor_island(cell: Vector2i) -> bool:
	var has_neighbor_island: bool = false
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if board.get_cell(neighbor) != CELL_ISLAND:
			continue
		has_neighbor_island = true
		break
	return has_neighbor_island


## Selects an initial open-island candidate: a new clue cell constrained to expand through a single open liberty. Most
## Nurikabe puzzles begin with at least one such forced expansion.
## [br]
## island_plan keys: [br]
## - seed_cell: Vector2i [br]
## - open_liberty: Vector2i [br]
## - supporting_clues: Dictionary[Vector2i, bool] [br]
func _select_initial_open_island_candidate(island_plan: Dictionary[String, Variant]) -> void:
	var corner_cells: Array[Vector2i] = []
	var edge_cells: Array[Vector2i] = []
	var interior_cells: Array[Vector2i] = []
	for cell: Vector2i in board.empty_cells:
		if _has_neighbor_island(cell):
			continue
		if board.solver_board.get_island_chain_map().has_chain_conflict(cell, 1):
			continue
		
		var empty_neighbor_cell_count: int = _empty_neighbor_cell_count(cell)
		match empty_neighbor_cell_count:
			2: corner_cells.append(cell)
			3: edge_cells.append(cell)
			4: interior_cells.append(cell)
	
	var potential_cells: Array[Vector2i]
	var weights := PackedFloat32Array([
		INITIAL_OPEN_ISLAND_CORNER_WEIGHT,
		INITIAL_OPEN_ISLAND_EDGE_WEIGHT,
		INITIAL_OPEN_ISLAND_INTERIOR_WEIGHT,
	])
	match rng.rand_weighted(weights):
		0: potential_cells = corner_cells
		1: potential_cells = edge_cells
		2: potential_cells = interior_cells
	if potential_cells.is_empty():
		potential_cells = board.cells.keys()
	if potential_cells.is_empty():
		return
	var seed_cell: Vector2i = _rng_ops.pick_random(potential_cells)
	
	var potential_preserved_liberties: Array[Vector2i] = []
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = seed_cell + neighbor_dir
		var neighbor_value: int = board.get_cell(neighbor)
		if neighbor_value == CELL_EMPTY:
			potential_preserved_liberties.append(neighbor)
	
	if potential_preserved_liberties.is_empty():
		return
	var open_liberty: Vector2i = _rng_ops.pick_random(potential_preserved_liberties)
	
	island_plan["seed_cell"] = seed_cell
	island_plan["open_liberty"] = open_liberty


## Augments the open-island candidate with supporting clues. These additional clues constrain the surrounding walls so
## that the island may expand only through its designated open liberty.
## [br]
## island_plan keys: [br]
## - seed_cell: Vector2i [br]
## - open_liberty: Vector2i [br]
## - supporting_clues: Dictionary[Vector2i, bool] [br]
func _plan_initial_open_island_walls(island_plan: Dictionary[String, Variant]) -> void:
	if not island_plan.has("seed_cell") or not island_plan.has("open_liberty"):
		return
	
	var seed_cell: Vector2i = island_plan["seed_cell"]
	var open_liberty: Vector2i = island_plan["open_liberty"]
	var initial_wall_cells: Dictionary[Vector2i, bool] = {}
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = seed_cell + neighbor_dir
		if neighbor == open_liberty:
			continue
		if board.get_cell(neighbor) != CELL_EMPTY:
			continue
		initial_wall_cells[neighbor] = true
	
	# If the island's surrounding wall is in a corner, it inevitably results in a split wall.
	if initial_wall_cells.keys().any(func(cell: Vector2i) -> bool:
			var empty_neighbor_cell_count: int = _empty_neighbor_cell_count(cell)
			return empty_neighbor_cell_count <= 2):
		return
	
	var supporting_clues: Dictionary[Vector2i, bool] = {}
	var mercy: int = 0
	var remaining_wall_cells: Dictionary[Vector2i, bool] = initial_wall_cells.duplicate()
	while not remaining_wall_cells.is_empty() and mercy < 10:
		mercy += 1
		var other_wall: Vector2i = _rng_ops.pick_random(remaining_wall_cells.keys())
		var other_clue: Vector2i = NurikabeUtils.POS_NOT_FOUND
		for potential_other_clue_dir: Vector2i in NEIGHBOR_DIRS.duplicate():
			var potential_other_clue: Vector2i = other_wall + potential_other_clue_dir
			if potential_other_clue == seed_cell:
				continue
			if potential_other_clue.distance_to(open_liberty) <= 1:
				continue
			if board.get_cell(potential_other_clue) != CELL_EMPTY:
				continue
			if _has_neighbor_island(potential_other_clue):
				continue
			if board.solver_board.get_island_chain_map().has_chain_conflict(potential_other_clue, 1):
				continue
			var adjacent_other_wall_count: int = 0
			for adjacent_other_wall_dir: Vector2i in NEIGHBOR_DIRS:
				var adjacent_other_wall: Vector2i = potential_other_clue + adjacent_other_wall_dir
				if remaining_wall_cells.has(adjacent_other_wall):
					adjacent_other_wall_count += 1
			if adjacent_other_wall_count >= 2:
				other_clue = potential_other_clue
				break
			elif other_clue == NurikabeUtils.POS_NOT_FOUND:
				other_clue = potential_other_clue
		
		if other_clue == NurikabeUtils.POS_NOT_FOUND:
			continue
		supporting_clues[other_clue] = true
		for removed_other_wall_dir: Vector2i in NEIGHBOR_DIRS:
			var removed_other_wall: Vector2i = other_clue + removed_other_wall_dir
			if remaining_wall_cells.has(removed_other_wall):
				remaining_wall_cells.erase(removed_other_wall)
	
	if not remaining_wall_cells.is_empty():
		return
	
	var new_clues: Array[Vector2i] = []
	new_clues.append_array(supporting_clues.keys())
	new_clues.append(seed_cell)
	if initial_wall_cells.is_empty():
		return
	var bfs_walls: Array[Vector2i] = board.solver_board.perform_bfs([initial_wall_cells.keys().front()],
		func(c: Vector2i) -> bool:
			var cell_value: int = board.get_cell(c)
			return cell_value == CELL_WALL or (cell_value == CELL_EMPTY and not new_clues.has(c)))
	if not initial_wall_cells.keys().all(
		func(c: Vector2i) -> bool:
			return bfs_walls.has(c)):
		return
	
	island_plan["supporting_clues"] = supporting_clues


func _empty_neighbor_cell_count(cell: Vector2i) -> int:
	var count: int = 0
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		var neighbor_value: int = board.get_cell(neighbor)
		if neighbor_value == CELL_EMPTY:
			count += 1
	return count


func _log_event(msg: String) -> void:
	_event_log.append("%s-%s" % [step_count, msg])
