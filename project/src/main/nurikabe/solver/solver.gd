class_name Solver

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

const UNKNOWN_REASON: Deduction.Reason = Deduction.Reason.UNKNOWN

## starting techniques
const ISLAND_OF_ONE: Deduction.Reason = Deduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Deduction.Reason = Deduction.Reason.ADJACENT_CLUES

## basic techniques
const CORNER_BUFFER: Deduction.Reason = Deduction.Reason.CORNER_BUFFER
const CORNER_ISLAND: Deduction.Reason = Deduction.Reason.CORNER_ISLAND
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
var board: SolverBoard
var metrics: Dictionary[String, Variant] = {}

var _change_history: Array[Dictionary] = []
var _log: DeductionLogger = DeductionLogger.new(self)
var _task_history: Dictionary[String, Dictionary] = {
}
var _task_queue: Array[Dictionary] = [
]
var _bifurcation_engine: BifurcationEngine = BifurcationEngine.new()

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
		history_item["tick"] = board.get_filled_cell_count()
		_change_history.append(history_item)
	
	_change_history.append_array(changes)
	board.set_cells(changes)
	deductions.clear()
	
	_react_to_changes(changes)


func apply_heat() -> void:
	board.decrease_heat()
	board.increase_heat(deductions.cells.keys())


func clear() -> void:
	deductions.clear()
	metrics.clear()
	_bifurcation_engine.clear()
	_change_history.clear()
	_task_history.clear()
	_task_queue.clear()


func is_queue_empty() -> bool:
	return _task_queue.is_empty()


func get_changes() -> Array[Dictionary]:
	return deductions.get_changes()


func schedule_tasks(allow_bifurcation: bool = true) -> void:
	if get_last_run(enqueue_islands_of_one) == -1:
		schedule_task(enqueue_islands_of_one, 1000)
	
	if get_last_run(enqueue_adjacent_clues) == -1:
		schedule_task(enqueue_adjacent_clues, 1000)
	
	if has_scheduled_task(enqueue_islands):
		pass
	elif get_last_run(enqueue_islands) == -1:
		schedule_task(enqueue_islands, 150)
	elif get_last_run(enqueue_islands) < board.get_filled_cell_count():
		schedule_task(enqueue_islands, 50)
	
	if has_scheduled_task(enqueue_walls):
		pass
	elif get_last_run(enqueue_walls) == -1:
		schedule_task(enqueue_walls, 145)
	elif get_last_run(enqueue_walls) < board.get_filled_cell_count():
		schedule_task(enqueue_walls, 45)
	
	if has_scheduled_task(enqueue_island_dividers):
		pass
	elif get_last_run(enqueue_island_dividers) == -1:
		schedule_task(enqueue_island_dividers, 140)
	elif get_last_run(enqueue_island_dividers) < board.get_filled_cell_count():
		schedule_task(enqueue_island_dividers, 40)
	
	if has_scheduled_task(enqueue_unreachable_squares):
		pass
	elif get_last_run(enqueue_unreachable_squares) == -1:
		schedule_task(enqueue_unreachable_squares, 135)
	elif get_last_run(enqueue_unreachable_squares) < board.get_filled_cell_count():
		schedule_task(enqueue_unreachable_squares, 35)
	
	if has_scheduled_task(enqueue_wall_chokepoints):
		pass
	elif get_last_run(enqueue_wall_chokepoints) == -1:
		schedule_task(enqueue_wall_chokepoints, 135)
	elif get_last_run(enqueue_wall_chokepoints) < board.get_filled_cell_count():
		schedule_task(enqueue_wall_chokepoints, 35)
	
	if has_scheduled_task(enqueue_island_chokepoints):
		pass
	elif get_last_run(enqueue_island_chokepoints) == -1:
		schedule_task(enqueue_island_chokepoints, 130)
	elif get_last_run(enqueue_island_chokepoints) < board.get_filled_cell_count():
		schedule_task(enqueue_island_chokepoints, 30)
	
	if is_queue_empty() and allow_bifurcation:
		metrics["bifurcation_start_time"] = Time.get_ticks_usec()
		
		if has_scheduled_task(enqueue_wall_strangle):
			pass
		elif get_last_run(enqueue_wall_strangle) < board.get_filled_cell_count():
			schedule_task(enqueue_wall_strangle, 20)
		
		if has_scheduled_task(enqueue_island_battleground):
			pass
		elif get_last_run(enqueue_island_battleground) < board.get_filled_cell_count():
			schedule_task(enqueue_island_battleground, 20)
		
		if has_scheduled_task(enqueue_island_release):
			pass
		elif get_last_run(enqueue_island_release) < board.get_filled_cell_count():
			schedule_task(enqueue_island_release, 20)
		
		if has_scheduled_task(enqueue_island_strangle):
			pass
		elif get_last_run(enqueue_island_strangle) < board.get_filled_cell_count():
			schedule_task(enqueue_island_strangle, 20)
		
		if not metrics.has("bifurcation_stops"):
			metrics["bifurcation_stops"] = 0
		metrics["bifurcation_stops"] += 1


