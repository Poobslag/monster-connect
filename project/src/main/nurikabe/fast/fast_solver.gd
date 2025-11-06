class_name FastSolver

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var deductions: DeductionBatch = DeductionBatch.new()
var board: FastBoard

var _change_history: Array[Dictionary] = []
var _task_history: Dictionary[String, Dictionary] = {
}
var _task_queue: Array[Dictionary] = [
]

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
	_change_history.clear()
	_task_history.clear()
	_task_queue.clear()


func is_queue_empty() -> bool:
	return _task_queue.is_empty()


func get_changes() -> Array[Dictionary]:
	return deductions.get_changes()


func schedule_tasks() -> void:
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
	_task_history[next_task["key"]] = {
		"last_run": board.get_filled_cell_count()
	} as Dictionary[String, Variant]
	next_task["callable"].call()


func deduce_adjacent_clues(clue_cell: Vector2i) -> void:
	if not board.get_cell_string(clue_cell).is_valid_int():
		return
	
	for neighbor_cell: Vector2i in board.get_neighbors(clue_cell):
		if not _can_deduce(board, neighbor_cell):
			continue
		var adjacent_clues: Array[Vector2i] = _find_adjacent_clues(neighbor_cell)
		if adjacent_clues.size() >= 2:
			deductions.add_deduction(neighbor_cell, CELL_WALL,
				"adjacent_clues %s %s" % [adjacent_clues[0], adjacent_clues[1]])


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
			deductions.add_deduction(chokepoint, CELL_ISLAND,
				"island_expansion %s" % [clue_cell])
		else:
			deductions.add_deduction(chokepoint, CELL_ISLAND,
				"island_chokepoint %s" % [clue_cell])


