class_name FastSolver

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

const UNKNOWN_REASON: FastDeduction.Reason = FastDeduction.Reason.UNKNOWN

## starting techniques
const ISLAND_OF_ONE: FastDeduction.Reason = FastDeduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: FastDeduction.Reason = FastDeduction.Reason.ADJACENT_CLUES

## basic techniques
const CORNER_ISLAND: FastDeduction.Reason = FastDeduction.Reason.CORNER_ISLAND
const ISLAND_BUFFER: FastDeduction.Reason = FastDeduction.Reason.ISLAND_BUFFER
const ISLAND_CHOKEPOINT: FastDeduction.Reason = FastDeduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: FastDeduction.Reason = FastDeduction.Reason.ISLAND_CONNECTOR
const ISLAND_DIVIDER: FastDeduction.Reason = FastDeduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: FastDeduction.Reason = FastDeduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: FastDeduction.Reason = FastDeduction.Reason.ISLAND_MOAT
const ISLAND_SNUG: FastDeduction.Reason = FastDeduction.Reason.ISLAND_SNUG
const LONG_ISLAND: FastDeduction.Reason = FastDeduction.Reason.LONG_ISLAND
const POOL_CHOKEPOINT: FastDeduction.Reason = FastDeduction.Reason.POOL_CHOKEPOINT
const POOL_TRIPLET: FastDeduction.Reason = FastDeduction.Reason.POOL_TRIPLET
const UNREACHABLE_CELL: FastDeduction.Reason = FastDeduction.Reason.UNREACHABLE_CELL
const WALL_BUBBLE: FastDeduction.Reason = FastDeduction.Reason.WALL_BUBBLE
const WALL_CONNECTOR: FastDeduction.Reason = FastDeduction.Reason.WALL_CONNECTOR
const WALL_EXPANSION: FastDeduction.Reason = FastDeduction.Reason.WALL_EXPANSION
const WALL_WEAVER: FastDeduction.Reason = FastDeduction.Reason.WALL_WEAVER

## advanced techniques
const ASSUMPTION: FastDeduction.Reason = FastDeduction.Reason.ASSUMPTION
const ISLAND_BATTLEGROUND: FastDeduction.Reason = FastDeduction.Reason.ISLAND_BATTLEGROUND
const ISLAND_STRANGLE: FastDeduction.Reason = FastDeduction.Reason.ISLAND_STRANGLE
const WALL_STRANGLE: FastDeduction.Reason = FastDeduction.Reason.WALL_STRANGLE

var verbose: bool = false

var deductions: DeductionBatch = DeductionBatch.new()
var board: FastBoard
var metrics: Dictionary[String, Variant] = {}

var _change_history: Array[Dictionary] = []
var _task_history: Dictionary[String, Dictionary] = {
}
var _task_queue: Array[Dictionary] = [
]
var _bifurcation_engine: BifurcationEngine = BifurcationEngine.new()

func add_deduction(pos: Vector2i, value: String,
		reason: FastDeduction.Reason = UNKNOWN_REASON,
		reason_cells: Array[Vector2i] = []) -> void:
	deductions.add_deduction(pos, value, reason, reason_cells)


func apply_changes() -> void:
	var changes: Array[Dictionary] = deductions.get_changes()
	for change: Dictionary[String, Variant] in changes:
		var history_item: Dictionary[String, Variant] = {}
		history_item["pos"] = change["pos"]
		history_item["value"] = change["value"]
		history_item["tick"] = board.get_filled_cell_count()
		_change_history.append(history_item)
	
	_change_history.append_array(changes)
	board.set_cell_strings(changes)
	deductions.clear()
	
	_react_to_changes(changes)


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
		
		if has_scheduled_task(enqueue_island_battleground):
			pass
		elif get_last_run(enqueue_island_battleground) < board.get_filled_cell_count():
			schedule_task(enqueue_island_battleground, 20)
		
		if has_scheduled_task(enqueue_wall_strangle):
			pass
		elif get_last_run(enqueue_wall_strangle) < board.get_filled_cell_count():
			schedule_task(enqueue_wall_strangle, 20)
		
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
	if not board.get_cell_string(clue_cell).is_valid_int():
		return
	
	for neighbor: Vector2i in board.get_neighbors(clue_cell):
		if not _can_deduce(board, neighbor):
			continue
		var adjacent_clues: Array[Vector2i] = _find_adjacent_clues(neighbor)
		if adjacent_clues.size() >= 2:
			add_deduction(neighbor, CELL_WALL,
				ADJACENT_CLUES, [adjacent_clues[0], adjacent_clues[1]] as Array[Vector2i])


