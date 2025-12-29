class_name Solver

enum SolverPass {
	NONE,
	LOCAL,
	GLOBAL,
	BIFURCATION,
}

const BIFURCATION_DEPTH: int = 8

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

const UNKNOWN_REASON: Deduction.Reason = Deduction.Reason.UNKNOWN

## starting techniques
const ISLAND_OF_ONE: Deduction.Reason = Deduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Deduction.Reason = Deduction.Reason.ADJACENT_CLUES

## basic techniques
const CORNER_BUFFER: Deduction.Reason = Deduction.Reason.CORNER_BUFFER
const CORNER_ISLAND: Deduction.Reason = Deduction.Reason.CORNER_ISLAND
const ISLAND_BUBBLE: Deduction.Reason = Deduction.Reason.ISLAND_BUBBLE
const ISLAND_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_BUFFER
const ISLAND_CHOKEPOINT: Deduction.Reason = Deduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: Deduction.Reason = Deduction.Reason.ISLAND_CONNECTOR
const ISLAND_DIVIDER: Deduction.Reason = Deduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: Deduction.Reason = Deduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Deduction.Reason = Deduction.Reason.ISLAND_MOAT
const ISLAND_SNUG: Deduction.Reason = Deduction.Reason.ISLAND_SNUG
const POOL_CHOKEPOINT: Deduction.Reason = Deduction.Reason.POOL_CHOKEPOINT
const POOL_TRIPLET: Deduction.Reason = Deduction.Reason.POOL_TRIPLET
const UNCLUED_LIFELINE: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE
const UNREACHABLE_CELL: Deduction.Reason = Deduction.Reason.UNREACHABLE_CELL
const WALL_BUBBLE: Deduction.Reason = Deduction.Reason.WALL_BUBBLE
const WALL_CONNECTOR: Deduction.Reason = Deduction.Reason.WALL_CONNECTOR
const WALL_EXPANSION: Deduction.Reason = Deduction.Reason.WALL_EXPANSION
const WALL_WEAVER: Deduction.Reason = Deduction.Reason.WALL_WEAVER
const BORDER_HUG: Deduction.Reason = Deduction.Reason.BORDER_HUG

## advanced techniques
const ASSUMPTION: Deduction.Reason = Deduction.Reason.ASSUMPTION
const ISLAND_BATTLEGROUND: Deduction.Reason = Deduction.Reason.ISLAND_BATTLEGROUND
const ISLAND_RELEASE: Deduction.Reason = Deduction.Reason.ISLAND_RELEASE
const ISLAND_STRANGLE: Deduction.Reason = Deduction.Reason.ISLAND_STRANGLE
const WALL_STRANGLE: Deduction.Reason = Deduction.Reason.WALL_STRANGLE

const FUN_TRIVIAL: Deduction.FunAxis = Deduction.FunAxis.FUN_TRIVIAL
const FUN_FAST: Deduction.FunAxis = Deduction.FunAxis.FUN_FAST
const FUN_NOVELTY: Deduction.FunAxis = Deduction.FunAxis.FUN_NOVELTY
const FUN_THINK: Deduction.FunAxis = Deduction.FunAxis.FUN_THINK
const FUN_BIFURCATE: Deduction.FunAxis = Deduction.FunAxis.FUN_BIFURCATE

## how unfun is it to bifurcate incorrectly? 0.0 = no fun; 1.0 = as fun as bifurcating correctly
const BAD_BIFURCATION_FUN_FACTOR: float = 0.25

var verbose: bool = false

var deductions: DeductionBatch = DeductionBatch.new()
var board: SolverBoard:
	set(value):
		board = value

var metrics: Dictionary[String, Variant] = {}

var _slow_strategy_iterator: StrategyIterator = StrategyIterator.new([
	deduce_all_clued_island_snugs,
	deduce_all_wall_chokepoints,
	deduce_all_island_chokepoints,
	deduce_all_clue_chokepoints,
	deduce_all_unreachable_squares,
	deduce_unclued_lifeline,
])

var _bifurcation_iterator: StrategyIterator = StrategyIterator.new([
	bifurcate_all_wall_strangles,
	bifurcate_all_island_strangles,
	bifurcate_all_island_battlegrounds,
	bifurcate_all_island_releases,
])

var _touched_cells: Dictionary[Vector2i, bool] = {}
var _cumulative_bifurcation_fun: float = 0.0

func add_deduction(pos: Vector2i, value: int,
		reason: Deduction.Reason = UNKNOWN_REASON,
		sources: Array[Vector2i] = []) -> void:
	deductions.add_deduction(pos, value, reason, sources)


func add_fun(fun_axis: Deduction.FunAxis, value: float) -> void:
	deductions.add_fun(fun_axis, value)


## Use only deductions that remain valid if new clues are added.
func set_generation_strategy() -> void:
	_slow_strategy_iterator = StrategyIterator.new([
		deduce_all_clued_island_snugs,
		deduce_all_wall_chokepoints,
		deduce_all_clue_chokepoints,
	])

	_bifurcation_iterator = StrategyIterator.new([
		bifurcate_all_wall_strangles,
		bifurcate_all_island_strangles,
		bifurcate_all_island_battlegrounds,
		bifurcate_all_island_releases,
	])


