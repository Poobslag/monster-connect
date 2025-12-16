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

const UNKNOWN_REASON: Placement.Reason = Placement.Reason.UNKNOWN

## starting techniques
const INITIAL_OPEN_ISLAND: Placement.Reason = Placement.Reason.INITIAL_OPEN_ISLAND

## basic techniques
const ISLAND_GUIDE: Placement.Reason = Placement.Reason.ISLAND_GUIDE
const ISLAND_EXPANSION: Placement.Reason = Placement.Reason.ISLAND_EXPANSION
const SEALED_ISLAND_CLUE: Placement.Reason = Placement.Reason.SEALED_ISLAND_CLUE
const ISLAND_MOAT: Placement.Reason = Placement.Reason.ISLAND_MOAT

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var board: GeneratorBoard:
	set(value):
		board = value
		solver.board = board.solver_board
var placements: PlacementBatch = PlacementBatch.new()
var solver: Solver = Solver.new()

var _ran_starting_techniques: bool = false

func _init() -> void:
	solver.set_generation_strategy()


func clear() -> void:
	board.clear()
	placements.clear()
	solver.clear()
	_ran_starting_techniques = false


func step_until_done() -> void:
	while true:
		step()
		if not placements.has_changes():
			break
		apply_changes()
		solver.step_until_done()
		solver.apply_changes()

var _basic_techniques: Array[Dictionary] = [
	{"callable": generate_open_island_expansion, "weight": 1.0},
	{"callable": generate_open_island_moat, "weight": 0.5},
	{"callable": generate_all_sealed_mystery_island_clues, "weight": 1.0},
]

func step() -> void:
	if not placements.has_changes() and not _ran_starting_techniques:
		generate_initial_open_island()
		_ran_starting_techniques = true
	
	if not placements.has_changes():
		var basic_technique_weights: Array[float] = []
		basic_technique_weights.resize(_basic_techniques.size())
		for i in _basic_techniques.size():
			basic_technique_weights[i] = _basic_techniques[i]["weight"]
		var shuffled_basic_techniques: Array[Dictionary] = _basic_techniques.duplicate()
		Utils.shuffle_weighted(shuffled_basic_techniques, basic_technique_weights)
		
		for basic_technique: Dictionary in shuffled_basic_techniques:
			basic_technique["callable"].call()
			if placements.has_changes():
				break


func generate_open_island_expansion() -> void:
	var open_islands: Array[CellGroup] = board.islands.filter(func(island: CellGroup) -> bool:
			return island.liberties.size() == 1)
	
	if open_islands:
		var open_island: CellGroup = open_islands.pick_random()
		placements.add_placement(open_island.liberties[0], CELL_ISLAND, ISLAND_EXPANSION)


func generate_open_island_moat() -> void:
	var mystery_islands: Array[CellGroup] = board.islands.filter(func(island: CellGroup) -> bool:
			return island.clue == CELL_MYSTERY_CLUE)
	if not mystery_islands:
		return
	
	# larger islands are chosen more frequently
	var weights_array: Array[float] = []
	for i in mystery_islands.size():
		weights_array.append(mystery_islands.size() - 1)
	Utils.shuffle_weighted(mystery_islands, weights_array)
	var mystery_island: CellGroup = mystery_islands[0]
	
	var clue_cell: Vector2i = _find_clue_cell(mystery_island)
	var new_wall_cells: Array[Vector2i] = mystery_island.liberties.duplicate()
	var temp_board: SolverBoard = board.solver_board.duplicate()
	temp_board.set_clue(clue_cell, mystery_island.size())
	for liberty: Vector2i in new_wall_cells:
		temp_board.set_cell(liberty, CELL_WALL)
	var local_cells: Array[Vector2i] = new_wall_cells.duplicate()
	local_cells.append(clue_cell)
	var validation_result: String = temp_board.validate_local(local_cells)
	if "p" in validation_result:
		pass
	else:
		placements.add_placement(clue_cell, mystery_island.size(), ISLAND_MOAT)
		for liberty: Vector2i in new_wall_cells:
			placements.add_placement(liberty, CELL_WALL, ISLAND_MOAT)


func generate_all_sealed_mystery_island_clues() -> void:
	for island: CellGroup in board.islands:
		if not island.liberties.is_empty() or island.clue != CELL_MYSTERY_CLUE:
			continue
		
		var clue_cell: Vector2i = _find_clue_cell(island)
		placements.add_placement(clue_cell, island.size(), SEALED_ISLAND_CLUE)


## Adds a new clue cell constrained to expand through a single open liberty. Most Nurikabe puzzles begin with at least
## one such forced expansion.
func generate_initial_open_island() -> void:
	for _mercy in 10:
		# island_plan keys:
		# - seed_cell: Vector2i
		# - open_liberty: Vector2i
		# - supporting_clues: Dictionary[Vector2i, bool]
		var island_plan: Dictionary[String, Variant] = {}
		_select_initial_open_island_candidate(island_plan)
		_plan_initial_open_island_walls(island_plan)
		
		if island_plan.has("seed_cell") and island_plan.has("supporting_clues"):
			placements.add_placement(island_plan["seed_cell"], CELL_MYSTERY_CLUE, INITIAL_OPEN_ISLAND)
			for other_clue: Vector2i in island_plan["supporting_clues"]:
				placements.add_placement(other_clue, CELL_MYSTERY_CLUE, ISLAND_GUIDE)
			break


func apply_changes() -> void:
	var changes: Array[Dictionary] = placements.get_changes()
	for change: Dictionary in changes:
		if NurikabeUtils.is_clue(change["value"]):
			board.set_clue(change["pos"], change["value"])
		else:
			board.set_cell(change["pos"], change["value"])
	placements.clear()


func _find_clue_cell(island: CellGroup) -> Vector2i:
	var clue_cells: Array[Vector2i] = island.cells.filter(func(cell: Vector2i) -> bool:
			return board.has_clue(cell))
	return clue_cells[0] if clue_cells.size() == 1 else POS_NOT_FOUND


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
	for cell: Vector2i in board.cells:
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
	var seed_cell: Vector2i = potential_cells.pick_random()
	
	var potential_preserved_liberties: Array[Vector2i] = []
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = seed_cell + neighbor_dir
		var neighbor_value: int = board.get_cell(neighbor)
		if neighbor_value == CELL_EMPTY:
			potential_preserved_liberties.append(neighbor)
	
	if potential_preserved_liberties.is_empty():
		return
	var open_liberty: Vector2i = potential_preserved_liberties.pick_random()
	
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
		var other_wall: Vector2i = remaining_wall_cells.keys().pick_random()
		var other_clue: Vector2i = NurikabeUtils.POS_NOT_FOUND
		for potential_other_clue_dir: Vector2i in NEIGHBOR_DIRS.duplicate():
			var potential_other_clue: Vector2i = other_wall + potential_other_clue_dir
			if potential_other_clue == seed_cell:
				continue
			if potential_other_clue.distance_to(open_liberty) <= 1:
				continue
			if board.get_cell(potential_other_clue) != CELL_EMPTY:
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
	var bfs_walls: Array[Vector2i] = board.solver_board.perform_bfs([initial_wall_cells.keys().front()],
		func(c: Vector2i) -> bool:
			var cell_value: int = board.solver_board.get_cell(c)
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
