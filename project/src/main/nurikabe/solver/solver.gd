class_name Solver

signal about_to_run_probe(probe: Probe)

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

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

var verbose: bool = false
var log_enabled: bool = false
var perform_redundant_deductions: bool = false

var deductions: DeductionBatch = DeductionBatch.new()
var board: SolverBoard:
	set(value):
		board = value
		decision_manager.board = value
		probe_library.board = value

var metrics: Dictionary[String, Variant] = {}

var bifurcation_engine: BifurcationEngine = BifurcationEngine.new()
var decision_manager: DecisionManager = DecisionManager.new()
var probe_library: ProbeLibrary = ProbeLibrary.new()

var _change_history: Array[Dictionary] = []
var _log: DeductionLogger = DeductionLogger.new(self)

func _init(default_probes: bool = true) -> void:
	decision_manager.probe_library = probe_library
	about_to_run_probe.connect(probe_library._on_solver_about_to_run_probe)
	
	if default_probes:
		_create_default_probes()


func add_bifurcation_scenario(key: String, cells: Array[Vector2i],
		assumptions: Dictionary[Vector2i, int],
		bifurcation_deductions: Array[Deduction]) -> void:
	if not bifurcation_deductions.any(func(d: Deduction) -> bool:
			return should_deduce(board, d.pos)):
		# the target cells have already been deduced
		return
	if not metrics.has("bifurcation_scenarios"):
		metrics["bifurcation_scenarios"] = 0
	metrics["bifurcation_scenarios"] += 1
	bifurcation_engine.add_scenario(board, key, cells, assumptions, bifurcation_deductions)
	var builder: ProbeLibrary.ProbeBuilder = probe_library.add_probe(run_bifurcation_step) \
			.set_bifurcation().set_one_shot().related_cells(cells)
	for deduction: Deduction in bifurcation_deductions:
		builder.probe.add_deduction_cell(deduction.pos)


func add_deduction(pos: Vector2i, value: int,
		reason: Deduction.Reason = UNKNOWN_REASON,
		reason_cells: Array[Vector2i] = []) -> void:
	deductions.add_deduction(pos, value, reason, reason_cells)


func apply_changes() -> void:
	if not deductions.has_changes():
		return
	
	var changes: Array[Dictionary] = deductions.get_changes()
	for change: Dictionary[String, Variant] in changes:
		var history_item: Dictionary[String, Variant] = {}
		history_item["pos"] = change["pos"]
		history_item["value"] = change["value"]
		history_item["tick"] = board.version
		_change_history.append(history_item)
	
	_change_history.append_array(changes)
	board.set_cells(changes)
	deductions.clear()
	bifurcation_engine.clear()
	
	_create_change_probes(changes)


func apply_heat() -> void:
	board.decrease_heat()
	board.increase_heat(deductions.cells.keys())


func clear(default_probes: bool = true) -> void:
	decision_manager.clear()
	deductions.clear()
	metrics.clear()
	probe_library.clear()
	bifurcation_engine.clear()
	_change_history.clear()
	
	if default_probes:
		_create_default_probes()


func get_changes() -> Array[Dictionary]:
	return deductions.get_changes()


func has_available_probes() -> bool:
	return probe_library.has_available_probes()


func run_all_probes() -> void:
	while probe_library.has_available_probes():
		run_next_probe()


func run_next_probe(allow_bifurcation: bool = true) -> void:
	AggregateTimer.start("choose_probe")
	var next_probe: Probe = decision_manager.choose_probe({
		"allow_bifurcation": allow_bifurcation,
	} as Dictionary[String, Variant])
	AggregateTimer.end("choose_probe")
	if next_probe == null:
		return
	
	if verbose:
		print("(%s;%s) run %s" % [board.version, Time.get_ticks_msec(), next_probe.key])
	about_to_run_probe.emit(next_probe)
	AggregateTimer.start("run_probe %s" % [next_probe.name])
	next_probe.run()
	AggregateTimer.end("run_probe %s" % [next_probe.name])


func create_all_island_probes() -> void:
	_log.start("create_all_island_probes")
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		deduce_island(island.front())
		create_island_probes(island)
	_log.end("create_all_island_probes")


func create_all_wall_probes() -> void:
	_log.start("create_all_wall_probes")
	for wall: Array[Vector2i] in board.get_walls():
		deduce_wall(wall.front())
		create_wall_probes(wall)
	_log.end("create_all_wall_probes")


func create_wall_probes(wall: Array[Vector2i]) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	if liberties.is_empty():
		return
	if wall.size() >= 3 and liberties.size() >= 1:
		probe_library.add_probe(deduce_pool.bind(wall.front())).set_one_shot() \
				.related_cells(liberties)


func create_bifurcation_probes() -> void:
	_log.start("create_bifurcation_probes")
	create_wall_strangle_probes()
	create_island_battleground_probes()
	create_island_release_probes()
	create_island_strangle_probes()
	_log.end("create_bifurcation_probes")