## Use all deductions, including those that may be invalidated by new clues.
func set_solve_strategy() -> void:
	_slow_strategy_iterator = StrategyIterator.new([
		deduce_all_clued_island_snugs,
		deduce_all_wall_chokepoints,
		deduce_all_island_chokepoints,
		deduce_all_clue_chokepoints,
		deduce_all_unreachable_squares,
		deduce_unclued_lifeline,
	])

	_bifurcation_iterator = StrategyIterator.new([
		bifurcate_all_wall_strangles,
		bifurcate_all_island_strangles,
		bifurcate_all_island_battlegrounds,
		bifurcate_all_island_releases,
	])


func apply_changes() -> void:
	if not metrics.has("fun"):
		metrics["fun"] = {} as Dictionary[Deduction.FunAxis, float]
	for key: Deduction.FunAxis in deductions.fun:
		if not metrics["fun"].has(key):
			metrics["fun"][key] = 0
		metrics["fun"][key] += deductions.fun[key]
	
	var changes: Array[Dictionary] = deductions.get_changes()
	board.set_cells(changes)
	deductions.clear()


func clear() -> void:
	deductions.clear()
	metrics.clear()


func get_changes() -> Array[Dictionary]:
	return deductions.get_changes()


func step_until_done(solver_pass: SolverPass = SolverPass.BIFURCATION) -> void:
	while true:
		step(solver_pass)
		if not deductions.has_changes():
			break
		apply_changes()


func step(solver_pass: SolverPass = SolverPass.BIFURCATION) -> void:
	# local techniques; we run these each time we expand a group
	if not deductions.has_changes() and solver_pass >= SolverPass.LOCAL:
		var touched_walls: Dictionary[CellGroup, bool] = {}
		var touched_islands: Dictionary[CellGroup, bool] = {}
		for touched_cell in _touched_cells:
			var touched_value: int = board.get_cell(touched_cell)
			if touched_value == CELL_WALL:
				touched_walls[board.get_wall_for_cell(touched_cell)] = true
			elif touched_value == CELL_ISLAND:
				touched_islands[board.get_island_for_cell(touched_cell)] = true
		_touched_cells.clear()
		for wall: CellGroup in touched_walls:
			deduce_wall_expansion(wall)
			deduce_pool(wall)
		for island: CellGroup in touched_islands:
			deduce_island(island)
	
	# fast global techniques; these scan the entire grid
	if not deductions.has_changes() and solver_pass >= SolverPass.GLOBAL:
		deduce_all_islands()
		deduce_all_walls()
		deduce_all_island_dividers()
	
	# fast quirky techniques; these don't come up very frequently
	if not deductions.has_changes() and solver_pass >= SolverPass.GLOBAL:
		deduce_all_bubbles()
	
	# slow global techniques; these require building special models
	if not deductions.has_changes() and solver_pass >= SolverPass.GLOBAL:
		# iterate through all strategies, starting with a different one each time
		for _i in _slow_strategy_iterator.size():
			_slow_strategy_iterator.next().call()
			if deductions.has_changes():
				break
	
	# bifurcation; this is very slow
	if not deductions.has_changes() and solver_pass >= SolverPass.BIFURCATION:
		if not metrics.has("bifurcation_stops"):
			metrics["bifurcation_stops"] = 0
		metrics["bifurcation_stops"] += 1
		
		_cumulative_bifurcation_fun = 0.0
		# iterate through all strategies, starting with a different one each time
		for _i in _bifurcation_iterator.size():
			_bifurcation_iterator.next().call()
			if deductions.has_changes():
				break
	
	for change: Dictionary[String, Variant] in deductions.get_changes():
		var cell: Vector2i = change["pos"]
		_touched_cells[cell] = true


func deduce_all_walls() -> void:
	for wall: CellGroup in board.walls:
		deduce_wall_expansion(wall)
		deduce_pool(wall)


func deduce_all_island_chokepoints() -> void:
	var chokepoints: Array[Vector2i] = board.get_island_chokepoint_map().chokepoints_by_cell.keys()
	var old_deductions_size: int = deductions.size()
	for chokepoint: Vector2i in chokepoints:
		if not should_deduce(board, chokepoint):
			continue
		
		deduce_island_chokepoint(chokepoint)
		if deductions.size() > old_deductions_size:
			break


func deduce_all_clue_chokepoints() -> void:
	var old_deductions_size: int = deductions.size()
	for island: CellGroup in board.islands:
		if island.liberties.is_empty():
			continue
		deduce_clue_chokepoint(island)
		if deductions.size() > old_deductions_size:
			break


func deduce_all_clued_island_snugs() -> void:
	var old_deductions_size: int = deductions.size()
	for island: CellGroup in board.islands:
		deduce_clued_island_snug(island)
		if deductions.size() > old_deductions_size:
			break


func deduce_all_wall_chokepoints() -> void:
	var chokepoints: Array[Vector2i] = board.get_wall_chokepoint_map().chokepoints_by_cell.keys()
	var old_deductions_size: int = deductions.size()
	for chokepoint: Vector2i in chokepoints:
		if not should_deduce(board, chokepoint):
			continue
		deduce_wall_chokepoint(chokepoint)
		if deductions.size() > old_deductions_size:
			break


