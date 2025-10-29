class_name NurikabeUnionFind
## Implementation of the union-find data structure for a nurikabe puzzle.[br]
## [br]
## Efficiently finds clusters of nurikabe cells matching a filter.

var cell_filter: Callable
var _guf: GridUnionFind = GridUnionFind.new()
var _pending_updates: Array[Dictionary] = []

func _init(init_cell_filter: Callable) -> void:
	cell_filter = init_cell_filter


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	_pending_updates.append({"cell_pos": cell_pos, "value": value} as Dictionary[String, Variant])


func get_groups() -> Array[Array]:
	for update: Dictionary[String, Variant] in _pending_updates:
		var new_active: bool = cell_filter.call(update["value"])
		_guf.set_active(update["cell_pos"], new_active)
	
	return _guf.get_groups()


func duplicate() -> NurikabeUnionFind:
	var copy: NurikabeUnionFind = NurikabeUnionFind.new(cell_filter)
	copy._guf = _guf.duplicate()
	copy._pending_updates = _pending_updates.duplicate()
	return copy
