class_name SolverTestUtils

static func init_board(grid: Array[String]) -> SolverBoard:
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	return board