## Executes a bifurcation on two islands which are almost adjacent.
func bifurcate_all_island_battlegrounds() -> void:
	var clued_island_neighbors_by_empty_cell: Dictionary[Vector2i, Array] = {}
	for island: CellGroup in board.islands:
		if island.clue < 1:
			# unclued/invalid group
			continue
		for liberty: Vector2i in island.liberties:
			if not clued_island_neighbors_by_empty_cell.has(liberty):
				clued_island_neighbors_by_empty_cell[liberty] = []
			clued_island_neighbors_by_empty_cell[liberty].append(island.root)
	
	var old_deductions_size: int = deductions.size()
	for cell: Vector2i in clued_island_neighbors_by_empty_cell:
		if clued_island_neighbors_by_empty_cell[cell].size() != 1:
			continue
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not clued_island_neighbors_by_empty_cell.has(neighbor):
				continue
			if clued_island_neighbors_by_empty_cell[neighbor].size() != 1:
				continue
			if clued_island_neighbors_by_empty_cell[neighbor][0] == clued_island_neighbors_by_empty_cell[cell][0]:
				continue
			var clued_liberty: Vector2i = clued_island_neighbors_by_empty_cell[cell][0]
			var neighbor_liberty: Vector2i = clued_island_neighbors_by_empty_cell[neighbor][0]
			
			if _disprove_assumptions({cell: CELL_ISLAND, neighbor: CELL_WALL}):
				add_deduction(cell, CELL_WALL, ISLAND_BATTLEGROUND, [clued_liberty, neighbor_liberty])
				add_fun(FUN_BIFURCATE, _cumulative_bifurcation_fun)
				break
		if deductions.size() > old_deductions_size:
			break


## Executes a bifurcation on an island with only two liberties, testing each possible wall/island pair.
func bifurcate_all_island_releases() -> void:
	for island: CellGroup in board.islands:
		if island.liberties.size() != 2:
			continue
		if island.size() >= island.clue or island.clue == CELL_MYSTERY_CLUE:
			continue
		var old_deductions_size: int = deductions.size()
		for liberty: Vector2i in island.liberties:
			if not should_deduce(board, liberty):
				continue
			
			var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
			squeeze_fill.push_change(liberty, CELL_WALL)
			for other_liberty: Vector2i in island.liberties:
				if other_liberty == liberty:
					continue
				if not should_deduce(board, other_liberty):
					continue
				squeeze_fill.push_change(other_liberty, CELL_ISLAND)
			squeeze_fill.skip_cells(island.cells)
			squeeze_fill.fill(island.clue - island.size() - 1)
			
			if _disprove_assumptions(squeeze_fill.changes):
				add_deduction(liberty, CELL_ISLAND, ISLAND_RELEASE, [island.root])
				add_fun(FUN_BIFURCATE, _cumulative_bifurcation_fun)
				break
		if deductions.size() > old_deductions_size:
			break

## Executes a bifurcation on an island which is one cell away from being complete.
func bifurcate_all_island_strangles() -> void:
	for island: CellGroup in board.islands:
		if island.size() != island.clue - 1 or island.clue == CELL_MYSTERY_CLUE:
			continue
		
		var old_deductions_size: int = deductions.size()
		for liberty: Vector2i in island.liberties:
			if not should_deduce(board, liberty):
				continue
			
			var assumptions: Dictionary[Vector2i, int] = {}
			assumptions[liberty] = CELL_ISLAND
			for new_wall_cell_dir: Vector2i in NEIGHBOR_DIRS:
				var new_wall_cell: Vector2i = liberty + new_wall_cell_dir
				if not should_deduce(board, new_wall_cell):
					continue
				assumptions[new_wall_cell] = CELL_WALL
			for other_liberty: Vector2i in island.liberties:
				if other_liberty == liberty:
					continue
				if not should_deduce(board, other_liberty):
					continue
				assumptions[other_liberty] = CELL_WALL
			
			if _disprove_assumptions(assumptions):
				add_deduction(liberty, CELL_WALL, ISLAND_STRANGLE, [island.root])
				add_fun(FUN_BIFURCATE, _cumulative_bifurcation_fun)
				break
		if deductions.size() > old_deductions_size:
			break


## Executes a bifurcation on a wall with only two liberties, testing each possible wall/island pair.[br]
## [br]
## There are two common border wall scenarios:[br]
## [br]
## 1. A wall has two liberties stacked against the wall, one above the other. It's unlikely the liberty bordering the
## 	puzzle's edge is an island, and assuming it is an island often leads to an obvious contradiction.[br]
## 2. A wall has two liberties side-by-side against the wall, so it can extend left or right. However, one of these is
## 	not an actual liberty, and extending it along the wall invalidates a clue.[br]
## [br]
## This deduction doesn't apply only to border walls, but border walls are the most useful case.
func bifurcate_all_wall_strangles() -> void:
	if board.walls.size() < 2:
		# The wall strangle deduction requires two walls.
		return
	
	for wall: CellGroup in board.walls:
		if wall.liberties.size() != 2:
			continue
		
		var reason: Deduction.Reason
		if wall.liberties.any(_is_border_cell):
			reason = BORDER_HUG
		else:
			reason = WALL_STRANGLE
			
		var old_deductions_size: int = deductions.size()
		for liberty: Vector2i in wall.liberties:
			var other_liberty: Vector2i = wall.liberties[1] if liberty == wall.liberties.front() \
					else wall.liberties.front()
			
			var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
			squeeze_fill.push_change(liberty, CELL_ISLAND)
			squeeze_fill.push_change(other_liberty, CELL_WALL)
			squeeze_fill.skip_cells(wall.cells)
			squeeze_fill.fill()
			
			if _disprove_assumptions(squeeze_fill.changes):
				add_deduction(liberty, CELL_WALL, reason, [wall.root])
				add_fun(FUN_BIFURCATE, _cumulative_bifurcation_fun)
				break
		if deductions.size() > old_deductions_size:
			break