func create_island_chokepoint_probes() -> void:
	_log.start("create_island_chokepoint_probes")
	var chokepoints: Array[Vector2i] = board.get_island_chokepoint_map().chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		if not should_deduce(board, chokepoint):
			continue
		probe_library.add_probe(deduce_island_chokepoint.bind(chokepoint)).set_one_shot() \
				.deduction_cell(chokepoint)
	
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var liberties: Array[Vector2i] = board.get_liberties(island)
		if liberties.is_empty():
			continue
		probe_library.add_probe(deduce_clue_chokepoint.bind(island.front())).set_one_shot() \
				.related_cells(liberties)
	_log.end("create_island_chokepoint_probes")


func create_wall_chokepoint_probes() -> void:
	_log.start("create_wall_chokepoint_probes")
	var chokepoints: Array[Vector2i] = board.get_wall_chokepoint_map().chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		if not should_deduce(board, chokepoint):
			continue
		probe_library.add_probe(deduce_wall_chokepoint.bind(chokepoint)).set_one_shot() \
				.deduction_cell(chokepoint)
	_log.end("create_wall_chokepoint_probes")


func create_island_probes(island: Array[Vector2i]) -> void:
	var clue_value: int = board.get_clue_for_island(island)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if clue_value == -1:
		return
	if liberties.is_empty():
		return
	
	if clue_value >= 1:
		# clued island
		probe_library.add_probe(deduce_clued_island_snug.bind(island.front())).set_one_shot() \
				.related_cells(liberties)


## Executes a bifurcation on two islands which are almost adjacent.
func create_island_battleground_probes() -> void:
	_log.start("create_island_battleground_probes")
	var clued_island_neighbors_by_empty_cell: Dictionary[Vector2i, Array] = {}
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		if board.get_clue_for_island(island) < 1:
			# unclued/invalid group
			continue
		for liberty: Vector2i in board.get_liberties(island):
			if not clued_island_neighbors_by_empty_cell.has(liberty):
				clued_island_neighbors_by_empty_cell[liberty] = []
			clued_island_neighbors_by_empty_cell[liberty].append(island.front())
	
	for cell: Vector2i in clued_island_neighbors_by_empty_cell:
		if clued_island_neighbors_by_empty_cell[cell].size() != 1:
			continue
		for neighbor_dir in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not clued_island_neighbors_by_empty_cell.has(neighbor):
				continue
			if clued_island_neighbors_by_empty_cell[neighbor].size() != 1:
				continue
			if clued_island_neighbors_by_empty_cell[neighbor][0] == clued_island_neighbors_by_empty_cell[cell][0]:
				continue
			var clued_liberty: Vector2i = clued_island_neighbors_by_empty_cell[cell][0]
			var neighbor_liberty: Vector2i = clued_island_neighbors_by_empty_cell[neighbor][0]
			create_bifurcation_probe(
				"bifurcate_island_battleground", [clued_liberty, neighbor_liberty],
				{cell: CELL_ISLAND, neighbor: CELL_WALL},
				[Deduction.new(cell, CELL_WALL,
						ISLAND_BATTLEGROUND, [clued_liberty, neighbor_liberty])])
	_log.end("create_island_battleground_probes")


func create_bifurcation_probe(key: String, cells: Array[Vector2i],
		assumptions: Dictionary[Vector2i, int],
		bifurcation_deductions: Array[Deduction]) -> void:
	var builder: ProbeLibrary.ProbeBuilder = probe_library.add_probe(add_bifurcation_scenario.bind(
			key, cells, assumptions, bifurcation_deductions)) \
		.set_bifurcation().set_one_shot().related_cells(cells)
	for deduction: Deduction in bifurcation_deductions:
		builder.probe.add_deduction_cell(deduction.pos)


## Executes a bifurcation on an island with only two liberties, testing each possible wall/island pair.
func create_island_release_probes() -> void:
	_log.start("create_island_release_probes")
	for island: Array[Vector2i] in board.get_islands():
		if board.get_liberties(island).size() != 2:
			continue
		var clue_value: int = board.get_clue_for_island(island)
		if island.size() >= clue_value:
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		for liberty: Vector2i in liberties:
			if not should_deduce(board, liberty):
				continue
			
			var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
			squeeze_fill.push_change(liberty, CELL_WALL)
			for other_liberty: Vector2i in liberties:
				if other_liberty == liberty:
					continue
				if not should_deduce(board, other_liberty):
					continue
				squeeze_fill.push_change(other_liberty, CELL_ISLAND)
			squeeze_fill.skip_cells(island)
			squeeze_fill.fill(clue_value - island.size() - 1)
			create_bifurcation_probe(
				"bifurcate_island_release", [island.front(), liberty],
				squeeze_fill.changes,
				[Deduction.new(liberty, CELL_ISLAND, ISLAND_RELEASE, [island.front()])]
			)
	
	if bifurcation_engine.get_scenario_count() >= 1:
		probe_library.add_probe(run_bifurcation_step).set_bifurcation().set_one_shot()
	_log.end("create_island_release_probes")


