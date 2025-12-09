class_name PerClueExtentMap
## Calculates extents for each clue.[br]
## [br]
## Performs a BFS from each queried clue to determine the set of reachable cells. For performance, the BFS stops early
## once the reachable cell count exceeds the clue value. For an exhaustive list of all reachable cells, use
## PerClueChokepointMap instead.[br]

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var _board: SolverBoard

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _extent_map_by_clue: Dictionary[Vector2i, Dictionary] = {}
var _claimed_by_clue: Dictionary[Vector2i, Vector2i] = {}

var _visitable: Dictionary[Vector2i, bool] = {}

func _init(init_board: SolverBoard) -> void:
	_board = init_board
	
	var islands: Array[Array] = _board.get_islands()
	
	# collect visitable cells (empty cells, or clueless islands)
	var island_clues: Dictionary[Vector2i, int] = _board.get_island_clues()
	for cell: Vector2i in _board.cells:
		var cell_value: int = _board.get_cell(cell)
		if cell_value == CELL_EMPTY \
				or (cell_value == CELL_ISLAND and island_clues.get(cell, 0) == 0):
			_visitable[cell] = true
	
	# seed queue from islands
	for island: Array[Vector2i] in islands:
		var clue_value: int = island_clues.get(island.front(), 0)
		if clue_value == 0:
			continue
		for liberty: Vector2i in _board.get_liberties(island):
			if _adjacent_clues_by_cell.has(liberty):
				# cell is adjacent to two or more islands, so no islands can reach it
				_adjacent_clues_by_cell[liberty] += 1
				_visitable.erase(liberty)
			else:
				_adjacent_clues_by_cell[liberty] = 1
				_claimed_by_clue[liberty] = island.front()


func get_extent_size(island_cell: Vector2i) -> int:
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	if not _has_extent_map(island_root):
		_init_extent_map(island_root)
	return _extent_map_by_clue[island_root].size()


func get_extent_cells(island_cell: Vector2i) -> Array[Vector2i]:
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	if not _has_extent_map(island_root):
		_init_extent_map(island_root)
	return _extent_map_by_clue[island_root].keys()


func _has_extent_map(island_root: Vector2i) -> bool:
	return _extent_map_by_clue.has(island_root)


func _init_extent_map(island_root: Vector2i) -> void:
	var clue_value: int = _board.get_clue_for_island_cell(island_root)
	var island: Array[Vector2i] = _board.get_island_for_cell(island_root)
	var extent_map: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in island:
		extent_map[cell] = true
	
	_board.perform_bfs(_board.get_liberties(island), func(cell: Vector2i) -> bool:
		if extent_map.size() > clue_value:
			return false
		if not _visitable.has(cell):
			return false
		if _claimed_by_clue.has(cell) and _claimed_by_clue[cell] != island_root:
			return false
		extent_map[cell] = true
		return true)
	
	_extent_map_by_clue[island_root] = extent_map
	SplitTimer.end()


func needs_buffer(island_root: Vector2i, cell: Vector2i) -> bool:
	return _claimed_by_clue.has(cell) \
		and _claimed_by_clue[cell] != island_root \
		and _board.get_cell(cell) == CELL_EMPTY