func _apply_assumptions(solver: Solver, assumptions: Dictionary[Vector2i, int]) -> bool:
	solver.board = board.duplicate()
	for assumption_cell in assumptions:
		if not solver.should_deduce(solver.board, assumption_cell):
			continue
		solver.add_deduction(assumption_cell, assumptions[assumption_cell], Deduction.Reason.ASSUMPTION)
		solver.add_fun(FUN_TRIVIAL, 1.0)
	var applied_changes: bool = false
	if solver.deductions.has_changes():
		solver.apply_changes()
		applied_changes = true
	return applied_changes


func _disprove_assumptions(assumptions: Dictionary[Vector2i, int]) -> bool:
	var solver: Solver = Solver.new()
	if not _apply_assumptions(solver, assumptions):
		return false
	
	if not metrics.has("bifurcation_scenarios"):
		metrics["bifurcation_scenarios"] = 0
	metrics["bifurcation_scenarios"] += 1
	var bifurcation_start_time: int = Time.get_ticks_usec()
	
	var local_cells: Array[Vector2i] = []
	for assumption_cell in assumptions:
		local_cells.append(assumption_cell)
	
	var assumptions_valid: bool = true
	var bifurcation_fun: float = 0.0
	for i in BIFURCATION_DEPTH:
		solver.step(SolverPass.GLOBAL)
		if not solver.deductions.has_changes():
			break
		for change: Dictionary[String, Variant] in solver.deductions.get_changes():
			local_cells.append(change["pos"])
		bifurcation_fun += solver.deductions.get_total_fun()
		solver.apply_changes()
		var validation_result: String = solver.board.validate_local(local_cells)
		if validation_result != "":
			assumptions_valid = false
			break
	
	if assumptions_valid:
		var validation_result: SolverBoard.ValidationResult = solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
		if validation_result.error_count > 0:
			assumptions_valid = false
	
	if assumptions_valid:
		bifurcation_fun *= BAD_BIFURCATION_FUN_FACTOR
	_cumulative_bifurcation_fun += bifurcation_fun
	
	if not metrics.has("bifurcation_duration"):
		metrics["bifurcation_duration"] = 0
	metrics["bifurcation_duration"] += (Time.get_ticks_usec() - bifurcation_start_time) / 1000.0
	
	return not assumptions_valid

func deduce_all_islands() -> void:
	for island: CellGroup in board.islands:
		deduce_island(island)


func deduce_all_island_dividers() -> void:
	var all_liberties: Dictionary[Vector2i, bool] = {}
	for island: CellGroup in board.islands:
		if island.clue == 0 or island.clue == -1:
			# unclued/invalid island
			continue
		for liberty: Vector2i in island.liberties:
			if should_deduce(board, liberty):
				all_liberties[liberty] = true
	
	for liberty: Vector2i in all_liberties:
		var neighbors: Array[Vector2i] = []
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			neighbors.append(liberty + neighbor_dir)
		var neighbor_islands: Array[CellGroup] = _get_unique_islands(neighbors)
		if neighbor_islands.size() < 2:
			continue
		if not _is_valid_merged_island(neighbor_islands, 1):
			var sorted_root_cells: Array[Vector2i] = _get_sorted_root_cells(neighbor_islands)
			var reason: int = ADJACENT_CLUES
			for neighbor_island: CellGroup in neighbor_islands:
				if neighbor_island.size() > 1 or neighbor_island.clue == 0 or neighbor_island.clue == -1:
					reason = ISLAND_DIVIDER
					break
			add_deduction(liberty, CELL_WALL, reason, sorted_root_cells)
			var fun_axis: Deduction.FunAxis = FUN_FAST
			if reason == ADJACENT_CLUES:
				fun_axis = FUN_TRIVIAL
			elif neighbor_islands.size() > 2 \
					or CellGroup.merge_clue_values(neighbor_islands[0].clue, neighbor_islands[1].clue) != -1:
				fun_axis = FUN_NOVELTY
			add_fun(fun_axis, 1.0)


func deduce_all_bubbles() -> void:
	# island bubbles
	var island_liberties: Dictionary[Vector2i, bool] = {}
	for island: CellGroup in board.islands:
		for liberty: Vector2i in island.liberties:
			if should_deduce(board, liberty):
				island_liberties[liberty] = true
	for cell: Vector2i in island_liberties:
		var bubble: bool = true
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor_value: int = board.get_cell(cell + neighbor_dir)
			if neighbor_value != CELL_INVALID and neighbor_value != CELL_ISLAND:
				bubble = false
				break
		if bubble:
			add_deduction(cell, CELL_ISLAND, ISLAND_BUBBLE)
			add_fun(FUN_FAST, 1.0)
	
	# wall bubbles
	var wall_liberties: Dictionary[Vector2i, bool] = {}
	for wall: CellGroup in board.walls:
		for liberty: Vector2i in wall.liberties:
			if should_deduce(board, liberty):
				wall_liberties[liberty] = true
	for cell: Vector2i in wall_liberties:
		var bubble: bool = true
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor_value: int = board.get_cell(cell + neighbor_dir)
			if neighbor_value != CELL_INVALID and neighbor_value != CELL_WALL:
				bubble = false
				break
		
		if bubble:
			add_deduction(cell, CELL_WALL, WALL_BUBBLE)
			add_fun(FUN_FAST, 1.0)


