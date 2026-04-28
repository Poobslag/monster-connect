class_name GeneratorTestUtils

static func init_board(grid: Array[String]) -> GeneratorBoard:
	var board: GeneratorBoard = GeneratorBoard.new()
	board.solver_board.from_grid_string("\n".join(grid))
	return board
