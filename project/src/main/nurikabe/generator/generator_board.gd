class_name GeneratorBoard

var cells: Dictionary[Vector2i, int]:
	get():
		return solver_board.cells

var solver_board: SolverBoard = SolverBoard.new()

func clear() -> void:
	solver_board.clear()


func from_game_board(game_board: NurikabeGameBoard) -> void:
	solver_board.from_game_board(game_board)


func is_filled() -> bool:
	return solver_board.is_filled()


func set_cell(cell_pos: Vector2i, value: int) -> void:
	solver_board.set_cell(cell_pos, value)


## Sets the specified cells on the model.[br]
## [br]
## Accepts a dictionary with the following keys:[br]
## 	'pos': (Vector2i) The cell to update.[br]
## 	'value': (String) The value to assign.[br]
func set_cells(changes: Array[Dictionary]) -> void:
	solver_board.set_cells(changes)


func set_clue(cell_pos: Vector2i, value: int) -> void:
	solver_board.set_clue(cell_pos, value)


func get_cell(cell_pos: Vector2i) -> int:
	return solver_board.get_cell(cell_pos)