func deduce_all_unreachable_squares() -> void:
	for cell: Vector2i in board.empty_cells:
		if not should_deduce(board, cell):
			continue
		match board.get_global_reachability_map().get_clue_reachability(cell):
			GlobalReachabilityMap.ClueReachability.REACHABLE:
				continue
			GlobalReachabilityMap.ClueReachability.UNREACHABLE:
				add_deduction(cell, CELL_WALL, UNREACHABLE_CELL,
						[board.get_global_reachability_map().get_nearest_clued_island_cell(cell)])
				add_fun(FUN_THINK, 1.0)
			GlobalReachabilityMap.ClueReachability.IMPOSSIBLE:
				add_deduction(cell, CELL_WALL, WALL_BUBBLE)
				add_fun(FUN_FAST, 1.0)
			GlobalReachabilityMap.ClueReachability.CONFLICT:
				var clued_neighbor_roots: Array[Vector2i] = _find_clued_neighbor_roots(cell)
				add_deduction(cell, CELL_WALL, ISLAND_DIVIDER,
						[clued_neighbor_roots[0], clued_neighbor_roots[1]])
				add_fun(FUN_FAST, 1.0)


func deduce_island_chokepoint(chokepoint: Vector2i) -> void:
	if not board.get_island_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	
	var old_deductions_size: int = deductions.size()
	if deductions.size() == old_deductions_size and should_deduce(board, chokepoint):
		deduce_island_chokepoint_cramped(chokepoint)
	
	if deductions.size() == old_deductions_size and should_deduce(board, chokepoint):
		deduce_island_chokepoint_pool(chokepoint)


## Deduces when a chokepoint prevents an island from reaching its required size.
func deduce_island_chokepoint_cramped(chokepoint: Vector2i) -> void:
	if not should_deduce(board, chokepoint):
		return
	if not board.get_island_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	
	var clue_cell: Vector2i = board.get_global_reachability_map().get_nearest_clued_island_cell(chokepoint)
	if clue_cell == POS_NOT_FOUND:
		return
	var unchoked_cell_count: int = \
			board.get_island_chokepoint_map().get_unchoked_cell_count(chokepoint, clue_cell)
	var island: CellGroup = board.get_island_for_cell(clue_cell)
	if unchoked_cell_count < island.clue and island.clue != CELL_MYSTERY_CLUE:
		if chokepoint in island.liberties:
			add_deduction(chokepoint, CELL_ISLAND,
				ISLAND_EXPANSION, [clue_cell])
			add_fun(FUN_THINK, 1.0)
		else:
			add_deduction(chokepoint, CELL_ISLAND,
				ISLAND_CHOKEPOINT, [clue_cell])
			add_fun(FUN_THINK, 1.0)


## Deduces when a chokepoint forces a 2x2 pool in a complex multi-cell case.
func deduce_island_chokepoint_pool(chokepoint: Vector2i) -> void:
	if not should_deduce(board, chokepoint):
		return
	if not board.get_island_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	
	var split_neighbor_set: Dictionary[Vector2i, bool] = {}
	var split_root_set: Dictionary[Vector2i, bool] = {}
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = chokepoint + neighbor_dir
		if board.get_cell(neighbor) != CELL_EMPTY:
			continue
		var island_chokepoint_map: SolverChokepointMap = board.get_island_chokepoint_map()
		var split_root: Vector2i = island_chokepoint_map.get_subtree_root_under_chokepoint(chokepoint, neighbor)
		if split_root_set.has(split_root):
			continue
		split_root_set[split_root] = true
		split_neighbor_set[neighbor] = true
	
	for neighbor: Vector2i in split_neighbor_set:
		var unchoked_special_count: int = board.get_island_chokepoint_map() \
				.get_unchoked_special_count(chokepoint, neighbor)
		if unchoked_special_count > 0:
			continue
		var wall_cell_set: Dictionary[Vector2i, bool] = {chokepoint: true}
		var wall_cells: Array[Vector2i] = board.perform_bfs([neighbor], func(cell: Vector2i) -> bool:
			var cell_value: int = board.get_cell(cell)
			return not (cell_value == CELL_WALL or cell_value == CELL_INVALID or cell == chokepoint))
		for wall_cell in wall_cells:
			wall_cell_set[wall_cell] = true
		
		var pool_cell_set: Dictionary[Vector2i, bool] = {}
		for wall_cell: Vector2i in wall_cell_set:
			for pool_dir: Vector2i in [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]:
				var pool_triplet_cells: Array[Vector2i] = NurikabeUtils.pool_triplet(wall_cell, pool_dir)
				if pool_triplet_cells.all(func(pool_triplet_cell: Vector2i) -> bool:
						return board.get_cell(pool_triplet_cell) == CELL_WALL \
							or pool_triplet_cell in wall_cell_set):
					for pool_triplet_cell: Vector2i in pool_triplet_cells:
						pool_cell_set[pool_triplet_cell] = true
					pool_cell_set[wall_cell] = true
		
		if not pool_cell_set.is_empty():
			var pool_cells: Array[Vector2i] = pool_cell_set.keys()
			pool_cells.sort()
			add_deduction(chokepoint, CELL_ISLAND, POOL_CHOKEPOINT, pool_cells)
			add_fun(FUN_THINK, 1.0)


