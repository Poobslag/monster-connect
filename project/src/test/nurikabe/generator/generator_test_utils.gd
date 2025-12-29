class_name GeneratorTestUtils

static func init_board(grid: Array[String]) -> GeneratorBoard:
	var board: GeneratorBoard = GeneratorBoard.new()
	for y in grid.size():
		var row_string: String = grid[y]
		@warning_ignore("integer_division")
		for x in row_string.length() / 2:
			var cell: Vector2i = Vector2i(x, y)
			var cell_value: int = NurikabeUtils.from_cell_string(row_string.substr(x * 2, 2).strip_edges())
			if NurikabeUtils.is_clue(cell_value):
				board.set_clue(cell, cell_value)
			else:
				board.set_cell(cell, cell_value)
	return board


static func init_janko(grid: Array[String]) -> GeneratorBoard:
	var board: GeneratorBoard = GeneratorBoard.new()
