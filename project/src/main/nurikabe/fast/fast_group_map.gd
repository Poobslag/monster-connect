class_name FastGroupMap

var groups: Array[Array]:
	get():
		if _group_map == null:
			_build_group_map()
		return _group_map.groups

var groups_by_cell: Dictionary[Vector2i, Array]:
	get():
		if _group_map == null:
			_build_group_map()
		return _group_map.groups_by_cell

var roots_by_cell: Dictionary[Vector2i, Vector2i]:
	get():
		if _group_map == null:
			_build_group_map()
		return _group_map.roots_by_cell

var _board: FastBoard
var _cell_filter: Callable
var _group_map: GroupMap

func _init(init_board: FastBoard, init_cell_filter: Callable) -> void:
	_board = init_board
	_cell_filter = init_cell_filter


func _build_group_map() -> void:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _board.cells:
		if _cell_filter.call(_board.get_cell_string(cell)):
			cells.append(cell)
	_group_map = GroupMap.new(cells)
