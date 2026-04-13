class_name SolverGroupMap
## Groups connected cells of a given type (islands, walls, etc.) into disjoint sets.[br]
## [br]
## Flood-fills all cells matching the filter. O(n) build.

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

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
var _group_map: GroupMap
var _included_types: Array[int] = []

func _init(init_board: SolverBoard, init_included_types: Array[int]) -> void:
	_board = init_board
	_included_types = init_included_types


func _build_group_map() -> void:
	var cells: Array[Vector2i] = []
	if CELL_EMPTY in _included_types:
		cells.append_array(_board.empty_cells.keys())
	if CELL_WALL in _included_types:
		for wall: CellGroup in _board.walls:
			cells.append_array(wall.cells)
	if CELL_ISLAND in _included_types:
		for island: CellGroup in _board.islands:
			cells.append_array(island.cells)
	_group_map = GroupMap.new(cells)


func erase_group(group: Array[Vector2i]) -> void:
	_group_map.erase_group(group)