## Executes a bifurcation on an island which is one cell away from being complete.
func create_island_strangle_probes() -> void:
	_log.start("create_island_strangle_probes")
	for island: Array[Vector2i] in board.get_islands():
		var clue_value: int = board.get_clue_for_island(island)
		if island.size() != clue_value - 1:
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		for liberty: Vector2i in liberties:
			if not should_deduce(board, liberty):
				continue
			
			var assumptions: Dictionary[Vector2i, int] = {}
			assumptions[liberty] = CELL_ISLAND
			for new_wall_cell_dir: Vector2i in NEIGHBOR_DIRS:
				var new_wall_cell: Vector2i = liberty + new_wall_cell_dir
				if not should_deduce(board, new_wall_cell):
					continue
				assumptions[new_wall_cell] = CELL_WALL
			for other_liberty: Vector2i in liberties:
				if other_liberty == liberty:
					continue
				if not should_deduce(board, other_liberty):
					continue
				assumptions[other_liberty] = CELL_WALL
			create_bifurcation_probe(
				"bifurcate_island_strangle", [island.front(), liberty],
				assumptions,
				[Deduction.new(liberty, CELL_WALL, ISLAND_STRANGLE, [island.front()])]
			)
	
	if bifurcation_engine.get_scenario_count() >= 1:
		probe_library.add_probe(run_bifurcation_step).set_bifurcation().set_one_shot()
	_log.end("create_island_strangle_probes")


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
func create_wall_strangle_probes() -> void:
	var walls: Array[Array] = board.get_walls()
	if walls.size() < 2:
		# The wall strangle deduction requires two walls.
		return
	
	_log.start("create_wall_strangle_probes")
	for wall: Array[Vector2i] in walls:
		var liberties: Array[Vector2i] = board.get_liberties(wall)
		if liberties.size() != 2:
			continue
		
		var scenario_key: String
		var reason: Deduction.Reason
		if liberties.any(_is_border_cell) or wall.any(_is_border_cell):
			scenario_key = "bifurcate_border_hug"
			reason = BORDER_HUG
		else:
			scenario_key = "bifurcate_wall_strangle"
			reason = WALL_STRANGLE
			
		for liberty: Vector2i in liberties:
			var other_liberty: Vector2i = liberties[1] if liberty == liberties[0] else liberties[0]
			
			var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
			squeeze_fill.push_change(liberty, CELL_ISLAND)
			squeeze_fill.push_change(other_liberty, CELL_WALL)
			squeeze_fill.skip_cells(wall)
			squeeze_fill.fill()
			create_bifurcation_probe(
				scenario_key, [wall.front(), liberty],
				squeeze_fill.changes,
				[Deduction.new(liberty, CELL_WALL, reason, [wall.front()])]
			)
	if bifurcation_engine.get_scenario_count() >= 1:
		probe_library.add_probe(run_bifurcation_step).set_bifurcation().set_one_shot()
	_log.end("create_wall_strangle_probes")


func deduce_all_island_dividers() -> void:
	_log.start("deduce_all_island_dividers")
	var all_liberties: Dictionary[Vector2i, bool] = {}
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var clue_value: int = board.get_clue_for_island(island)
		if clue_value < 1:
			# unclued/invalid island
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		for liberty: Vector2i in liberties:
			if should_deduce(board, liberty):
				all_liberties[liberty] = true
	
	for liberty: Vector2i in all_liberties:
		var neighbors: Array[Vector2i] = []
		for neighbor_dir in NEIGHBOR_DIRS:
			neighbors.append(liberty + neighbor_dir)
		if not _is_valid_merged_island(neighbors, 1):
			var unique_neighbor_island_cells: Array[Vector2i] \
					= get_unique_neighbor_island_cells(neighbors)
			add_deduction(liberty, CELL_WALL, ISLAND_DIVIDER, unique_neighbor_island_cells)
	_log.end("deduce_all_island_dividers")


func deduce_all_adjacent_clues() -> void:
	_log.start("deduce_all_adjacent_clues")
	var clue_cells: Array[Vector2i] = board.cells.keys().filter(func(c: Vector2i) -> bool:
		return NurikabeUtils.is_clue(board.get_cell(c)))
	var adjacent_clues_by_cell: Dictionary[Vector2i, Array] = {}
	for clue_cell: Vector2i in clue_cells:
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = clue_cell + neighbor_dir
			if not adjacent_clues_by_cell.has(neighbor):
				adjacent_clues_by_cell[neighbor] = [] as Array[Vector2i]
			adjacent_clues_by_cell[neighbor].append(clue_cell)
	for neighbor: Vector2i in adjacent_clues_by_cell:
		if not should_deduce(board, neighbor):
			continue
		var adjacent_clues: Array[Vector2i] = adjacent_clues_by_cell[neighbor]
		if adjacent_clues.size() >= 2:
			adjacent_clues.sort()
			add_deduction(neighbor, CELL_WALL,
				ADJACENT_CLUES, [adjacent_clues[0], adjacent_clues[1]] as Array[Vector2i])
	_log.end("deduce_all_adjacent_clues")


func deduce_all_bubbles() -> void:
	_log.start("deduce_all_bubbles")
	for cell: Vector2i in board.cells:
		if not should_deduce(board, cell):
			continue
		var has_empty_neighbor: bool = false
		var has_island_neighbor: bool = false
		var has_wall_neighbor: bool = false
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor_value: int = board.get_cell(cell + neighbor_dir)
			if neighbor_value == CELL_INVALID:
				pass
			elif neighbor_value == CELL_EMPTY:
				has_empty_neighbor = true
			elif neighbor_value == CELL_WALL:
				has_wall_neighbor = true
			elif neighbor_value == CELL_ISLAND or NurikabeUtils.is_clue(neighbor_value):
				has_island_neighbor = true
		
		if has_empty_neighbor:
			continue
		
		if has_wall_neighbor and not has_island_neighbor:
			add_deduction(cell, CELL_WALL, WALL_BUBBLE)
		elif has_island_neighbor and not has_wall_neighbor:
			add_deduction(cell, CELL_ISLAND, ISLAND_BUBBLE)
	_log.end("deduce_all_bubbles")