func get_last_run(callable: Callable) -> int:
	var task_key: String = _task_key(callable)
	var history_item: Dictionary[String, Variant] = _task_history.get(task_key, {} as Dictionary[String, Variant])
	return -1 if history_item.is_empty() else history_item["last_run"]


func has_scheduled_task(callable: Callable) -> bool:
	return not get_scheduled_task(callable).is_empty()


func has_scheduled_tasks() -> bool:
	return not _task_queue.is_empty()


func get_scheduled_task(callable: Callable) -> Dictionary[String, Variant]:
	var key: String = _task_key(callable)
	var result: Dictionary[String, Variant]
	for task: Dictionary[String, Variant] in _task_queue:
		if task["key"] == key:
			result = task
			break
	return result


func schedule_task(callable: Callable, priority: int) -> void:
	var scheduled_task: Dictionary[String, Variant] = get_scheduled_task(callable)
	var tasks_dirty: bool = false
	if scheduled_task.is_empty():
		var key: String = _task_key(callable)
		_task_queue.append({"key": key, "callable": callable, "priority": priority} as Dictionary[String, Variant])
		tasks_dirty = true
	elif scheduled_task["priority"] != priority:
		scheduled_task["priority"] = priority
		tasks_dirty = true
	if tasks_dirty:
		_task_queue.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
			return a.priority > b.priority)


func step() -> void:
	if not _task_queue.is_empty():
		run_next_task()


func print_queue() -> void:
	var strings: Array[String] = []
	print("task_queue.size=%s; filled_cells=%s" % [_task_queue.size(), board.get_filled_cell_count()])
	for task: Dictionary[String, Variant] in _task_queue:
		strings.append(" priority=%s: %s" % [task["priority"], task["key"]])
	print("\n".join(strings))


func run_all_tasks() -> void:
	while not _task_queue.is_empty():
		run_next_task()


func run_next_task() -> void:
	if _task_queue.is_empty():
		return
	
	var next_task: Dictionary[String, Variant] = _task_queue.pop_front()
	if verbose:
		print("(%s;%s) run %s" % [board.get_filled_cell_count(), Time.get_ticks_msec(), next_task["key"]])
	_task_history[next_task["key"]] = {
		"last_run": board.get_filled_cell_count()
	} as Dictionary[String, Variant]
	next_task["callable"].call()


func deduce_adjacent_clues(clue_cell: Vector2i) -> void:
	if not NurikabeUtils.is_clue(board.get_cell(clue_cell)):
		return
	
	_log.start("adjacent_clues", [clue_cell])
	
	for neighbor: Vector2i in board.get_neighbors(clue_cell):
		if not _should_deduce(board, neighbor):
			continue
		var adjacent_clues: Array[Vector2i] = _find_adjacent_clues(neighbor)
		if adjacent_clues.size() >= 2:
			add_deduction(neighbor, CELL_WALL,
				ADJACENT_CLUES, [adjacent_clues[0], adjacent_clues[1]] as Array[Vector2i])
	
	_log.end("adjacent_clues", [clue_cell])


func deduce_island_chokepoint(chokepoint: Vector2i) -> void:
	var old_deductions_size: int = deductions.size()
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and _should_deduce(board, chokepoint):
		deduce_island_chokepoint_cramped(chokepoint)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and _should_deduce(board, chokepoint):
		deduce_island_chokepoint_tiny_pool(chokepoint)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and _should_deduce(board, chokepoint):
		deduce_island_chokepoint_pool(chokepoint)


## Deduces when a chokepoint prevents an island from reaching its required size.
func deduce_island_chokepoint_cramped(chokepoint: Vector2i) -> void:
	_log.start("island_chokepoint_cramped", [chokepoint])
	
	var clue_cell: Vector2i = board.get_global_reachability_map().get_nearest_clue_cell(chokepoint)
	if clue_cell == POS_NOT_FOUND:
		_log.end("island_chokepoint_cramped", [chokepoint])
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
	
	_log.end("island_chokepoint_cramped", [chokepoint])


## Deduces when a chokepoint forces a 2x2 pool in a simple 2-cell case.
func deduce_island_chokepoint_tiny_pool(chokepoint: Vector2i) -> void:
	_log.start("island_chokepoint_tiny_pool", [chokepoint])
	
	# Check for two empty cells leading into a dead end, which create a pool.
	var old_deductions_size: int = deductions.size()
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		_check_island_chokepoint_tiny_pool(chokepoint, dir)
		if deductions.size() > old_deductions_size:
			break
	
	_log.end("island_chokepoint_tiny_pool", [chokepoint])


