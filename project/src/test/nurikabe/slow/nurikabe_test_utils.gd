class_name NurikabeTestUtils

static func init_model(grid: Array[String]) -> NurikabeBoardModel:
	var model: NurikabeBoardModel = NurikabeBoardModel.new()
	for y in grid.size():
		var row_string: String = grid[y]
		@warning_ignore("integer_division")
		for x in row_string.length() / 2:
			model.set_cell_string(Vector2i(x, y), row_string.substr(x * 2, 2).strip_edges())
	return model


static func sort_groups(groups: Array[Array]) -> Array[Array]:
	var new_groups: Array[Array] = []
	for group: Array[Variant] in groups:
		var new_group: Array[Vector2i] = []
		new_group.assign(group)
		new_group.sort()
		new_groups.append(new_group)
	new_groups.sort_custom(func(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
		if a.is_empty() != b.is_empty():
			return a.is_empty()
		return a[0] < b[0])
	return new_groups