func deduce_all_islands_of_one() -> void:
	_log.start("deduce_all_islands_of_one")
	for cell: Vector2i in board.cells:
		if board.get_cell(cell) != 1:
			continue
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not should_deduce(board, neighbor):
				continue
			add_deduction(neighbor, CELL_WALL, ISLAND_OF_ONE, [cell])
	_log.end("deduce_all_islands_of_one")


func deduce_all_unreachable_squares() -> void:
	_log.start("deduce_all_unreachable_squares")
	for cell: Vector2i in board.cells:
		if not should_deduce(board, cell):
			continue
		match board.get_global_reachability_map().get_clue_reachability(cell):
			GlobalReachabilityMap.ClueReachability.REACHABLE:
				continue
			GlobalReachabilityMap.ClueReachability.UNREACHABLE:
				add_deduction(cell, CELL_WALL, UNREACHABLE_CELL,
						[board.get_global_reachability_map().get_nearest_clue_cell(cell)])
			GlobalReachabilityMap.ClueReachability.IMPOSSIBLE:
				add_deduction(cell, CELL_WALL, WALL_BUBBLE)
			GlobalReachabilityMap.ClueReachability.CONFLICT:
				var clued_neighbor_roots: Array[Vector2i] = _find_clued_neighbor_roots(cell)
				add_deduction(cell, CELL_WALL, ISLAND_DIVIDER,
						[clued_neighbor_roots[0], clued_neighbor_roots[1]])
	_log.end("deduce_all_unreachable_squares")


func deduce_island_chokepoint(chokepoint: Vector2i) -> void:
	if not board.get_island_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	
	_log.start("deduce_island_chokepoint")
	var old_deductions_size: int = deductions.size()
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and should_deduce(board, chokepoint):
		deduce_island_chokepoint_cramped(chokepoint)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and should_deduce(board, chokepoint):
		deduce_island_chokepoint_tiny_pool(chokepoint)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and should_deduce(board, chokepoint):
		deduce_island_chokepoint_pool(chokepoint)
	_log.end("deduce_island_chokepoint")


## Deduces when a chokepoint prevents an island from reaching its required size.
func deduce_island_chokepoint_cramped(chokepoint: Vector2i) -> void:
	if not board.get_island_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	_log.start("deduce_island_chokepoint_cramped", [chokepoint])
	
	var clue_cell: Vector2i = board.get_global_reachability_map().get_nearest_clue_cell(chokepoint)
	if clue_cell == POS_NOT_FOUND:
		_log.end("deduce_island_chokepoint_cramped", [chokepoint])
		return
	var chokepoint_value: int = board.get_cell(chokepoint)
	var clue_value: int = chokepoint_value if NurikabeUtils.is_clue(chokepoint_value) else 0
	var unchoked_cell_count: int = \
			board.get_island_chokepoint_map().get_unchoked_cell_count(chokepoint, clue_cell)
	if unchoked_cell_count < clue_value:
		var liberties: Array[Vector2i] = board.get_liberties(board.get_island_for_cell(clue_cell))
		if chokepoint in liberties:
			add_deduction(chokepoint, CELL_ISLAND,
				ISLAND_EXPANSION, [clue_cell])
		else:
			add_deduction(chokepoint, CELL_ISLAND,
				ISLAND_CHOKEPOINT, [clue_cell])
	
	_log.end("deduce_island_chokepoint_cramped", [chokepoint])


## Deduces when a chokepoint forces a 2x2 pool in a simple 2-cell case.
func deduce_island_chokepoint_tiny_pool(chokepoint: Vector2i) -> void:
	if not board.get_island_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	_log.start("deduce_island_chokepoint_tiny_pool", [chokepoint])
	
	# Check for two empty cells leading into a dead end, which create a pool.
	var old_deductions_size: int = deductions.size()
	for dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
		_check_island_chokepoint_tiny_pool(chokepoint, dir)
		if deductions.size() > old_deductions_size:
			break
	
	_log.end("deduce_island_chokepoint_tiny_pool", [chokepoint])


## Deduces when a chokepoint forces a 2x2 pool in a complex multi-cell case.
func deduce_island_chokepoint_pool(chokepoint: Vector2i) -> void:
	if not board.get_island_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	_log.start("deduce_island_chokepoint_pool", [chokepoint])
	
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
		board.perform_bfs([neighbor], func(cell: Vector2i) -> bool:
			var cell_value: int = board.get_cell(cell)
			if cell_value == CELL_WALL or cell_value == CELL_INVALID or cell == chokepoint:
				return false
			wall_cell_set[cell] = true
			return true)
		
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
	
	_log.end("deduce_island_chokepoint_pool", [chokepoint])