func deduce_island_chokepoint(chokepoint: Vector2i) -> void:
	if not _can_deduce(board, chokepoint):
		return
	var clue_cell: Vector2i = board.get_global_reachability_map().get_nearest_clue_cell(chokepoint)
	if clue_cell == POS_NOT_FOUND:
		return
	var clue_value: int = int(board.cells[clue_cell])
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
	
	# Check for two empty cells leading into a dead end, which create a pool.
	if _can_deduce(board, chokepoint):
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if _is_pool_chokepoint(chokepoint, dir):
				add_deduction(chokepoint, CELL_ISLAND, POOL_CHOKEPOINT, [chokepoint + dir])


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
func _is_pool_chokepoint(chokepoint: Vector2i, dir: Vector2i) -> bool:
	if board.get_cell_string(chokepoint) != CELL_EMPTY:
		return false
	if board.get_cell_string(chokepoint + dir) != CELL_EMPTY:
		return false
	
	var solid: Array[bool] = []
	var wall: Array[bool] = []
	for offset: Vector2i in [
			Vector2i(-dir.y, dir.x), Vector2i(dir.y, -dir.x),
			dir + Vector2i(-dir.y, dir.x), dir + Vector2i(dir.y, -dir.x), dir + dir]:
		solid.append(board.get_cell_string(chokepoint + offset) in [CELL_WALL, CELL_INVALID])
		wall.append(board.get_cell_string(chokepoint + offset) == CELL_WALL)
	
	return (solid[2] and solid[3] and solid[4]) \
			and (wall[0] and wall[2] or wall[1] and wall[3])


func deduce_clue_chokepoint(island_cell: Vector2i) -> void:
	var old_deductions_size: int = deductions.size()
	
	if deductions.size() == old_deductions_size:
		deduce_clue_chokepoint_snug(island_cell)
	
	if deductions.size() == old_deductions_size:
		deduce_clue_chokepoint_loose(island_cell)
	
	if deductions.size() == old_deductions_size:
		deduce_clue_chokepoint_wall_weaver(island_cell)


func deduce_clue_chokepoint_snug(island_cell: Vector2i) -> void:
	var island_root: Vector2i = board.get_island_root_for_cell(island_cell)
	var clue_value: int = board.get_clue_value_for_cell(island_cell)
	if board.get_per_clue_chokepoint_map().get_component_cell_count(island_cell) != clue_value:
		return
	
	var component_cells: Array[Vector2i] = board.get_per_clue_chokepoint_map().get_component_cells(island_cell)
	for component_cell: Vector2i in component_cells:
		if board.get_cell_string(component_cell) == CELL_EMPTY:
			add_deduction(component_cell, CELL_ISLAND, ISLAND_SNUG, [island_cell])
		for neighbor: Vector2i in board.get_neighbors(component_cell):
			if board.get_per_clue_chokepoint_map().needs_buffer(island_root, neighbor):
				add_deduction(neighbor, CELL_WALL, ISLAND_BUFFER, [island_cell])


func deduce_clue_chokepoint_loose(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var chokepoint_cells: Dictionary[Vector2i, String] = \
			board.get_per_clue_chokepoint_map().find_chokepoint_cells(island_cell)
	for chokepoint: Vector2i in chokepoint_cells:
		if not _can_deduce(board, chokepoint):
			continue
		if chokepoint_cells[chokepoint] == CELL_ISLAND:
			if chokepoint in board.get_liberties(island):
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_EXPANSION, [island_cell])
			else:
				add_deduction(chokepoint, CELL_ISLAND, ISLAND_CHOKEPOINT, [island_cell])
		else:
			add_deduction(chokepoint, CELL_WALL, ISLAND_BUFFER, [island_cell])


