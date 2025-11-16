class_name SolverTestUtils

static func init_board(grid: Array[String]) -> SolverBoard:
	var board: SolverBoard = SolverBoard.new()
	for y in grid.size():
		var row_string: String = grid[y]
		@warning_ignore("integer_division")
		for x in row_string.length() / 2:
			board.set_cell(Vector2i(x, y), NurikabeUtils.from_cell_string(row_string.substr(x * 2, 2).strip_edges()))
	return board