func deduce_clue_chokepoint(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	
	var snug_cells: Dictionary[Vector2i, String] = \
			board.get_per_clue_chokepoint_map().find_snug_cells(island_cell)
	for snug_cell in snug_cells:
		if not _can_deduce(board, snug_cell):
			continue
		if snug_cells[snug_cell] == CELL_ISLAND:
			deductions.add_deduction(snug_cell, CELL_ISLAND, "island_snug %s" % [island_cell])
		else:
			deductions.add_deduction(snug_cell, CELL_WALL, "island_buffer %s" % [island_cell])
	
	if snug_cells.is_empty():
		var chokepoint_cells: Dictionary[Vector2i, String] = \
				board.get_per_clue_chokepoint_map().find_chokepoint_cells(island_cell)
		for chokepoint: Vector2i in chokepoint_cells:
			if not _can_deduce(board, chokepoint):
				continue
			if chokepoint_cells[chokepoint] == CELL_ISLAND:
				if chokepoint in board.get_liberties(island):
					deductions.add_deduction(chokepoint, CELL_ISLAND, "island_expansion %s" % [island_cell])
				else:
					deductions.add_deduction(chokepoint, CELL_ISLAND, "island_chokepoint %s" % [island_cell])
			else:
				deductions.add_deduction(chokepoint, CELL_WALL, "island_buffer %s" % [island_cell])


func deduce_island_of_one(clue_cell: Vector2i) -> void:
	if not board.get_cell_string(clue_cell) == "1":
		return
	for neighbor_cell in board.get_neighbors(clue_cell):
		if not _can_deduce(board, neighbor_cell):
			continue
		deductions.add_deduction(neighbor_cell, CELL_WALL,
			"island_of_one %s" % [clue_cell])


func deduce_clued_island(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var clue_value: int = board.get_clue_for_group(island)
	if clue_value < 1:
		# unclued/invalid group
		return
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if liberties.size() == 0:
		# sealed group
		return
	
	if clue_value == island.size():
		for liberty: Vector2i in liberties:
			if not _can_deduce(board, liberty):
				continue
			deductions.add_deduction(liberty, CELL_WALL, "island_moat %s" % [island[0]])
	elif liberties.size() == 1 and clue_value == island.size() + 1:
		if _can_deduce(board, liberties[0]):
			deductions.add_deduction(liberties[0], CELL_ISLAND, "island_expansion %s" % [island[0]])
		for new_wall_cell: Vector2i in board.get_neighbors(liberties[0]):
			if _can_deduce(board, new_wall_cell):
				deductions.add_deduction(new_wall_cell, CELL_WALL, "island_moat %s" % [island[0]])
	elif liberties.size() == 1 and clue_value > island.size():
		if _can_deduce(board, liberties[0]):
			deductions.add_deduction(liberties[0], CELL_ISLAND, "island_expansion %s" % [island[0]])
	else:
		var component_cell_count: int = board.get_island_chokepoint_map().get_component_cell_count(island_cell)
		if component_cell_count == clue_value:
			for deduction_cell: Vector2i in board.get_island_chokepoint_map().get_component_cells(island_cell):
				if _can_deduce(board, deduction_cell):
					deductions.add_deduction(deduction_cell, CELL_ISLAND, "island_snug %s" % [island_cell])


func deduce_unclued_island(island_cell: Vector2i) -> void:
	var island: Array[Vector2i] = board.get_island_for_cell(island_cell)
	var clue_value: int = board.get_clue_for_group(island)
	if clue_value != 0:
		# clued/invalid group
		return
	var liberties: Array[Vector2i] = board.get_liberties(island)
	if liberties.size() == 1:
		deductions.add_deduction(liberties[0], CELL_ISLAND, "island_connector %s" % [island[0]])


func deduce_island_divider(island_cell: Vector2i) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(board.get_island_for_cell(island_cell))
	for liberty: Vector2i in liberties:
		if not _can_deduce(board, liberty):
			continue
		var clued_neighbor_roots: Array[Vector2i] = _find_clued_neighbor_roots(liberty)
		if clued_neighbor_roots.size() >= 2:
			deductions.add_deduction(liberty, CELL_WALL, "island_divider %s %s"
					% [clued_neighbor_roots[0], clued_neighbor_roots[1]])


func deduce_unreachable_square(cell: Vector2i) -> void:
	if not _can_deduce(board, cell):
		return
	
	match board.get_global_reachability_map().get_clue_reachability(cell):
		GlobalReachabilityMap.ClueReachability.UNREACHABLE:
			deductions.add_deduction(cell, CELL_WALL, "unreachable_square %s"
					% [board.get_global_reachability_map().get_nearest_clue_cell(cell)])
		
		GlobalReachabilityMap.ClueReachability.IMPOSSIBLE:
			deductions.add_deduction(cell, CELL_WALL, "wall_bubble")
		
		GlobalReachabilityMap.ClueReachability.CONFLICT:
			var clued_neighbor_roots: Array[Vector2i] = _find_clued_neighbor_roots(cell)
			deductions.add_deduction(cell, CELL_WALL, "island_divider %s %s"
					% [clued_neighbor_roots[0], clued_neighbor_roots[1]])


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
		deductions.add_deduction(chokepoint, CELL_WALL, "wall_connector %s" % [split_neighbor])


func deduce_wall_expansion(wall_cell: Vector2i) -> void:
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	if board.get_walls().size() <= 1:
		return
	
	if liberties.size() == 1:
		deductions.add_deduction(liberties[0], CELL_WALL, "wall_expansion %s" % [wall_cell])


func deduce_pool(wall_cell: Vector2i) -> void:
	var wall: Array[Vector2i] = board.get_wall_for_cell(wall_cell)
	var liberties: Array[Vector2i] = board.get_liberties(wall)
	if liberties.size() == 0:
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
		if wall_mask in [5, 6, 9, 10]:
			# Calculate the three pool cells: The two wall cells adjacent to the liberty, and the diagonal cell.
			var pool: Array[Vector2i] = []
			for neighbor_cell in board.get_neighbors(liberty):
				if neighbor_cell in wall_cell_set:
					pool.append(neighbor_cell)
			pool.append(Vector2i(pool[1].x, pool[0].y) if pool[0].x == liberty.x else Vector2i(pool[0].x, pool[1].y))
			pool.sort()
			
			deductions.add_deduction(liberty, CELL_ISLAND, "pool_triplet %s %s %s" % [pool[0], pool[1], pool[2]])


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
		schedule_task(deduce_island_chokepoint.bind(chokepoint), 230)
	
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		schedule_task(deduce_clue_chokepoint.bind(island.front()), 225)


func enqueue_wall_chokepoints() -> void:
	var chokepoints: Array[Vector2i] = board.get_wall_chokepoint_map().chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		schedule_task(deduce_wall_chokepoint.bind(chokepoint), 235)


func enqueue_islands() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var liberties: Array[Vector2i] = board.get_liberties(island)
		if liberties.size() == 0:
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


func enqueue_island_dividers() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var clue_value: int = board.get_clue_for_group(island)
		if clue_value < 1:
			# unclued/invalid island
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		if liberties.size() > 0:
			schedule_task(deduce_island_divider.bind(island.front()), 240)


func enqueue_islands_of_one() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) == "1":
			schedule_task(deduce_island_of_one.bind(cell), 1100)


func enqueue_walls() -> void:
	var walls: Array[Array] = board.get_walls()
	for wall: Array[Vector2i] in walls:
		var liberties: Array[Vector2i] = board.get_liberties(wall)
		if liberties.size() > 0:
			schedule_task(deduce_wall.bind(wall.front()), 245)


func enqueue_unreachable_squares() -> void:
	for cell: Vector2i in board.cells:
		if not _can_deduce(board, cell):
			continue
		if board.get_global_reachability_map().get_clue_reachability(cell) \
				== GlobalReachabilityMap.ClueReachability.REACHABLE:
			continue
		schedule_task(deduce_unreachable_square.bind(cell), 235)


func _can_deduce(target_board: FastBoard, cell: Vector2i) -> bool:
	return target_board.get_cell_string(cell) == CELL_EMPTY and not cell in deductions.cells


func _find_adjacent_clues(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor_cell: Vector2i in board.get_neighbors(cell):
		if board.get_cell_string(neighbor_cell).is_valid_int():
			result.append(neighbor_cell)
	return result


func _find_clued_neighbor_roots(cell: Vector2i) -> Array[Vector2i]:
	var clued_neighbor_roots: Dictionary[Vector2i, bool] = {}
	for neighbor_cell: Vector2i in board.get_neighbors(cell):
		if board.get_clue_value_for_cell(neighbor_cell) == 0:
			continue
		var neighbor_root: Vector2i = board.get_island_root_for_cell(neighbor_cell)
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
		if board.get_liberties(wall).size() > 0:
			schedule_task(deduce_wall.bind(wall_root), 345)
	
	for island_root: Vector2i in affected_island_roots:
		var island: Array[Vector2i] = board.get_island_for_cell(island_root)
		if board.get_liberties(island).size() == 0:
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
