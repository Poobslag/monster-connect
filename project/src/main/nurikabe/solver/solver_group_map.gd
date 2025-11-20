class_name SolverGroupMap
## Groups connected cells of a given type (islands, walls, etc.) into disjoint sets.[br]
## [br]
## Flood-fills all cells matching the filter. O(n) build.

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

var _board: SolverBoard
var _cell_filter: Callable
var _group_map: GroupMap

func _init(init_board: SolverBoard, init_cell_filter: Callable) -> void:
	_board = init_board
	_cell_filter = init_cell_filter


func _build_group_map() -> void:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _board.cells:
		if _cell_filter.call(_board.get_cell(cell)):
			cells.append(cell)
	_group_map = GroupMap.new(cells)


func erase_group(group: Array[Vector2i]) -> void:
	_group_map.erase_group(group)