func deduce_clue_chokepoint_wall_weaver(island_cell: Vector2i) -> void:
	var clue_value: int = board.get_clue_value_for_cell(island_cell)
	var wall_exclusion_map: GroupMap = board.get_per_clue_chokepoint_map().get_wall_exclusion_map(island_cell)
	var component_cell_count: int = board.get_per_clue_chokepoint_map().get_component_cell_count(island_cell)
	if wall_exclusion_map.groups.size() != 1 + component_cell_count - clue_value:
		return
	
	var connectors_by_wall: Dictionary[Vector2i, Array]
	for cell: Vector2i in board.get_per_clue_chokepoint_map().get_component_cells(island_cell):
		if not board.get_cell_string(cell) == CELL_EMPTY:
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
		if not _can_deduce(board, connector):
			continue
		deductions.add_deduction(connector, CELL_WALL, WALL_WEAVER, [island_cell])


func deduce_long_island() -> void:
	var reachable_clues_by_cell: Dictionary[Vector2i, Dictionary] \
			= board.get_per_clue_chokepoint_map().get_reachable_clues_by_cell()
	for cell: Vector2i in reachable_clues_by_cell:
		if reachable_clues_by_cell[cell].size() > 1:
			continue
		if board.get_cell_string(cell) != CELL_ISLAND:
			continue
		var clued_island_cell: Vector2i = reachable_clues_by_cell[cell].keys().front()
		var clued_island: Array[Vector2i] = board.get_island_for_cell(clued_island_cell)
		var clue_value: int = board.get_clue_for_group(clued_island)
		
		var closest_clued_island_cell_dist: int = 999999
		var closest_clued_island_cell: Vector2i
		for next_clued_island_cell: Vector2i in clued_island:
			var next_clued_island_cell_dist: int = abs(cell.x - next_clued_island_cell.x) \
					+ abs(cell.y - next_clued_island_cell.y)
			if next_clued_island_cell_dist < closest_clued_island_cell_dist:
				closest_clued_island_cell = next_clued_island_cell
				closest_clued_island_cell_dist = next_clued_island_cell_dist
		
		if (closest_clued_island_cell.x != cell.x and closest_clued_island_cell.y != cell.y):
			# closest cell is not in a straight vertical/horizontal line
			continue
		
		if closest_clued_island_cell_dist < (clue_value - clued_island.size() - 1):
			# closest cell is too close; clue has some "wiggle room"
			continue
		
		var cell_step: Vector2i = Vector2i(\
				sign(cell.x - closest_clued_island_cell.x),
				sign(cell.y - closest_clued_island_cell.y))
		for i in closest_clued_island_cell_dist:
			var deduction_cell: Vector2i = closest_clued_island_cell + i * cell_step
			if not _can_deduce(board, deduction_cell):
				continue
			add_deduction(deduction_cell, CELL_ISLAND, LONG_ISLAND, [clued_island_cell])


func deduce_island_of_one(clue_cell: Vector2i) -> void:
	if not board.get_cell_string(clue_cell) == "1":
		return
	for neighbor: Vector2i in board.get_neighbors(clue_cell):
		if not _can_deduce(board, neighbor):
			continue
		add_deduction(neighbor, CELL_WALL,
			ISLAND_OF_ONE, [clue_cell])


