class_name GeneratorBoard

var cells: Dictionary[Vector2i, int]:
	get():
		return solver_board.cells

var solver_board: SolverBoard = SolverBoard.new()

func clear() -> void:
	solver_board.clear()


func from_game_board(game_board: NurikabeGameBoard) -> void:
	solver_board.from_game_board(game_board)


func set_cell(cell_pos: Vector2i, value: int) -> void:
	solver_board.set_cell(cell_pos, value)


func set_clue(cell_pos: Vector2i, value: int) -> void:
	solver_board.set_clue(cell_pos, value)


func get_cell(cell_pos: Vector2i) -> int:
	return solver_board.get_cell(cell_pos)
