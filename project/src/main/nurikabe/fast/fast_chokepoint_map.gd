class_name FastChokepointMap
## Identifies articulation points within the specified Nurikabe region type (islands, walls, etc.)[br]
## [br]
## Uses Tarjan's articulation-point algorithm on cells matching the filter. O(n) build.

var chokepoints_by_cell: Dictionary[Vector2i, bool]:
	get():
		if _chokepoint_map == null:
			_build_chokepoint_map()
		return _chokepoint_map.chokepoints_by_cell

var _board: FastBoard
var _cell_filter: Callable
var _special_cell_filter: Callable
var _chokepoint_map: ChokepointMap

func _init(init_board: FastBoard, init_cell_filter: Callable, init_special_cell_filter: Callable = Callable()) -> void:
	_board = init_board
	_cell_filter = init_cell_filter
	_special_cell_filter = init_special_cell_filter


func get_component_cell_count(cell: Vector2i) -> int:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_component_cell_count(cell)


func get_component_cells(cell: Vector2i) -> Array[Vector2i]:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_component_cells(cell)


func get_component_special_count(cell: Vector2i) -> int:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_component_special_count(cell)


func get_subtree_roots() -> Array[Vector2i]:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_subtree_roots()


func get_subtree_root(cell: Vector2i) -> Vector2i:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_subtree_root(cell)


func get_unchoked_cell_count(chokepoint: Vector2i, cell: Vector2i) -> int:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_unchoked_cell_count(chokepoint, cell)


func get_unchoked_special_count(chokepoint: Vector2i, cell: Vector2i) -> int:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_unchoked_special_count(chokepoint, cell)


func _build_chokepoint_map() -> void:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _board.cells:
		if _cell_filter.call(_board.get_cell_string(cell)):
			cells.append(cell)
	_chokepoint_map = ChokepointMap.new(cells, _special_cell_filter)