func deduce_clued_island(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var clue_value: int = board.get_clue_for_group(island)
	if clue_value < 1:
		# unclued/invalid group
		return
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if liberties.is_empty():
		# sealed group
		return
	
	if clue_value == island.size():
		for liberty: Vector2i in liberties:
			if not _can_deduce(board, liberty):
				continue
			add_deduction(liberty, CELL_WALL, ISLAND_MOAT, [island[0]])
	elif liberties.size() == 1 and clue_value == island.size() + 1:
		if _can_deduce(board, liberties[0]):
			add_deduction(liberties[0], CELL_ISLAND, ISLAND_EXPANSION, [island[0]])
		for new_wall_cell: Vector2i in board.get_neighbors(liberties[0]):
			if _can_deduce(board, new_wall_cell):
				add_deduction(new_wall_cell, CELL_WALL, ISLAND_MOAT, [island[0]])
	elif liberties.size() == 1 and clue_value > island.size():
		if _can_deduce(board, liberties[0]):
			add_deduction(liberties[0], CELL_ISLAND, ISLAND_EXPANSION, [island[0]])
	else:
		var component_cell_count: int = board.get_island_chokepoint_map().get_component_cell_count(island_cell)
		if component_cell_count == clue_value:
			for deduction_cell: Vector2i in board.get_island_chokepoint_map().get_component_cells(island_cell):
				if _can_deduce(board, deduction_cell):
					add_deduction(deduction_cell, CELL_ISLAND, ISLAND_SNUG, [island_cell])
		
		if liberties.size() == 2 and clue_value == island.size() + 1:
			# If there are two liberties, and the liberties are diagonal, any blank squares connecting those liberties
			# must be walls.
			var liberty_connectors: Array[Vector2i] = []
			liberty_connectors.assign(Utils.intersection( \
					board.get_neighbors(liberties[0]), board.get_neighbors(liberties[1])))
			for liberty_connector: Vector2i in liberty_connectors:
				if not _can_deduce(board, liberty_connector):
					continue
				add_deduction(liberty_connector, CELL_WALL, CORNER_ISLAND, [island_cell])


func deduce_unclued_island(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var clue_value: int = board.get_clue_for_group(island)
	if clue_value != 0:
		# clued/invalid group
		return
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if liberties.size() == 1:
		add_deduction(liberties[0], CELL_ISLAND, ISLAND_CONNECTOR, [island[0]])


func deduce_island_divider(island_cell: Vector2i) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(board.get_island_for_cell(island_cell))
	for liberty: Vector2i in liberties:
		if not _can_deduce(board, liberty):
			continue
		var clued_neighbor_roots: Array[Vector2i] = _find_clued_neighbor_roots(liberty)
		if clued_neighbor_roots.size() >= 2:
			add_deduction(liberty, CELL_WALL, ISLAND_DIVIDER,
					[clued_neighbor_roots[0], clued_neighbor_roots[1]])


func deduce_unreachable_square(cell: Vector2i) -> void:
	if not _can_deduce(board, cell):
		return
	
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


func deduce_wall(wall_cell: Vector2i) -> void:
	deduce_wall_expansion(wall_cell)
	deduce_pool(wall_cell)


func deduce_wall_chokepoint(chokepoint: Vector2i) -> void:
	if not _can_deduce(board, chokepoint):
		return
	
	var max_choked_special_count: int = 0
	var split_neighbor: Vector2i = POS_NOT_FOUND
	for neighbor: Vector2i in board.get_neighbors(chokepoint):
		if board.get_cell_string(neighbor) != CELL_WALL:
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
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	if board.get_walls().size() <= 1:
		return
	
	if liberties.size() == 1:
		add_deduction(liberties[0], CELL_WALL, WALL_EXPANSION, [wall_cell])


func deduce_pool(wall_cell: Vector2i) -> void:
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	if liberties.is_empty():
		return
	if wall.size() < 3:
		return
	
	var wall_cell_set: Dictionary[Vector2i, bool] = {}
	for next_wall_cell in wall:
		wall_cell_set[next_wall_cell] = true
	for liberty: Vector2i in liberties:
		if not _can_deduce(board, liberty):
			continue
		var wall_mask: int = neighbor_mask(liberty, func(cell: Vector2i) -> bool:
			return wall_cell_set.has(cell))
		if wall_mask in [5, 6, 7, 9, 10, 11, 13, 14]:
			# Calculate the three pool cells: The two wall cells adjacent to the liberty, and the diagonal cell.
			var pool: Array[Vector2i] = []
			for neighbor: Vector2i in board.get_neighbors(liberty):
				if neighbor in wall_cell_set:
					pool.append(neighbor)
			pool.append(Vector2i(pool[1].x, pool[0].y) if pool[0].x == liberty.x else Vector2i(pool[0].x, pool[1].y))
			pool.sort()
			
			add_deduction(liberty, CELL_ISLAND, POOL_TRIPLET, [pool[0], pool[1], pool[2]])


func neighbor_mask(cell: Vector2i, callable: Callable) -> int:
	var result: int = 0
	result |= 1 if callable.call(cell + Vector2i.UP) else 0
	result |= 2 if callable.call(cell + Vector2i.DOWN) else 0
	result |= 4 if callable.call(cell + Vector2i.LEFT) else 0
	result |= 8 if callable.call(cell + Vector2i.RIGHT) else 0
	return result


func enqueue_adjacent_clues() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell).is_valid_int():
			schedule_task(deduce_adjacent_clues.bind(cell), 1100)


func enqueue_island_chokepoints() -> void:
	var chokepoints: Array[Vector2i] = board.get_island_chokepoint_map().chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		if not _can_deduce(board, chokepoint):
			continue
		schedule_task(deduce_island_chokepoint.bind(chokepoint), 230)
	
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		if board.get_liberties(island).is_empty():
			continue
		schedule_task(deduce_clue_chokepoint.bind(island.front()), 225)
	
	schedule_task(deduce_long_island, 224)


func enqueue_wall_chokepoints() -> void:
	var chokepoints: Array[Vector2i] = board.get_wall_chokepoint_map().chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		if not _can_deduce(board, chokepoint):
			continue
		schedule_task(deduce_wall_chokepoint.bind(chokepoint), 235)


func enqueue_islands() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		if board.get_liberties(island).is_empty():
			continue
		var clue_value: int = board.get_clue_for_group(island)
		if clue_value == -1:
			# invalid island
			continue
		elif clue_value == 0:
			# unclued island
			schedule_task(deduce_unclued_island.bind(island.front()), 250)
		else:
			# clued island
			schedule_task(deduce_clued_island.bind(island.front()), 250)


func enqueue_island_battleground() -> void:
	var clued_island_neighbors_by_empty_cell: Dictionary[Vector2i, Array] = {}
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		if board.get_clue_for_group(island) < 1:
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
			var clued_island: Vector2i = clued_island_neighbors_by_empty_cell[cell][0]
			var neighbor_clued_island: Vector2i = clued_island_neighbors_by_empty_cell[neighbor][0]
			_add_bifurcation_scenario(
				{cell: CELL_ISLAND, neighbor: CELL_WALL},
				[FastDeduction.new(cell, CELL_WALL,
						ISLAND_BATTLEGROUND, [clued_island, neighbor_clued_island])])
	
	if not has_scheduled_task(run_bifurcation_step):
		schedule_task(run_bifurcation_step, 10)


func enqueue_island_strangle() -> void:
	for island: Array[Vector2i] in board.get_islands():
		var clue_value: int = board.get_clue_for_group(island)
		if island.size() != clue_value - 1:
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		for liberty: Vector2i in liberties:
			if not _can_deduce(board, liberty):
				continue
			
			var assumptions: Dictionary[Vector2i, String] = {}
			assumptions[liberty] = CELL_ISLAND
			for new_wall_cell: Vector2i in board.get_neighbors(liberty):
				if not _can_deduce(board, new_wall_cell):
					continue
				assumptions[new_wall_cell] = CELL_WALL
			for other_liberty: Vector2i in liberties:
				if other_liberty == liberty:
					continue
				if not _can_deduce(board, other_liberty):
					continue
				assumptions[other_liberty] = CELL_WALL
			
			_add_bifurcation_scenario(
				assumptions,
				[FastDeduction.new(liberty, CELL_WALL, ISLAND_STRANGLE, [island.front()])]
			)
	
	if not has_scheduled_task(run_bifurcation_step):
		schedule_task(run_bifurcation_step, 10)


func enqueue_wall_strangle() -> void:
	var walls: Array[Array] = board.get_walls()
	if walls.size() < 2:
		# The wall strangle deduction requires two walls.
		return
	
	for wall: Array[Vector2i] in walls:
		var liberties: Array[Vector2i] = board.get_liberties(wall)
		if liberties.size() == 2:
			_add_bifurcation_scenario(
				{liberties[0]: CELL_ISLAND, liberties[1]: CELL_WALL},
				[FastDeduction.new(liberties[0], CELL_WALL, WALL_STRANGLE, [wall.front()])]
			)
			_add_bifurcation_scenario(
				{liberties[1]: CELL_ISLAND, liberties[0]: CELL_WALL},
				[FastDeduction.new(liberties[1], CELL_WALL, WALL_STRANGLE, [wall.front()])]
			)
	
	if not has_scheduled_task(run_bifurcation_step):
		schedule_task(run_bifurcation_step, 10)


func enqueue_island_dividers() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var clue_value: int = board.get_clue_for_group(island)
		if clue_value < 1:
			# unclued/invalid island
			continue
		if board.get_liberties(island).is_empty():
			continue
		schedule_task(deduce_island_divider.bind(island.front()), 240)


func enqueue_islands_of_one() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != "1":
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
		if not _can_deduce(board, cell):
			continue
		if board.get_global_reachability_map().get_clue_reachability(cell) \
				== GlobalReachabilityMap.ClueReachability.REACHABLE:
			continue
		schedule_task(deduce_unreachable_square.bind(cell), 235)


func run_bifurcation_step() -> void:
	if verbose:
		print("> bifurcating: %s scenarios" % [_bifurcation_engine.get_scenario_count()])
	_bifurcation_engine.step()
	if _bifurcation_engine.has_contradictions():
		for deduction: FastDeduction in _bifurcation_engine.get_confirmed_deductions():
			if not _can_deduce(board, deduction.pos):
				continue
			add_deduction(deduction.pos, deduction.value, deduction.reason, deduction.reason_cells)
		_bifurcation_engine.clear()
	elif not _bifurcation_engine.is_queue_empty():
		schedule_task(run_bifurcation_step, 10)
	
	if _bifurcation_engine.is_queue_empty() and metrics.has("bifurcation_start_time"):
		var bifurcation_duration: int = (Time.get_ticks_usec() - metrics["bifurcation_start_time"])
		metrics.erase("bifurcation_start_time")
		
		if not metrics.has("bifurcation_duration"):
			metrics["bifurcation_duration"] = 0.0
		metrics["bifurcation_duration"] += bifurcation_duration / 1000.0


func _add_bifurcation_scenario(assumptions: Dictionary[Vector2i, String],
		bifurcation_deductions: Array[FastDeduction]) -> void:
	if not metrics.has("bifurcation_scenarios"):
		metrics["bifurcation_scenarios"] = 0
	metrics["bifurcation_scenarios"] += 1
	_bifurcation_engine.add_scenario(board, assumptions, bifurcation_deductions)


func _can_deduce(target_board: FastBoard, cell: Vector2i) -> bool:
	return target_board.get_cell_string(cell) == CELL_EMPTY and not cell in deductions.cells


func _find_adjacent_clues(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor: Vector2i in board.get_neighbors(cell):
		if board.get_cell_string(neighbor).is_valid_int():
			result.append(neighbor)
	return result


func _find_clued_neighbor_roots(cell: Vector2i) -> Array[Vector2i]:
	var clued_neighbor_roots: Dictionary[Vector2i, bool] = {}
	for neighbor: Vector2i in board.get_neighbors(cell):
		if board.get_clue_value_for_cell(neighbor) == 0:
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
		if board.get_clue_for_group(island) >= 1:
			schedule_task(deduce_clued_island.bind(island_root), 350)
		if board.get_clue_for_group(island) == 0:
			schedule_task(deduce_unclued_island.bind(island_root), 350)


func _task_key(callable: Callable) -> String:
	var key: String = callable.get_method()
	var args: Array[Variant] = callable.get_bound_arguments()
	if not args.is_empty():
		key += ":" + JSON.stringify(args)
	return key
