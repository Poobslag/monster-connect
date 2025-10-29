class_name GridConnectivityMap

var cells: Dictionary[Vector2i, bool] = {}
var groups: Array[Array] = []

func clear() -> void:
	cells.clear()
	groups.clear()


func has_cell(pos: Vector2i) -> bool:
	return pos in cells


func set_active(pos: Vector2i, active: bool) -> void:
	cells[pos] = active
	groups.append([pos] as Array[Vector2i])


func is_active(pos: Vector2i) -> bool:
	return cells.has(pos)


func get_groups() -> Array[Array]:
	return groups
