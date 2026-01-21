class_name SolverChokepointMap
## Identifies articulation points within the specified Nurikabe region type (islands, walls, etc.)[br]
## [br]
## Uses Tarjan's articulation-point algorithm on cells matching the filter. O(n) build.

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

var chokepoints_by_cell: Dictionary[Vector2i, bool]:
	get():
		if _chokepoint_map == null:
			_build_chokepoint_map()
		return _chokepoint_map.chokepoints_by_cell

var board: SolverBoard
var _included_types: Array[int]
var _special_cell_filter: Callable
var _chokepoint_map: ChokepointMap

func _init(init_board: SolverBoard, init_included_types: Array[int], \
		init_special_cell_filter: Callable = Callable()) -> void:
	board = init_board
	_included_types = init_included_types
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


func get_subtree_root_under_chokepoint(chokepoint: Vector2i, cell: Vector2i) -> Vector2i:
	if _chokepoint_map == null:
		_build_chokepoint_map()
	return _chokepoint_map.get_subtree_root_under_chokepoint(chokepoint, cell)


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
	if CELL_EMPTY in _included_types:
		cells.append_array(board.empty_cells.keys())
	if CELL_WALL in _included_types:
		for wall: CellGroup in board.walls:
			cells.append_array(wall.cells)
	if CELL_ISLAND in _included_types:
		for island: CellGroup in board.islands:
			cells.append_array(island.cells)
	_chokepoint_map = ChokepointMap.new(cells, _special_cell_filter)