func deduce_clue_chokepoint(island: CellGroup) -> void:
	if island.liberties.is_empty():
		return
	
	var old_deductions_size: int = deductions.size()
	if deductions.size() == old_deductions_size:
		deduce_clue_chokepoint_loose(island)
	
	if deductions.size() == old_deductions_size:
		deduce_clue_chokepoint_wall_weaver(island)


func deduce_clue_chokepoint_loose(island: CellGroup) -> void:
	if island.liberties.is_empty():
		return
	
	var chokepoint_cells: Dictionary[Vector2i, int] = \
			board.get_per_clue_chokepoint_map().find_chokepoint_cells(island)
	for chokepoint: Vector2i in chokepoint_cells:
		if not should_deduce(board, chokepoint):
			continue
		if chokepoint_cells[chokepoint] == CELL_ISLAND:
			if chokepoint in island.liberties:
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_EXPANSION, [island.root])
				add_fun(FUN_THINK, 1.0)
			else:
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_CHOKEPOINT, [island.root])
				add_fun(FUN_THINK, 1.0)
		else:
			add_deduction(chokepoint, CELL_WALL, ISLAND_BUFFER, [island.root])
			add_fun(FUN_FAST, 1.0)


func deduce_clue_chokepoint_wall_weaver(island: CellGroup) -> void:
	if island.liberties.is_empty():
		return
	
	var wall_exclusion_map: GroupMap = board.get_per_clue_chokepoint_map().get_wall_exclusion_map(island)
	var component_cell_count: int = board.get_per_clue_chokepoint_map().get_component_cell_count(island)
	if wall_exclusion_map.groups.size() != 1 + component_cell_count - island.clue:
		return
	
	var connectors_by_wall: Dictionary[Vector2i, Array]
	for cell: Vector2i in board.get_per_clue_chokepoint_map().get_component_cells(island):
		if not board.get_cell(cell) == CELL_EMPTY:
			continue
		var wall_roots: Dictionary[Vector2i, bool] = {}
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not wall_exclusion_map.roots_by_cell.has(neighbor):
				continue
			wall_roots[wall_exclusion_map.roots_by_cell.get(neighbor)] = true
		if wall_roots.size() >= 2:
			for wall_root: Vector2i in wall_roots:
				if not connectors_by_wall.has(wall_root):
					connectors_by_wall[wall_root] = [] as Array[Vector2i]
				connectors_by_wall[wall_root].append(cell)
	
	for wall_root: Vector2i in connectors_by_wall:
		if connectors_by_wall[wall_root].size() > 1:
			continue
		var connector: Vector2i = connectors_by_wall[wall_root].front()
		if not should_deduce(board, connector):
			continue
		add_deduction(connector, CELL_WALL, WALL_WEAVER, [island.root])
		add_fun(FUN_THINK, 1.0)


func deduce_unclued_lifeline() -> void:
	var exclusive_clues_by_unclued: Dictionary[Vector2i, Vector2i] = {}
	
	var reachable_clues_by_cell: Dictionary[Vector2i, Dictionary] \
			= board.get_per_clue_chokepoint_map().get_reachable_clues_by_cell()
	for unclued_cell: Vector2i in reachable_clues_by_cell:
		if reachable_clues_by_cell[unclued_cell].size() > 1:
			continue
		if board.get_cell(unclued_cell) != CELL_ISLAND:
			continue
		var island: CellGroup = board.get_island_for_cell(unclued_cell)
		if island.clue != 0:
			continue
		exclusive_clues_by_unclued[island.root] \
				= reachable_clues_by_cell[unclued_cell].keys().front()
	
	var old_deductions_size: int = deductions.size()
	for unclued_root: Vector2i in exclusive_clues_by_unclued:
		var unclued_island: CellGroup = board.get_island_for_cell(unclued_root)
		
		var clue_root: Vector2i = exclusive_clues_by_unclued[unclued_root]
		var clued_island: CellGroup = board.get_island_for_cell(clue_root)
		if clued_island.clue == CELL_MYSTERY_CLUE:
			continue
		
		# calculate the minimum distance to the clued and unclued cells
		var unclued_distance_map: Dictionary[Vector2i, int] \
				= board.get_per_clue_chokepoint_map().get_distance_map(clued_island, unclued_island.cells)
		var clued_island_distance_map: Dictionary[Vector2i, int] \
				= board.get_per_clue_chokepoint_map().get_distance_map(clued_island, clued_island.cells)
		
		# calculate the cells capable of connecting the clued and unclued cells
		var corridor_cells: Array[Vector2i] = []
		var budget: int = clued_island.clue - unclued_island.size() - clued_island.size() + 1
		for reachable_cell: Vector2i in \
				board.get_per_clue_chokepoint_map().get_component_cells(clued_island):
			var clue_distance: int = clued_island_distance_map[reachable_cell]
			var unclued_distance: int = unclued_distance_map[reachable_cell]
			if clue_distance == 0 or unclued_distance == 0 or clue_distance + unclued_distance <= budget:
				corridor_cells.append(reachable_cell)
		
		# calculate any corridor chokepoints which would separate the clued and unclued cells
		var chokepoint_map: ChokepointMap = ChokepointMap.new(corridor_cells, func(cell: Vector2i) -> bool:
			return cell in unclued_island.cells)
		for chokepoint: Vector2i in chokepoint_map.chokepoints_by_cell.keys():
			if not should_deduce(board, chokepoint):
				continue
			var unchoked_special_count: int = \
					chokepoint_map.get_unchoked_special_count(chokepoint, clue_root)
			if unchoked_special_count < unclued_island.size():
				add_deduction(chokepoint, CELL_ISLAND, UNCLUED_LIFELINE, [clue_root])
				add_fun(FUN_THINK, 1.0)
		if deductions.size() > old_deductions_size:
			break


