class_name FastSolver

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var deductions: DeductionBatch = DeductionBatch.new()
var board: FastBoard

var _task_history: Dictionary[String, Dictionary] = {
}
var _task_queue: Array[Callable] = [
]

func apply_changes() -> void:
	board.set_cell_strings(deductions.get_changes())
	deductions.clear()


func clear() -> void:
	deductions.clear()
	_task_history.clear()
	_task_queue.clear()


func is_queue_empty() -> bool:
	return _task_queue.is_empty()


func get_changes() -> Array[Dictionary]:
	return deductions.get_changes()


func schedule_tasks() -> void:
	if _task_queue.is_empty() and not _task_history.has("enqueue_islands_of_one"):
		schedule_task(enqueue_islands_of_one.bind())
	
	if _task_queue.is_empty() and not _task_history.has("enqueue_adjacent_clues"):
		schedule_task(enqueue_adjacent_clues.bind())


func schedule_task(callable: Callable) -> void:
	_task_queue.append(callable)


func step() -> void:
	if _task_queue.is_empty():
		schedule_tasks()
	
	if not _task_queue.is_empty():
		run_next_task()


func print_queue() -> void:
	var strings: Array[String] = []
	for callable: Callable in _task_queue:
		strings.append("%s %s" % [callable.get_method(), callable.get_bound_arguments()])
	print(str(strings))


func run_all_tasks() -> void:
	while not _task_queue.is_empty():
		run_next_task()


func run_next_task() -> void:
	if _task_queue.is_empty():
		return
	
	var next_technique: Callable = _task_queue.pop_front()
	_task_history[next_technique.get_method()] = {
		"last_run": board.get_filled_cell_count()
	} as Dictionary[String, Variant]
	next_technique.call()


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


func enqueue_adjacent_clues() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell).is_valid_int():
			_task_queue.append(deduce_adjacent_clues.bind(cell))


func enqueue_islands_of_one() -> void:
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) == "1":
			_task_queue.append(deduce_island_of_one.bind(cell))


func _can_deduce(target_board: FastBoard, cell: Vector2i) -> bool:
	return target_board.get_cell_string(cell) == CELL_EMPTY and not cell in deductions.cells


func _find_adjacent_clues(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor_cell: Vector2i in board.get_neighbors(cell):
		if board.get_cell_string(neighbor_cell).is_valid_int():
			result.append(neighbor_cell)
	return result