func deduce_clue_chokepoint(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	if board.get_liberties(island).is_empty():
		return
	
	_log.start("deduce_clue_chokepoint", [island_cell])
	var old_deductions_size: int = deductions.size()
	
	if deductions.size() == old_deductions_size or perform_redundant_deductions:
		deduce_clue_chokepoint_loose(island_cell)
	
	if deductions.size() == old_deductions_size or perform_redundant_deductions:
		deduce_clue_chokepoint_wall_weaver(island_cell)
	_log.end("deduce_clue_chokepoint", [island_cell])


func deduce_clue_chokepoint_loose(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	if board.get_liberties(island).is_empty():
		return
	
	_log.start("deduce_clue_chokepoint_loose", [island_cell])
	var chokepoint_cells: Dictionary[Vector2i, int] = \
			board.get_per_clue_chokepoint_map().find_chokepoint_cells(island_cell)
	for chokepoint: Vector2i in chokepoint_cells:
		if not should_deduce(board, chokepoint):
			continue
		if chokepoint_cells[chokepoint] == CELL_ISLAND:
			if chokepoint in board.get_liberties(island):
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_EXPANSION, [island_cell])
			else:
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_CHOKEPOINT, [island_cell])
		else:
			add_deduction(chokepoint, CELL_WALL, ISLAND_BUFFER, [island_cell])
	
	_log.end("deduce_clue_chokepoint_loose", [island_cell])