func deduce_clued_island_snug(island: CellGroup) -> void:
	if island.clue == 0 or island.clue == -1 or island.clue == CELL_MYSTERY_CLUE:
		return
	if island.liberties.is_empty():
		return
	var extent_size: int = board.get_per_clue_extent_map().get_extent_size(island)
	if extent_size != island.clue:
		return
	
	for extent_cell: Vector2i in board.get_per_clue_extent_map().get_extent_cells(island):
		if should_deduce(board, extent_cell):
			add_deduction(extent_cell, CELL_ISLAND, ISLAND_SNUG, [island.root])
			add_fun(FUN_THINK, 1.0)
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = extent_cell + neighbor_dir
			if not should_deduce(board, neighbor):
				continue
			if board.get_per_clue_extent_map().needs_buffer(island, neighbor):
				add_deduction(neighbor, CELL_WALL, ISLAND_BUFFER, [island.root])
				add_fun(FUN_FAST, 1.0)


func deduce_wall_chokepoint(chokepoint: Vector2i) -> void:
	if not should_deduce(board, chokepoint):
		return
	if not board.get_wall_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	
	var max_choked_special_count: int = 0
	var split_neighbor: Vector2i = POS_NOT_FOUND
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = chokepoint + neighbor_dir
		if board.get_cell(neighbor) != CELL_WALL:
			continue
		var special_count: int = board.get_wall_chokepoint_map() \
				.get_component_special_count(neighbor)
		var unchoked_special_count: int = board.get_wall_chokepoint_map() \
				.get_unchoked_special_count(chokepoint, neighbor)
		var choked_special_count: int = special_count - unchoked_special_count
		if choked_special_count > max_choked_special_count:
			split_neighbor = neighbor
			choked_special_count = max_choked_special_count
			break
	
	if split_neighbor != POS_NOT_FOUND:
		add_deduction(chokepoint, CELL_WALL, WALL_CONNECTOR, [split_neighbor])
		add_fun(FUN_THINK, 1.0)


func deduce_island(island: CellGroup) -> void:
	if island.clue == -1:
		return
	if island.liberties.is_empty():
		return
	if island.clue == CELL_MYSTERY_CLUE:
		return
	
	if island.clue == 0:
		# unclued island
		if island.liberties.size() == 1:
			_check_unclued_island_forced_expansion(island)
		elif island.liberties.size() == 2:
			_check_corner_buffer(island)
	else:
		# clued island
		if island.clue == island.size():
			_check_clued_island_moat(island)
		elif island.liberties.size() == 1 and island.clue > island.size():
			_check_clued_island_forced_expansion(island)
		else:
			if island.liberties.size() == 2 and island.clue == island.size() + 1:
				_check_clued_island_corner(island)
			if island.liberties.size() == 2:
				_check_corner_buffer(island)


func deduce_wall_expansion(wall: CellGroup) -> void:
	@warning_ignore("integer_division")
	if wall.liberties.size() == 1 and (board.walls.size() >= 2 or wall.size() < board.cells.size() / 2):
		var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
		squeeze_fill.skip_cells(wall.cells)
		squeeze_fill.push_change(wall.liberties.front(), CELL_WALL)
		squeeze_fill.fill()
		for change: Vector2i in squeeze_fill.changes:
			if should_deduce(board, change):
				add_deduction(change, CELL_WALL, WALL_EXPANSION, [wall.root])
				add_fun(FUN_FAST, 1.0)


func deduce_pool(wall: CellGroup) -> void:
	if wall.size() < 3 or wall.liberties.is_empty():
		return
	for liberty: Vector2i in wall.liberties:
		if not should_deduce(board, liberty):
			continue
		for pool_dir: Vector2i in [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]:
			var pool_triplet_cells: Array[Vector2i] =  [
				liberty + pool_dir,
				liberty + Vector2i(pool_dir.x, 0),
				liberty + Vector2i(0, pool_dir.y)]
			if pool_triplet_cells.all(func(pool_triplet_cell: Vector2i) -> bool:
					return board.get_cell(pool_triplet_cell) == CELL_WALL):
				pool_triplet_cells.sort()
				add_deduction(liberty, CELL_ISLAND, POOL_TRIPLET, pool_triplet_cells)
				add_fun(FUN_FAST, 1.0)
				break


func should_deduce(target_board: SolverBoard, cell: Vector2i) -> bool:
	return target_board.get_cell(cell) == CELL_EMPTY and cell not in deductions.cells


