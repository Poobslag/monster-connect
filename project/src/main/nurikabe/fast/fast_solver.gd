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
	
	if get_last_run(enqueue_clued_islands) == -1:
		schedule_task(enqueue_clued_islands, 150)
	
	if get_last_run(enqueue_wall_expansions) == -1:
		schedule_task(enqueue_wall_expansions, 145)
	
	if get_last_run(enqueue_island_dividers) == -1:
		schedule_task(enqueue_island_dividers, 140)


func get_last_run(callable: Callable) -> int:
	var task_key: String = _task_key(callable)
	var history_item: Dictionary[String, Variant] = _task_history.get(task_key, {} as Dictionary[String, Variant])
	return -1 if history_item.is_empty() else history_item["last_run"]


func has_scheduled_task(callable: Callable) -> bool:
	return not get_scheduled_task(callable).is_empty()


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
	if _task_queue.is_empty():
		schedule_tasks()
	
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
	if clue_value == 0:
		# unclued group
		return
	var liberties: Array[Vector2i] = board.get_liberties(island)
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


func deduce_island_divider(island_cell: Vector2i) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(board.get_island_for_cell(island_cell))
	for liberty: Vector2i in liberties:
		if not _can_deduce(board, liberty):
			continue
		var clued_neighbor_roots: Dictionary[Vector2i, bool] = {}
		for neighbor_cell: Vector2i in board.get_neighbors(liberty):
			if board.get_clue_value_for_cell(neighbor_cell) == 0:
				continue
			var neighbor_root: Vector2i = board.get_island_root_for_cell(neighbor_cell)
			clued_neighbor_roots[neighbor_root] = true
		if clued_neighbor_roots.size() >= 2:
			deductions.add_deduction(liberty, CELL_WALL, "island_divider %s %s"
					% [clued_neighbor_roots.keys()[0], clued_neighbor_roots.keys()[1]])


func deduce_wall(wall_cell: Vector2i) -> void:
	var liberties: Array[Vector2i] = board.get_liberties(board.get_wall_for_cell(wall_cell))
	if liberties.size() == 1 and board.get_walls().size() >= 2:
		deductions.add_deduction(liberties[0], CELL_WALL, "wall_expansion %s" % [wall_cell])


func enqueue_adjacent_clues() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell).is_valid_int():
			schedule_task(deduce_adjacent_clues.bind(cell), 1100)


func enqueue_clued_islands() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var clue_value: int = board.get_clue_for_group(island)
		if clue_value == 0:
			# unclued island
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		if liberties.size() > 0:
			schedule_task(deduce_clued_island.bind(island.front()), 250)


func enqueue_island_dividers() -> void:
	var islands: Array[Array] = board.get_islands()
	for island: Array[Vector2i] in islands:
		var clue_value: int = board.get_clue_for_group(island)
		if clue_value == 0:
			# unclued island
			continue
		var liberties: Array[Vector2i] = board.get_liberties(island)
		if liberties.size() > 0:
			schedule_task(deduce_island_divider.bind(island.front()), 240)


func enqueue_islands_of_one() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) == "1":
			schedule_task(deduce_island_of_one.bind(cell), 1100)


func enqueue_wall_expansions() -> void:
	var walls: Array[Array] = board.get_walls()
	for wall: Array[Vector2i] in walls:
		var liberties: Array[Vector2i] = board.get_liberties(wall)
		if liberties.size() > 0:
			schedule_task(deduce_wall.bind(wall.front()), 245)


func _can_deduce(target_board: FastBoard, cell: Vector2i) -> bool:
	return target_board.get_cell_string(cell) == CELL_EMPTY and not cell in deductions.cells


func _find_adjacent_clues(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor_cell: Vector2i in board.get_neighbors(cell):
		if board.get_cell_string(neighbor_cell).is_valid_int():
			result.append(neighbor_cell)
	return result


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
		if board.get_clue_for_group(island) != 0 and board.get_liberties(island).size() > 0:
			schedule_task(deduce_clued_island.bind(island_root), 350)


func _task_key(callable: Callable) -> String:
	var key: String = callable.get_method()
	var args: Array[Variant] = callable.get_bound_arguments()
	if not args.is_empty():
		key += ":" + JSON.stringify(args)
	return key