## Deduces when a chokepoint forces a 2x2 pool in a complex multi-cell case.
func deduce_island_chokepoint_pool(chokepoint: Vector2i) -> void:
	_log.start("island_chokepoint_pool", [chokepoint])
	
	var split_neighbor_set: Dictionary[Vector2i, bool] = {}
	var split_root_set: Dictionary[Vector2i, bool] = {}
	for neighbor: Vector2i in board.get_neighbors(chokepoint):
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
		board.perform_bfs(neighbor, func(cell: Vector2i) -> bool:
			if board.get_cell(cell) in [CELL_WALL, CELL_INVALID] or cell == chokepoint:
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
	
	_log.end("island_chokepoint_pool", [chokepoint])


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
		solid.append(board.get_cell(magic_cell) in [CELL_WALL, CELL_INVALID])
		wall.append(board.get_cell(magic_cell) == CELL_WALL)
	
	if (solid[2] and solid[3] and solid[4]) \
			and (wall[0] and wall[2] or wall[1] and wall[3]):
		var pool_cells: Array[Vector2i] = [chokepoint, chokepoint + dir]
		if wall[0] and wall[2]:
			pool_cells.append_array([magic_cells[0], magic_cells[2]])
		if wall[1] and wall[3]:
			pool_cells.append_array([magic_cells[1], magic_cells[3]])
		pool_cells.sort()
		add_deduction(chokepoint, CELL_ISLAND, POOL_CHOKEPOINT, pool_cells)


func deduce_clue_chokepoint(island_cell: Vector2i) -> void:
	var old_deductions_size: int = deductions.size()
	
	if deductions.size() == old_deductions_size or perform_redundant_deductions:
		deduce_clue_chokepoint_snug(island_cell)
	
	if deductions.size() == old_deductions_size or perform_redundant_deductions:
		deduce_clue_chokepoint_loose(island_cell)
	
	if deductions.size() == old_deductions_size or perform_redundant_deductions:
		deduce_clue_chokepoint_wall_weaver(island_cell)


func deduce_clue_chokepoint_snug(island_cell: Vector2i) -> void:
	_log.start("clue_chokepoint_snug", [island_cell])
	
	var island_root: Vector2i = board.get_island_root_for_cell(island_cell)
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	if board.get_per_clue_chokepoint_map().get_component_cell_count(island_cell) != clue_value:
		return
	
	var component_cells: Array[Vector2i] = board.get_per_clue_chokepoint_map().get_component_cells(island_cell)
	for component_cell: Vector2i in component_cells:
		if board.get_cell(component_cell) == CELL_EMPTY:
			add_deduction(component_cell, CELL_ISLAND, ISLAND_SNUG, [island_cell])
		for neighbor: Vector2i in board.get_neighbors(component_cell):
			if board.get_per_clue_chokepoint_map().needs_buffer(island_root, neighbor):
				add_deduction(neighbor, CELL_WALL, ISLAND_BUFFER, [island_cell])
	
	_log.end("clue_chokepoint_snug", [island_cell])


func deduce_clue_chokepoint_loose(island_cell: Vector2i) -> void:
	_log.start("clue_chokepoint_loose", [island_cell])
	
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var chokepoint_cells: Dictionary[Vector2i, int] = \
			board.get_per_clue_chokepoint_map().find_chokepoint_cells(island_cell)
	for chokepoint: Vector2i in chokepoint_cells:
		if not _should_deduce(board, chokepoint):
			continue
		if chokepoint_cells[chokepoint] == CELL_ISLAND:
			if chokepoint in board.get_liberties(island):
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_EXPANSION, [island_cell])
			else:
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_CHOKEPOINT, [island_cell])
		else:
			add_deduction(chokepoint, CELL_WALL, ISLAND_BUFFER, [island_cell])
	
	_log.end("clue_chokepoint_loose", [island_cell])


func deduce_clue_chokepoint_wall_weaver(island_cell: Vector2i) -> void:
	_log.start("clue_chokepoint_wall_weaver", [island_cell])
	
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
		for neighbor: Vector2i in board.get_neighbors(cell):
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
		if not _should_deduce(board, connector):
			continue
		deductions.add_deduction(connector, CELL_WALL, WALL_WEAVER, [island_cell])
	
	_log.end("clue_chokepoint_wall_weaver", [island_cell])


func deduce_unclued_lifeline() -> void:
	_log.start("unclued_lifeline")
	
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
			if not _should_deduce(board, chokepoint):
				continue
			var unchoked_special_count: int = \
					chokepoint_map.get_unchoked_special_count(chokepoint, clue_root)
			if unchoked_special_count < unclued.size():
				add_deduction(chokepoint, CELL_ISLAND, UNCLUED_LIFELINE, [clue_root])
	
	_log.end("unclued_lifeline")