## If there are two liberties, and the liberties are diagonal, any blank squares connecting those liberties
## must be walls.
func _check_clued_island_corner(island: CellGroup) -> void:
	for diagonal_dir: Vector2i in NEIGHBOR_DIRS:
		var diagonal: Vector2i = island.liberties.front() + diagonal_dir
		if diagonal.distance_to(island.liberties[1]) != 1:
			continue
		if not should_deduce(board, diagonal):
			continue
		add_deduction(diagonal, CELL_WALL, CORNER_ISLAND, [island.root])
		add_fun(FUN_NOVELTY, 1.0)


func _check_corner_buffer(island: CellGroup) -> void:
	for diagonal_dir: Vector2i in NEIGHBOR_DIRS:
		var diagonal: Vector2i = island.liberties.front() + diagonal_dir
		if diagonal.distance_to(island.liberties[1]) != 1:
			continue
		if not should_deduce(board, diagonal):
			continue
		var merged_island_cells: Array[Vector2i] = []
		for merged_dir in NEIGHBOR_DIRS:
			merged_island_cells.append(diagonal + merged_dir)
		merged_island_cells.append(island.root)
		var neighbor_islands: Array[CellGroup] = _get_unique_islands(merged_island_cells)
		if not _is_valid_merged_island(neighbor_islands, 2):
			var sorted_root_cells: Array[Vector2i] = _get_sorted_root_cells(neighbor_islands)
			add_deduction(diagonal, CELL_WALL, CORNER_BUFFER, sorted_root_cells)
			add_fun(FUN_NOVELTY, 1.0)


func _check_unclued_island_forced_expansion(island: CellGroup) -> void:
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(island.cells)
	squeeze_fill.push_change(island.liberties.front(), CELL_ISLAND)
	squeeze_fill.fill()
	for change: Vector2i in squeeze_fill.changes:
		if should_deduce(board, change):
			add_deduction(change, CELL_ISLAND, ISLAND_CONNECTOR, [island.root])
			add_fun(FUN_NOVELTY, 1.0)


func _check_clued_island_moat(island: CellGroup) -> void:
	for liberty: Vector2i in island.liberties:
		if not should_deduce(board, liberty):
			return
		var reason: int = ISLAND_OF_ONE if island.clue == 1 else ISLAND_MOAT
		add_deduction(liberty, CELL_WALL, reason, [island.root])
		add_fun(FUN_TRIVIAL, 1.0)


func _check_clued_island_forced_expansion(island: CellGroup) -> void:
	if island.liberties.size() != 1 or island.clue <= island.size() or island.clue == CELL_MYSTERY_CLUE:
		return
	
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(island.cells)
	squeeze_fill.push_change(island.liberties.front(), CELL_ISLAND)
	squeeze_fill.fill(island.clue - island.size() - 1)
	for new_island_cell: Vector2i in squeeze_fill.changes:
		if should_deduce(board, new_island_cell):
			add_deduction(new_island_cell, CELL_ISLAND, ISLAND_EXPANSION, [island.root])
			add_fun(FUN_FAST, 1.0)
	
	if squeeze_fill.changes.size() == island.clue - island.size():
		for new_island_cell: Vector2i in squeeze_fill.changes:
			for new_island_neighbor_dir: Vector2i in NEIGHBOR_DIRS:
				var new_island_neighbor: Vector2i = new_island_cell + new_island_neighbor_dir
				if new_island_neighbor in squeeze_fill.changes:
					continue
				if should_deduce(board, new_island_neighbor):
					add_deduction(new_island_neighbor, CELL_WALL, ISLAND_MOAT, [island.root])
					add_fun(FUN_TRIVIAL, 1.0)


func _find_clued_neighbor_roots(cell: Vector2i) -> Array[Vector2i]:
	var clued_neighbor_roots: Dictionary[Vector2i, bool] = {}
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		var neighbor_value: int = board.get_cell(neighbor)
		if neighbor_value != CELL_ISLAND:
			continue
		var island: CellGroup = board.get_island_for_cell(neighbor)
		if island.clue == 0:
			continue
		clued_neighbor_roots[island.root] = true
	return clued_neighbor_roots.keys()


func _get_unique_islands(cells: Array[Vector2i]) -> Array[CellGroup]:
	var islands: Dictionary[CellGroup, bool] = {}
	for cell: Vector2i in cells:
		if board.get_cell(cell) != CELL_ISLAND:
			continue
		var island: CellGroup = board.get_island_for_cell(cell)
		islands[island] = true
	return islands.keys()


func _get_sorted_root_cells(islands: Array[CellGroup]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for island: CellGroup in islands:
		cells.append(island.root)
	cells.sort()
	return cells


func _is_border_cell(cell: Vector2i) -> bool:
	var result: bool = false
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if board.get_cell(neighbor) == CELL_INVALID:
			result = true
			break
	return result


func _is_valid_merged_island(islands: Array[CellGroup], merge_cells: int) -> bool:
	var total_joined_size: int = merge_cells
	var total_clues: int = 0
	var clue_value: int = 0
	
	var result: bool = true
	
	for island: CellGroup in islands:
		total_joined_size += island.size()
		if island.clue >= 1 or island.clue == CELL_MYSTERY_CLUE:
			if clue_value > 0:
				result = false
				break
			clue_value = island.clue
			total_clues += 1
			if total_clues >= 2:
				result = false
				break
		if clue_value > 0 and total_joined_size > clue_value:
			result = false
			break
	
	return result
