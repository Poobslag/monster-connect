class_name NurikabeUnionFind

var cell_filter: Callable
var guf: GridUnionFind = GridUnionFind.new()

func _init(init_cell_filter: Callable) -> void:
	cell_filter = init_cell_filter


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	var new_active: bool = cell_filter.call(value)
	guf.set_active(cell_pos, new_active)


func get_groups() -> Array[Array]:
	return guf.get_groups()


func duplicate() -> NurikabeUnionFind:
	var copy: NurikabeUnionFind = NurikabeUnionFind.new(cell_filter)
	copy.guf = guf.duplicate()
	return copy