func deduce_island_of_one(clue_cell: Vector2i) -> void:
	_log.start("island_of_one", [clue_cell])
	
	if not board.get_cell(clue_cell) == 1:
		_log.end("island_of_one", [clue_cell])
		return
	
	for neighbor: Vector2i in board.get_neighbors(clue_cell):
		if not _should_deduce(board, neighbor):
			continue
		add_deduction(neighbor, CELL_WALL,
			ISLAND_OF_ONE, [clue_cell])
	
	_log.end("island_of_one", [clue_cell])


func deduce_clued_island(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	if clue_value < 1:
		# unclued/invalid group
		return
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if liberties.is_empty():
		# sealed group
		return
	
	var old_deductions_size: int = deductions.size()
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and clue_value == island.size():
		deduce_clued_island_moat(island_cell)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and liberties.size() == 1 and clue_value > island.size():
		deduce_clued_island_forced_expansion(island_cell)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions):
		deduce_clued_island_snug(island_cell)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and liberties.size() == 2 and clue_value == island.size() + 1:
		deduce_clued_island_corner(island_cell)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and liberties.size() == 2:
		deduce_corner_buffer(island_cell)


func deduce_clued_island_moat(island_cell: Vector2i) -> void:
	_log.start("clued_island_moat", [island_cell])
	
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if clue_value != island.size():
		_log.end("clued_island_moat", [island_cell])
		return
	
	for liberty: Vector2i in liberties:
		if not _should_deduce(board, liberty):
			continue
		add_deduction(liberty, CELL_WALL, ISLAND_MOAT, [island[0]])
	
	_log.end("clued_island_moat", [island_cell])


func deduce_clued_island_forced_expansion(island_cell: Vector2i) -> void:
	_log.start("clued_island_forced_expansion", [island_cell])
	
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if liberties.size() != 1 or clue_value <= island.size():
		_log.end("clued_island_forced_expansion", [island_cell])
		return
	
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(island)
	squeeze_fill.push_change(liberties[0], CELL_ISLAND)
	squeeze_fill.fill(clue_value - island.size() - 1)
	for new_island_cell: Vector2i in squeeze_fill.changes:
		if _should_deduce(board, new_island_cell):
			add_deduction(new_island_cell, CELL_ISLAND, ISLAND_EXPANSION, [island[0]])
	
	if squeeze_fill.changes.size() == clue_value - island.size():
		for new_island_cell: Vector2i in squeeze_fill.changes:
			for new_island_neighbor: Vector2i in board.get_neighbors(new_island_cell):
				if new_island_neighbor in squeeze_fill.changes:
					continue
				if _should_deduce(board, new_island_neighbor):
					add_deduction(new_island_neighbor, CELL_WALL, ISLAND_MOAT, [island[0]])
	
	_log.end("clued_island_forced_expansion", [island_cell])


func deduce_clued_island_snug(island_cell: Vector2i) -> void:
	_log.start("clued_island_snug", [island_cell])
	
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	var component_cell_count: int = board.get_island_chokepoint_map().get_component_cell_count(island_cell)
	if component_cell_count != clue_value:
		_log.end("clued_island_snug", [island_cell])
		return
	
	for deduction_cell: Vector2i in board.get_island_chokepoint_map().get_component_cells(island_cell):
		if _should_deduce(board, deduction_cell):
			add_deduction(deduction_cell, CELL_ISLAND, ISLAND_SNUG, [island_cell])
	
	_log.end("clued_island_snug", [island_cell])


## If there are two liberties, and the liberties are diagonal, any blank squares connecting those liberties
## must be walls.
func deduce_clued_island_corner(island_cell: Vector2i) -> void:
	_log.start("clued_island_corner", [island_cell])
	
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	var liberty_connectors: Array[Vector2i] = []
	liberty_connectors.assign(Utils.intersection( \
			board.get_neighbors(liberties[0]), board.get_neighbors(liberties[1])))
	for liberty_connector: Vector2i in liberty_connectors:
		if not _should_deduce(board, liberty_connector):
			continue
		add_deduction(liberty_connector, CELL_WALL, CORNER_ISLAND, [island_cell])
	
	_log.end("clued_island_corner", [island_cell])


func deduce_corner_buffer(island_cell: Vector2i) -> void:
	_log.start("corner_buffer", [island_cell])

	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	var diagonals: Array[Vector2i] = []
	for neighbor: Vector2i in board.get_neighbors(liberties[0]):
		if (neighbor - liberties[1]).length() != 1:
			continue
		if not _should_deduce(board, neighbor):
			continue
		diagonals.append(neighbor)
	
	for diagonal: Vector2i in diagonals:
		var merged_island_cells: Array[Vector2i] = []
		merged_island_cells.append_array(board.get_neighbors(diagonal))
		merged_island_cells.append(island_cell)
		if not is_valid_merged_island(merged_island_cells, 2):
			var unique_neighbor_island_cells: Array[Vector2i] \
					= get_unique_neighbor_island_cells(merged_island_cells)
			add_deduction(diagonal, CELL_WALL, CORNER_BUFFER,
					unique_neighbor_island_cells)
	
	_log.end("corner_buffer", [island_cell])