func deduce_clue_chokepoint_wall_weaver(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	if board.get_liberties(island).is_empty():
		return
	_log.start("deduce_clue_chokepoint_wall_weaver", [island_cell])
	
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	var wall_exclusion_map: GroupMap = board.get_per_clue_chokepoint_map().get_wall_exclusion_map(island_cell)
	var component_cell_count: int = board.get_per_clue_chokepoint_map().get_component_cell_count(island_cell)
	if wall_exclusion_map.groups.size() != 1 + component_cell_count - clue_value:
		return
	
	var connectors_by_wall: Dictionary[Vector2i, Array]
	for cell: Vector2i in board.get_per_clue_chokepoint_map().get_component_cells(island_cell):
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
		deductions.add_deduction(connector, CELL_WALL, WALL_WEAVER, [island_cell])
	
	_log.end("deduce_clue_chokepoint_wall_weaver", [island_cell])


func deduce_unclued_lifeline() -> void:
	_log.start("deduce_unclued_lifeline")
	
	var exclusive_clues_by_unclued: Dictionary[Vector2i, Vector2i] = {}
	
	var reachable_clues_by_cell: Dictionary[Vector2i, Dictionary] \
			= board.get_per_clue_chokepoint_map().get_reachable_clues_by_cell()
	for unclued_cell: Vector2i in reachable_clues_by_cell:
		if reachable_clues_by_cell[unclued_cell].size() > 1:
			continue
		if board.get_cell(unclued_cell) != CELL_ISLAND:
			continue
		if board.get_clue_for_island_cell(unclued_cell) != 0:
			continue
		exclusive_clues_by_unclued[board.get_island_for_cell(unclued_cell).front()] \
				= reachable_clues_by_cell[unclued_cell].keys().front()
	
	for unclued_root: Vector2i in exclusive_clues_by_unclued:
		var unclued: Array[Vector2i] = board.get_island_for_cell(unclued_root)
		
		var clue_root: Vector2i = exclusive_clues_by_unclued[unclued_root]
		var clue: Array[Vector2i] = board.get_island_for_cell(clue_root)
		var clue_value: int = board.get_clue_for_island_cell(clue_root)
		
		# calculate the minimum distance to the clued and unclued cells
		var unclued_distance_map: Dictionary[Vector2i, int] \
				= board.get_per_clue_chokepoint_map().get_distance_map(clue_root, unclued)
		var clued_island_distance_map: Dictionary[Vector2i, int] \
				= board.get_per_clue_chokepoint_map().get_distance_map(clue_root, clue)
		
		# calculate the cells capable of connecting the clued and unclued cells
		var corridor_cells: Array[Vector2i] = []
		var budget: int = clue_value - unclued.size() - clue.size() + 1
		for reachable_cell: Vector2i in \
				board.get_per_clue_chokepoint_map().get_component_cells(clue_root):
			var clue_distance: int = clued_island_distance_map[reachable_cell]
			var unclued_distance: int = unclued_distance_map[reachable_cell]
			if clue_distance == 0 or unclued_distance == 0 or clue_distance + unclued_distance <= budget:
				corridor_cells.append(reachable_cell)
		
		# calculate any corridor chokepoints which would separate the clued and unclued cells
		var chokepoint_map: ChokepointMap = ChokepointMap.new(corridor_cells, func(cell: Vector2i) -> bool:
			return cell in unclued)
		for chokepoint: Vector2i in chokepoint_map.chokepoints_by_cell.keys():
			if not should_deduce(board, chokepoint):
				continue
			var unchoked_special_count: int = \
					chokepoint_map.get_unchoked_special_count(chokepoint, clue_root)
			if unchoked_special_count < unclued.size():
				add_deduction(chokepoint, CELL_ISLAND, UNCLUED_LIFELINE, [clue_root])
	
	_log.end("deduce_unclued_lifeline")


func deduce_clued_island_snug(island_cell: Vector2i) -> void:
	_log.start("deduce_clued_island_snug", [island_cell])
	
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	var extent_size: int = board.get_per_clue_extent_map().get_extent_size(island_cell)
	if extent_size != clue_value:
		_log.end("deduce_clued_island_snug", [island_cell])
		return
	
	var island_root: Vector2i = board.get_island_root_for_cell(island_cell)
	for extent_cell: Vector2i in board.get_per_clue_extent_map().get_extent_cells(island_cell):
		if should_deduce(board, extent_cell):
			add_deduction(extent_cell, CELL_ISLAND, ISLAND_SNUG, [island_cell])
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = extent_cell + neighbor_dir
			if board.get_per_clue_extent_map().needs_buffer(island_root, neighbor):
				add_deduction(neighbor, CELL_WALL, ISLAND_BUFFER, [island_cell])
	
	_log.end("deduce_clued_island_snug", [island_cell])


func deduce_wall_chokepoint(chokepoint: Vector2i) -> void:
	if not should_deduce(board, chokepoint):
		return
	if not board.get_wall_chokepoint_map().chokepoints_by_cell.has(chokepoint):
		return
	
	_log.start("deduce_wall_chokepoint", [chokepoint])
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
	_log.end("deduce_wall_chokepoint", [chokepoint])


func deduce_island(island_cell: Vector2i) -> void:
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if clue_value == -1:
		return
	if liberties.is_empty():
		return
	
	_log.start("deduce_island", [island.front()])
	if clue_value == 0:
		# unclued island
		if liberties.size() == 1:
			_check_unclued_island_forced_expansion(island)
		elif liberties.size() == 2:
			_check_corner_buffer(island)
	else:
		# clued island
		if clue_value == island.size():
			_check_clued_island_moat(island)
		elif liberties.size() == 1 and clue_value > island.size():
			_check_clued_island_forced_expansion(island)
		else:
			if liberties.size() == 2 and clue_value == island.size() + 1:
				_check_clued_island_corner(island)
			if liberties.size() == 2:
				_check_corner_buffer(island)
	_log.end("deduce_island", [island.front()])


func deduce_wall(wall_cell: Vector2i) -> void:
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	if liberties.is_empty():
		return
	
	_log.start("deduce_wall", [wall_cell])
	if liberties.size() == 1 and board.get_walls().size() >= 2:
		_check_wall_expansion(wall)
	_log.end("deduce_wall", [wall_cell])


func deduce_pool(wall_cell: Vector2i) -> void:
	_log.start("deduce_pool", [wall_cell])
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(board.get_wall_for_cell(wall_cell))
	var wall_cell_set: Dictionary[Vector2i, bool] = {}
	for next_wall_cell in wall:
		wall_cell_set[next_wall_cell] = true
	for liberty: Vector2i in liberties:
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
				break
	_log.end("deduce_pool", [wall_cell])


func get_unique_neighbor_island_cells(island_cells: Array[Vector2i]) -> Array[Vector2i]:
	var neighbor_islands_by_root: Dictionary[Vector2i, Vector2i] = {}
	for island_cell: Vector2i in island_cells:
		var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
		if not island.is_empty():
			neighbor_islands_by_root[island.front()] = island_cell
	var result: Array[Vector2i] = neighbor_islands_by_root.values()
	result.sort()
	return result


func run_bifurcation_step() -> void:
	if verbose:
		print("> bifurcating: %s scenarios (%s)" \
				% [bifurcation_engine.get_scenario_count(), bifurcation_engine.get_scenario_keys()])
	for key: String in bifurcation_engine.get_scenario_keys():
		_log.start(key)
		bifurcation_engine.step(key)
		_log.pause(key)
	if bifurcation_engine.has_new_local_contradictions():
		# found a contradiction; we can make a deduction
		_add_local_bifurcation_deductions()
	elif bifurcation_engine.has_available_probes():
		# there's still more to do
		probe_library.add_probe(run_bifurcation_step).set_bifurcation().set_one_shot()
	elif bifurcation_engine.has_new_contradictions(SolverBoard.VALIDATE_SIMPLE):
		# we're stuck; check if any of the scenarios cause a contradiction which we overlooked
		_add_bifurcation_deductions(SolverBoard.VALIDATE_SIMPLE)
	elif bifurcation_engine.has_new_contradictions(SolverBoard.VALIDATE_COMPLEX):
		# we're stuck; check if any of the scenarios cause a contradiction which we overlooked
		_add_bifurcation_deductions(SolverBoard.VALIDATE_COMPLEX)
	else:
		# we're stuck; remove all pending bifurcation scenarios. they're dead ends
		bifurcation_engine.clear()
	if not bifurcation_engine.has_available_probes() and metrics.has("bifurcation_start_time"):
		var bifurcation_duration: int = (Time.get_ticks_usec() - metrics["bifurcation_start_time"])
		metrics.erase("bifurcation_start_time")
		
		if not metrics.has("bifurcation_duration"):
			metrics["bifurcation_duration"] = 0.0
		metrics["bifurcation_duration"] += bifurcation_duration / 1000.0


func should_deduce(target_board: SolverBoard, cell: Vector2i) -> bool:
	return target_board.get_cell(cell) == CELL_EMPTY and (cell not in deductions.cells or perform_redundant_deductions)


func _add_local_bifurcation_deductions() -> void:
	# found a contradiction; we can make a deduction
	var scenario_keys: Array[String] = bifurcation_engine.get_scenario_keys()
	for key: String in scenario_keys:
		_log.start(key)
		if not bifurcation_engine.scenario_has_new_local_contradictions(key):
			_log.end(key)
			continue
		for deduction: Deduction in bifurcation_engine.get_scenario_deductions(key):
			if not should_deduce(board, deduction.pos):
				continue
			add_deduction(deduction.pos, deduction.value, deduction.reason, deduction.reason_cells)
		_log.end(key)
	bifurcation_engine.clear()


func _add_bifurcation_deductions(mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> void:
	# found a contradiction; we can make a deduction
	var scenario_keys: Array[String] = bifurcation_engine.get_scenario_keys()
	for key: String in scenario_keys:
		_log.start(key)
		if not bifurcation_engine.scenario_has_new_contradictions(key, mode):
			_log.end(key)
			continue
		for deduction: Deduction in bifurcation_engine.get_scenario_deductions(key):
			if not should_deduce(board, deduction.pos):
				continue
			add_deduction(deduction.pos, deduction.value, deduction.reason, deduction.reason_cells)
		_log.end(key)
	bifurcation_engine.clear()


## If there are two liberties, and the liberties are diagonal, any blank squares connecting those liberties
## must be walls.
func _check_clued_island_corner(island: Array[Vector2i]) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(island)
	for diagonal_dir: Vector2i in NEIGHBOR_DIRS:
		var diagonal: Vector2i = liberties[0] + diagonal_dir
		if diagonal.distance_to(liberties[1]) != 1:
			continue
		if not should_deduce(board, diagonal):
			continue
		add_deduction(diagonal, CELL_WALL, CORNER_ISLAND, [island.front()])


func _check_corner_buffer(island: Array[Vector2i]) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(island)
	for diagonal_dir: Vector2i in NEIGHBOR_DIRS:
		var diagonal: Vector2i = liberties[0] + diagonal_dir
		if diagonal.distance_to(liberties[1]) != 1:
			continue
		if not should_deduce(board, diagonal):
			continue
		var merged_island_cells: Array[Vector2i] = []
		for merged_dir in NEIGHBOR_DIRS:
			merged_island_cells.append(diagonal + merged_dir)
		merged_island_cells.append(island.front())
		if not _is_valid_merged_island(merged_island_cells, 2):
			var unique_neighbor_island_cells: Array[Vector2i] \
					= get_unique_neighbor_island_cells(merged_island_cells)
			add_deduction(diagonal, CELL_WALL, CORNER_BUFFER,
					unique_neighbor_island_cells)


func _check_unclued_island_forced_expansion(island: Array[Vector2i]) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(island)
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(island)
	squeeze_fill.push_change(liberties[0], CELL_ISLAND)
	squeeze_fill.fill()
	for change: Vector2i in squeeze_fill.changes:
		add_deduction(change, CELL_ISLAND, ISLAND_CONNECTOR, [island[0]])


func _check_clued_island_moat(island: Array[Vector2i]) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(island)
	for liberty: Vector2i in liberties:
		if not should_deduce(board, liberty):
			continue
		add_deduction(liberty, CELL_WALL, ISLAND_MOAT, [island[0]])


func _check_clued_island_forced_expansion(island: Array[Vector2i]) -> void:
	var clue_value: int = board.get_clue_for_island(island)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if liberties.size() != 1 or clue_value <= island.size():
		return
	
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(island)
	squeeze_fill.push_change(liberties[0], CELL_ISLAND)
	squeeze_fill.fill(clue_value - island.size() - 1)
	for new_island_cell: Vector2i in squeeze_fill.changes:
		if should_deduce(board, new_island_cell):
			add_deduction(new_island_cell, CELL_ISLAND, ISLAND_EXPANSION, [island[0]])
	
	if squeeze_fill.changes.size() == clue_value - island.size():
		for new_island_cell: Vector2i in squeeze_fill.changes:
			for new_island_neighbor_dir: Vector2i in NEIGHBOR_DIRS:
				var new_island_neighbor: Vector2i = new_island_cell + new_island_neighbor_dir
				if new_island_neighbor in squeeze_fill.changes:
					continue
				if should_deduce(board, new_island_neighbor):
					add_deduction(new_island_neighbor, CELL_WALL, ISLAND_MOAT, [island[0]])


## Returns true if converting the chokepoint to a wall would enclose a 2x2 pool.[br]
## [codeblock lang=text]
## +------
## | 0 2
## | c n 4
## | 1 3
##
## [0,1]: Cells flanking the chokepoint (diagonals before the corridor)
## [2,3,4]: Cells forming the dead-end pocket (forward and its sides)
## c: Island chokepoint
## n: Neighbor
## [/codeblock]
## If the dead-end pocket ([2,3,4]) is fully blocked, and one diagonal pair ([0,2] or [1,3]) are walls,
## then turning the chokepoint into a wall would create a 2x2 pool.
func _check_island_chokepoint_tiny_pool(chokepoint: Vector2i, dir: Vector2i) -> void:
	if board.get_cell(chokepoint) != CELL_EMPTY:
		return
	if board.get_cell(chokepoint + dir) != CELL_EMPTY:
		return
	
	var magic_cells: Array[Vector2i] = [
		chokepoint + Vector2i(-dir.y, dir.x), chokepoint + Vector2i(dir.y, -dir.x),
		chokepoint + dir + Vector2i(-dir.y, dir.x), chokepoint + dir + Vector2i(dir.y, -dir.x),
		chokepoint + dir + dir]
	var solid: Array[bool] = []
	var wall: Array[bool] = []
	for magic_cell in magic_cells:
		var magic_value: int = board.get_cell(magic_cell)
		solid.append(magic_value == CELL_WALL or magic_value == CELL_INVALID)
		wall.append(magic_value == CELL_WALL)
	
	if (solid[2] and solid[3] and solid[4]) \
			and (wall[0] and wall[2] or wall[1] and wall[3]):
		var pool_cells: Array[Vector2i] = [chokepoint, chokepoint + dir]
		if wall[0] and wall[2]:
			pool_cells.append_array([magic_cells[0], magic_cells[2]])
		if wall[1] and wall[3]:
			pool_cells.append_array([magic_cells[1], magic_cells[3]])
		pool_cells.sort()
		add_deduction(chokepoint, CELL_ISLAND, POOL_CHOKEPOINT, pool_cells)


func _check_wall_expansion(wall: Array[Vector2i]) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(wall)
	squeeze_fill.push_change(liberties[0], CELL_WALL)
	squeeze_fill.fill()
	for change: Vector2i in squeeze_fill.changes:
		add_deduction(change, CELL_WALL, WALL_EXPANSION, [wall.front()])


func _create_change_probes(changes: Array[Dictionary]) -> void:
	var affected_wall_roots: Dictionary[Vector2i, bool] = {}
	var affected_island_roots: Dictionary[Vector2i, bool] = {}
	var cells_to_check: Dictionary[Vector2i, bool] = {}
	for change: Dictionary[String, Variant] in changes:
		var cell: Vector2i = change["pos"]
		cells_to_check[cell] = true
		for neighbor_dir in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			cells_to_check[neighbor] = true
	for cell_to_check: Vector2i in cells_to_check:
		var wall_root: Vector2i = board.get_wall_root_for_cell(cell_to_check)
		if wall_root != POS_NOT_FOUND:
			affected_wall_roots[wall_root] = true
		var island_root: Vector2i = board.get_island_root_for_cell(cell_to_check)
		if island_root != POS_NOT_FOUND:
			affected_island_roots[island_root] = true
	
	for wall_root: Vector2i in affected_wall_roots:
		deduce_wall(wall_root)
		create_wall_probes(board.get_wall_for_cell(wall_root))
	
	for island_root: Vector2i in affected_island_roots:
		deduce_island(island_root)


func _create_default_probes() -> void:
	# starting techniques; we do these once and then never again
	probe_library.add_probe(deduce_all_islands_of_one).set_one_shot().set_startup()
	probe_library.add_probe(deduce_all_adjacent_clues).set_one_shot().set_startup()
	
	# basic techniques; we can do these again and again
	probe_library.add_probe(create_all_island_probes)
	probe_library.add_probe(create_all_wall_probes)
	probe_library.add_probe(create_wall_chokepoint_probes)
	probe_library.add_probe(create_island_chokepoint_probes)
	probe_library.add_probe(deduce_all_island_dividers)
	probe_library.add_probe(deduce_all_unreachable_squares)
	probe_library.add_probe(deduce_unclued_lifeline)
	
	# advanced techniques; these require bifurcation and are very expensive
	probe_library.add_probe(create_bifurcation_probes).set_bifurcation()
	probe_library.add_probe(create_wall_strangle_probes).set_bifurcation()
	probe_library.add_probe(create_island_battleground_probes).set_bifurcation()
	probe_library.add_probe(create_island_release_probes).set_bifurcation()
	probe_library.add_probe(create_island_strangle_probes).set_bifurcation()


func _find_adjacent_clues(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if NurikabeUtils.is_clue(board.get_cell(neighbor)):
			result.append(neighbor)
	return result


func _find_clued_neighbor_roots(cell: Vector2i) -> Array[Vector2i]:
	var clued_neighbor_roots: Dictionary[Vector2i, bool] = {}
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if board.get_clue_for_island_cell(neighbor) == 0:
			continue
		var neighbor_root: Vector2i = board.get_island_root_for_cell(neighbor)
		clued_neighbor_roots[neighbor_root] = true
	return clued_neighbor_roots.keys()


func _is_border_cell(cell: Vector2i) -> bool:
	var result: bool = false
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if board.get_cell(neighbor) == CELL_INVALID:
			result = true
			break
	return result


func _is_valid_merged_island(island_cells: Array[Vector2i], merge_cells: int) -> bool:
	var visited_island_roots: Dictionary[Vector2i, bool] = {}
	var total_joined_size: int = merge_cells
	var total_clues: int = 0
	var clue_value: int = 0
	
	var result: bool = true
	
	for island_cell: Vector2i in island_cells:
		var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
		if island.is_empty() or visited_island_roots.has(island.front()):
			continue
		var neighbor_clue_value: int = board.get_clue_for_island_cell(island_cell)
		total_joined_size += island.size()
		if neighbor_clue_value >= 1:
			if clue_value > 0:
				result = false
				break
			clue_value = neighbor_clue_value
			total_clues += 1
			if total_clues >= 2:
				result = false
				break
		if clue_value > 0 and total_joined_size > clue_value:
			result = false
			break
		visited_island_roots[island.front()] = true
	
	return result
