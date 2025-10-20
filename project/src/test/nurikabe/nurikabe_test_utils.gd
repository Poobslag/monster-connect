class_name NurikabeTestUtils

static func init_model(grid: Array[String]) -> NurikabeBoardModel:
	var model: NurikabeBoardModel = NurikabeBoardModel.new()
	for y in grid.size():
		var row_string: String = grid[y]
		@warning_ignore("integer_division")
		for x in row_string.length() / 2:
			model.set_cell_string(Vector2i(x, y), row_string.substr(x * 2, 2).strip_edges())
	return model
