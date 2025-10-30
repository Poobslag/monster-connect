class_name FastSolver

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var fast_pass: FastPass = FastPass.new()
var board: FastBoard

var _knowledge: Dictionary[String, Variant] = {
}
var _queue: Array[Callable] = [
]

func clear() -> void:
	fast_pass.clear()
	_knowledge.clear()
	_queue.clear()


func do_something() -> void:
	# pick ideas for what to solve... cells, techniques
	if _queue.is_empty():
		_populate_queue()
	
	# attempt to solve
	if not _queue.is_empty():
		var next_technique: Callable = _queue.pop_front()
		next_technique.call()


func get_changes() -> Array[Dictionary]:
	return fast_pass.get_changes()


func is_queue_empty() -> bool:
	return _queue.is_empty()


func apply_changes() -> void:
	board.set_cell_strings(fast_pass.get_changes())
	fast_pass.clear()


func deduce_adjacent_clues(clue_cell: Vector2i) -> void:
	if not board.get_cell_string(clue_cell).is_valid_int():
		return
	
	for neighbor_cell: Vector2i in board.get_neighbors(clue_cell):
		if not _can_deduce(board, neighbor_cell):
			continue
		var adjacent_clues: Array[Vector2i] = _find_adjacent_clues(neighbor_cell)
		if adjacent_clues.size() >= 2:
			fast_pass.add_deduction(neighbor_cell, CELL_WALL,
				"adjacent_clues %s %s" % [adjacent_clues[0], adjacent_clues[1]])


func deduce_island_of_one(clue_cell: Vector2i) -> void:
	if not board.get_cell_string(clue_cell) == "1":
		return
	for neighbor_cell in board.get_neighbors(clue_cell):
		if not _can_deduce(board, neighbor_cell):
			continue
		fast_pass.add_deduction(neighbor_cell, CELL_WALL,
			"island_of_one %s" % [clue_cell])


func _can_deduce(target_board: FastBoard, cell: Vector2i) -> bool:
	return target_board.get_cell_string(cell) == CELL_EMPTY and not cell in fast_pass.deduction_cells


func _find_adjacent_clues(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor_cell: Vector2i in board.get_neighbors(cell):
		if board.get_cell_string(neighbor_cell).is_valid_int():
			result.append(neighbor_cell)
	return result


func _populate_queue() -> void:
	if _queue.is_empty() and not _knowledge.has("island_of_one"):
		for cell: Vector2i in board.cells:
			if board.get_cell_string(cell) == "1":
				_queue.append(deduce_island_of_one.bind(cell))
		_knowledge["island_of_one"] = true
	
	if _queue.is_empty() and not _knowledge.has("adjacent_clues"):
		for cell: Vector2i in board.cells:
			if board.get_cell_string(cell).is_valid_int():
				_queue.append(deduce_adjacent_clues.bind(cell))
		_knowledge["adjacent_clues"] = true
	
	print("queue -> %s" % [_queue])