func deduce_unclued_island(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	var clue_value: int = board.get_clue_for_island_cell(island_cell)
	if clue_value != 0:
		# clued/invalid group
		return
	if liberties.size() == 1:
		deduce_unclued_island_forced_expansion(island_cell)
	if liberties.size() == 2:
		deduce_corner_buffer(island_cell)


func deduce_unclued_island_forced_expansion(island_cell: Vector2i) -> void:
	_log.start("unclued_island_forced_expansion", [island_cell])
	
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var liberties: Array[Vector2i] = board.get_liberties(island)
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(island)
	squeeze_fill.push_change(liberties[0], CELL_ISLAND)
	squeeze_fill.fill()
	for change: Vector2i in squeeze_fill.changes:
		add_deduction(change, CELL_ISLAND, ISLAND_CONNECTOR, [island[0]])
	
	_log.end("unclued_island_forced_expansion", [island_cell])


func deduce_island_divider(island_cell: Vector2i) -> void:
	_log.start("island_divider", [island_cell])
	
	var liberties: Array[Vector2i] = board.get_liberties(board.get_island_for_cell(island_cell))
	for liberty: Vector2i in liberties:
		if not _should_deduce(board, liberty):
			continue
		
		if not is_valid_merged_island(board.get_neighbors(liberty), 1):
			var unique_neighbor_island_cells: Array[Vector2i] \
					= get_unique_neighbor_island_cells(board.get_neighbors(liberty))
			add_deduction(liberty, CELL_WALL, ISLAND_DIVIDER, unique_neighbor_island_cells)
	
	_log.end("island_divider", [island_cell])


func deduce_unreachable_square(cell: Vector2i) -> void:
	if not _should_deduce(board, cell):
		return
	
	_log.start("unreachable_square", [cell])
	
	match board.get_global_reachability_map().get_clue_reachability(cell):
		GlobalReachabilityMap.ClueReachability.UNREACHABLE:
			add_deduction(cell, CELL_WALL, UNREACHABLE_CELL,
					[board.get_global_reachability_map().get_nearest_clue_cell(cell)])
		
		GlobalReachabilityMap.ClueReachability.IMPOSSIBLE:
			add_deduction(cell, CELL_WALL, WALL_BUBBLE)
		
		GlobalReachabilityMap.ClueReachability.CONFLICT:
			var clued_neighbor_roots: Array[Vector2i] = _find_clued_neighbor_roots(cell)
			add_deduction(cell, CELL_WALL, ISLAND_DIVIDER,
					[clued_neighbor_roots[0], clued_neighbor_roots[1]])
	
	_log.end("unreachable_square", [cell])


func deduce_wall(wall_cell: Vector2i) -> void:
	var old_deductions_size: int = deductions.size()
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and board.get_walls().size() >= 2 and liberties.size() == 1:
		deduce_wall_expansion(wall_cell)
	
	if (deductions.size() == old_deductions_size or perform_redundant_deductions) \
			and wall.size() >= 3 and liberties.size() >= 1:
		deduce_pool(wall_cell)


func deduce_wall_chokepoint(chokepoint: Vector2i) -> void:
	if not _should_deduce(board, chokepoint):
		return
	
	var max_choked_special_count: int = 0
	var split_neighbor: Vector2i = POS_NOT_FOUND
	for neighbor: Vector2i in board.get_neighbors(chokepoint):
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


func deduce_wall_expansion(wall_cell: Vector2i) -> void:
	_log.start("wall_expansion", [wall_cell])
	
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(board.get_wall_for_cell(wall_cell))
	var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
	squeeze_fill.skip_cells(wall)
	squeeze_fill.push_change(liberties[0], CELL_WALL)
	squeeze_fill.fill()
	for change: Vector2i in squeeze_fill.changes:
		add_deduction(change, CELL_WALL, WALL_EXPANSION, [wall_cell])
	
	_log.end("wall_expansion", [wall_cell])


func deduce_pool(wall_cell: Vector2i) -> void:
	_log.start("pool", [wall_cell])
	
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(board.get_wall_for_cell(wall_cell))
	var wall_cell_set: Dictionary[Vector2i, bool] = {}
	for next_wall_cell in wall:
		wall_cell_set[next_wall_cell] = true
	for liberty: Vector2i in liberties:
		if not _should_deduce(board, liberty):
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
	
	_log.end("pool", [wall_cell])


func enqueue_adjacent_clues() -> void:
	for cell: Vector2i in board.cells:
		if NurikabeUtils.is_clue(board.get_cell(cell)):
			schedule_task(deduce_adjacent_clues.bind(cell), 1100)


func enqueue_island_chokepoints() -> void:
	var chokepoints: Array[Vector2i] = board.get_island_chokepoint_map().chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		if not _should_deduce(board, chokepoint):
			continue
		schedule_task(deduce_island_chokepoint.bind(chokepoint), 230)
	
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		if board.get_liberties(island).is_empty():
			continue
		schedule_task(deduce_clue_chokepoint.bind(island.front()), 225)
	
	schedule_task(deduce_unclued_lifeline, 224)


func enqueue_wall_chokepoints() -> void:
	var chokepoints: Array[Vector2i] = board.get_wall_chokepoint_map().chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		if not _should_deduce(board, chokepoint):
			continue
		schedule_task(deduce_wall_chokepoint.bind(chokepoint), 235)


func is_border_cell(cell: Vector2i) -> bool:
	var result: bool = false
	for neighbor: Vector2i in board.get_neighbors(cell):
		if board.get_cell(neighbor) == CELL_INVALID:
			result = true
			break
	return result


func enqueue_islands() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		if board.get_liberties(island).is_empty():
			continue
		var clue_value: int = board.get_clue_for_island(island)
		if clue_value == -1:
			# invalid island
			continue
		elif clue_value == 0:
			# unclued island
			schedule_task(deduce_unclued_island.bind(island.front()), 250)
		else:
			# clued island
			schedule_task(deduce_clued_island.bind(island.front()), 250)


## Executes a bifurcation on two islands which are almost adjacent.
func enqueue_island_battleground() -> void:
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
		for neighbor: Vector2i in board.get_neighbors(cell):
			if not clued_island_neighbors_by_empty_cell.has(neighbor):
				continue
			if clued_island_neighbors_by_empty_cell[neighbor].size() != 1:
				continue
			if clued_island_neighbors_by_empty_cell[neighbor][0] == clued_island_neighbors_by_empty_cell[cell][0]:
				continue
			var clued_liberty: Vector2i = clued_island_neighbors_by_empty_cell[cell][0]
			var neighbor_liberty: Vector2i = clued_island_neighbors_by_empty_cell[neighbor][0]
			_add_bifurcation_scenario(
				"island_battleground", [clued_liberty, neighbor_liberty],
				{cell: CELL_ISLAND, neighbor: CELL_WALL},
				[Deduction.new(cell, CELL_WALL,
						ISLAND_BATTLEGROUND, [clued_liberty, neighbor_liberty])])
	
	if _bifurcation_engine.get_scenario_count() >= 1 \
			and not has_scheduled_task(run_bifurcation_step):
		schedule_task(run_bifurcation_step, 10)


## Executes a bifurcation on an island with only two liberties, testing each possible wall/island pair.
func enqueue_island_release() -> void:
	for island: Array[Vector2i] in board.get_islands():
		if board.get_liberties(island).size() != 2:
			continue
		var clue_value: int = board.get_clue_for_island(island)
		var liberties: Array[Vector2i] = board.get_liberties(island)
		for liberty: Vector2i in liberties:
			if not _should_deduce(board, liberty):
				continue
			
			var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
			squeeze_fill.push_change(liberty, CELL_WALL)
			for other_liberty: Vector2i in liberties:
				if other_liberty == liberty:
					continue
				if not _should_deduce(board, other_liberty):
					continue
				squeeze_fill.push_change(other_liberty, CELL_ISLAND)
			squeeze_fill.skip_cells(island)
			squeeze_fill.fill(clue_value - island.size() - 1)
			_add_bifurcation_scenario(
				"island_release", [island.front(), liberty],
				squeeze_fill.changes,
				[Deduction.new(liberty, CELL_ISLAND, ISLAND_RELEASE, [island.front()])]
			)
	
	if _bifurcation_engine.get_scenario_count() >= 1 \
			and not has_scheduled_task(run_bifurcation_step):
		schedule_task(run_bifurcation_step, 10)


## Executes a bifurcation on an island which is one cell away from being complete.
func enqueue_island_strangle() -> void:
	for island: Array[Vector2i] in board.get_islands():
		var clue_value: int = board.get_clue_for_island(island)
		if island.size() != clue_value - 1:
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		for liberty: Vector2i in liberties:
			if not _should_deduce(board, liberty):
				continue
			
			var assumptions: Dictionary[Vector2i, int] = {}
			assumptions[liberty] = CELL_ISLAND
			for new_wall_cell: Vector2i in board.get_neighbors(liberty):
				if not _should_deduce(board, new_wall_cell):
					continue
				assumptions[new_wall_cell] = CELL_WALL
			for other_liberty: Vector2i in liberties:
				if other_liberty == liberty:
					continue
				if not _should_deduce(board, other_liberty):
					continue
				assumptions[other_liberty] = CELL_WALL
			
			_add_bifurcation_scenario(
				"island_strangle", [island.front(), liberty],
				assumptions,
				[Deduction.new(liberty, CELL_WALL, ISLAND_STRANGLE, [island.front()])]
			)
	
	if _bifurcation_engine.get_scenario_count() >= 1 \
			and not has_scheduled_task(run_bifurcation_step):
		schedule_task(run_bifurcation_step, 10)


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
func enqueue_wall_strangle() -> void:
	var walls: Array[Array] = board.get_walls()
	if walls.size() < 2:
		# The wall strangle deduction requires two walls.
		return
	
	for wall: Array[Vector2i] in walls:
		var liberties: Array[Vector2i] = board.get_liberties(wall)
		if liberties.size() != 2:
			continue
		
		var scenario_key: String
		var reason: Deduction.Reason
		if liberties.any(is_border_cell) or wall.any(is_border_cell):
			scenario_key = "border_hug"
			reason = BORDER_HUG
		else:
			scenario_key = "wall_strangle"
			reason = WALL_STRANGLE
			
		for liberty: Vector2i in liberties:
			var other_liberty: Vector2i = liberties[1] if liberty == liberties[0] else liberties[0]
			
			var squeeze_fill: SqueezeFill = SqueezeFill.new(board)
			squeeze_fill.push_change(liberty, CELL_ISLAND)
			squeeze_fill.push_change(other_liberty, CELL_WALL)
			squeeze_fill.skip_cells(wall)
			squeeze_fill.fill()
			_add_bifurcation_scenario(
				scenario_key, [wall.front(), liberty],
				squeeze_fill.changes,
				[Deduction.new(liberty, CELL_WALL, reason, [wall.front()])]
			)
	if _bifurcation_engine.get_scenario_count() >= 1 \
			and not has_scheduled_task(run_bifurcation_step):
		schedule_task(run_bifurcation_step, 10)


func enqueue_island_dividers() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var clue_value: int = board.get_clue_for_island(island)
		if clue_value < 1:
			# unclued/invalid island
			continue
		if board.get_liberties(island).is_empty():
			continue
		schedule_task(deduce_island_divider.bind(island.front()), 240)


func enqueue_islands_of_one() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell(cell) != 1:
			continue
		if board.get_liberties(board.get_island_for_cell(cell)).is_empty():
			continue
		schedule_task(deduce_island_of_one.bind(cell), 1100)


func enqueue_walls() -> void:
	var walls: Array[Array] = board.get_walls()
	for wall: Array[Vector2i] in walls:
		if board.get_liberties(wall).is_empty():
			continue
		schedule_task(deduce_wall.bind(wall.front()), 245)


func enqueue_unreachable_squares() -> void:
	for cell: Vector2i in board.cells:
		if not _should_deduce(board, cell):
			continue
		if board.get_global_reachability_map().get_clue_reachability(cell) \
				!= GlobalReachabilityMap.ClueReachability.REACHABLE:
			schedule_task(deduce_unreachable_square.bind(cell), 235)


func get_unique_neighbor_island_cells(island_cells: Array[Vector2i]) -> Array[Vector2i]:
	var neighbor_islands_by_root: Dictionary[Vector2i, Vector2i] = {}
	for island_cell: Vector2i in island_cells:
		var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
		if not island.is_empty():
			neighbor_islands_by_root[island.front()] = island_cell
	var result: Array[Vector2i] = neighbor_islands_by_root.values()
	result.sort()
	return result


func is_valid_merged_island(island_cells: Array[Vector2i], merge_cells: int) -> bool:
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


func run_bifurcation_step() -> void:
	if verbose:
		print("> bifurcating: %s scenarios" % [_bifurcation_engine.get_scenario_count()])
	for key: String in _bifurcation_engine.get_scenario_keys():
		_log.start(key)
		_bifurcation_engine.step(key)
		_log.pause(key)
	if _bifurcation_engine.has_new_local_contradictions():
		# found a contradiction; we can make a deduction
		_add_local_bifurcation_deductions()
	elif not _bifurcation_engine.is_queue_empty():
		# there's still more to do
		schedule_task(run_bifurcation_step, 10)
	elif _bifurcation_engine.has_new_contradictions(SolverBoard.VALIDATE_SIMPLE):
		# we're stuck; check if any of the scenarios cause a contradiction which we overlooked
		_add_bifurcation_deductions(SolverBoard.VALIDATE_SIMPLE)
	elif _bifurcation_engine.has_new_contradictions(SolverBoard.VALIDATE_COMPLEX):
		# we're stuck; check if any of the scenarios cause a contradiction which we overlooked
		_add_bifurcation_deductions(SolverBoard.VALIDATE_COMPLEX)
	
	if _bifurcation_engine.is_queue_empty() and metrics.has("bifurcation_start_time"):
		var bifurcation_duration: int = (Time.get_ticks_usec() - metrics["bifurcation_start_time"])
		metrics.erase("bifurcation_start_time")
		
		if not metrics.has("bifurcation_duration"):
			metrics["bifurcation_duration"] = 0.0
		metrics["bifurcation_duration"] += bifurcation_duration / 1000.0


func _add_local_bifurcation_deductions() -> void:
	# found a contradiction; we can make a deduction
	var scenario_keys: Array[String] = _bifurcation_engine.get_scenario_keys()
	for key: String in scenario_keys:
		_log.start(key)
		if not _bifurcation_engine.scenario_has_new_local_contradictions(key):
			_log.end(key)
			continue
		for deduction: Deduction in _bifurcation_engine.get_scenario_deductions(key):
			if not _should_deduce(board, deduction.pos):
				continue
			add_deduction(deduction.pos, deduction.value, deduction.reason, deduction.reason_cells)
		_log.end(key)
	_bifurcation_engine.clear()


func _add_bifurcation_deductions(mode: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE) -> void:
	# found a contradiction; we can make a deduction
	var scenario_keys: Array[String] = _bifurcation_engine.get_scenario_keys()
	for key: String in scenario_keys:
		_log.start(key)
		if not _bifurcation_engine.scenario_has_new_contradictions(key, mode):
			_log.end(key)
			continue
		for deduction: Deduction in _bifurcation_engine.get_scenario_deductions(key):
			if not _should_deduce(board, deduction.pos):
				continue
			add_deduction(deduction.pos, deduction.value, deduction.reason, deduction.reason_cells)
		_log.end(key)
	_bifurcation_engine.clear()


func _add_bifurcation_scenario(key: String, cells: Array[Vector2i],
		assumptions: Dictionary[Vector2i, int],
		bifurcation_deductions: Array[Deduction]) -> void:
	if not metrics.has("bifurcation_scenarios"):
		metrics["bifurcation_scenarios"] = 0
	metrics["bifurcation_scenarios"] += 1
	_bifurcation_engine.add_scenario(board, key, cells, assumptions, bifurcation_deductions)


func _should_deduce(target_board: SolverBoard, cell: Vector2i) -> bool:
	return target_board.get_cell(cell) == CELL_EMPTY and (cell not in deductions.cells or perform_redundant_deductions)


func _find_adjacent_clues(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor: Vector2i in board.get_neighbors(cell):
		if NurikabeUtils.is_clue(board.get_cell(neighbor)):
			result.append(neighbor)
	return result


func _find_clued_neighbor_roots(cell: Vector2i) -> Array[Vector2i]:
	var clued_neighbor_roots: Dictionary[Vector2i, bool] = {}
	for neighbor: Vector2i in board.get_neighbors(cell):
		if board.get_clue_for_island_cell(neighbor) == 0:
			continue
		var neighbor_root: Vector2i = board.get_island_root_for_cell(neighbor)
		clued_neighbor_roots[neighbor_root] = true
	return clued_neighbor_roots.keys()


func _react_to_changes(changes: Array[Dictionary]) -> void:
	var affected_wall_roots: Dictionary[Vector2i, bool] = {}
	var affected_island_roots: Dictionary[Vector2i, bool] = {}
	var cells_to_check: Dictionary[Vector2i, bool] = {}
	for change: Dictionary[String, Variant] in changes:
		var cell: Vector2i = change["pos"]
		cells_to_check[cell] = true
		for neighbor: Vector2i in board.get_neighbors(cell):
			cells_to_check[neighbor] = true
	for cell_to_check: Vector2i in cells_to_check:
		var wall_root: Vector2i = board.get_wall_root_for_cell(cell_to_check)
		if wall_root != POS_NOT_FOUND:
			affected_wall_roots[wall_root] = true
		var island_root: Vector2i = board.get_island_root_for_cell(cell_to_check)
		if island_root != POS_NOT_FOUND:
			affected_island_roots[island_root] = true
	
	for wall_root: Vector2i in affected_wall_roots:
		var wall: Array[Vector2i] = board.get_wall_for_cell(wall_root)
		if board.get_liberties(wall).is_empty():
			continue
		schedule_task(deduce_wall.bind(wall_root), 345)
	
	for island_root: Vector2i in affected_island_roots:
		var island: Array[Vector2i] = board.get_island_for_cell(island_root)
		if board.get_liberties(island).is_empty():
			continue
		var clue_value: int = board.get_clue_for_island_cell(island_root)
		if clue_value >= 1:
			schedule_task(deduce_clued_island.bind(island_root), 350)
		elif clue_value == 0:
			schedule_task(deduce_unclued_island.bind(island_root), 350)


func _task_key(callable: Callable) -> String:
	var key: String = callable.get_method()
	var args: Array[Variant] = callable.get_bound_arguments()
	if not args.is_empty():
		key += ":" + JSON.stringify(args)
	return key
