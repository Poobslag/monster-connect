class_name NurikabeConnectivityMap

var cell_filter: Callable
var gcm: GridConnectivityMap

func _init(init_cell_filter: Callable) -> void:
	cell_filter = init_cell_filter


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	var new_active: bool = cell_filter.call(value)
	gcm.set_active(cell_pos, new_active)


func get_groups() -> Array[Array]:
	return gcm.get_groups()
