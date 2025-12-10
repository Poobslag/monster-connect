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

var board: SolverBoard

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _extent_map_by_clue: Dictionary[Vector2i, Dictionary] = {}
var _claimed_by_clue: Dictionary[Vector2i, Vector2i] = {}

var _visitable: Dictionary[Vector2i, bool] = {}

func _init(init_board: SolverBoard) -> void:
	board = init_board
	
	# collect visitable cells (empty cells, or clueless islands)
	for cell: Vector2i in board.cells:
		var cell_value: int = board.get_cell(cell)
		if cell_value == CELL_EMPTY:
			_visitable[cell] = true
	for island: CellGroup in board.islands:
		if island.clue != 0:
			continue
		for cell: Vector2i in island.cells:
			_visitable[cell] = true
	
	# seed queue from islands
	for island: CellGroup in board.islands:
		if island.clue == 0:
			continue
		for liberty: Vector2i in island.liberties:
			if _adjacent_clues_by_cell.has(liberty):
				# cell is adjacent to two or more islands, so no islands can reach it
				_adjacent_clues_by_cell[liberty] += 1
				_visitable.erase(liberty)
			else:
				_adjacent_clues_by_cell[liberty] = 1
				_claimed_by_clue[liberty] = island.cells.front()


func get_extent_size(island: CellGroup) -> int:
	if not _has_extent_map(island):
		_init_extent_map(island)
	return _extent_map_by_clue[island.cells.front()].size()


func get_extent_cells(island: CellGroup) -> Array[Vector2i]:
	if not _has_extent_map(island):
		_init_extent_map(island)
	return _extent_map_by_clue[island.cells.front()].keys()


func _has_extent_map(island: CellGroup) -> bool:
	return _extent_map_by_clue.has(island.cells.front())


func _init_extent_map(island: CellGroup) -> void:
	var extent_map: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in island.cells:
		extent_map[cell] = true
	var extent_list: Array[Vector2i] = board.perform_bfs(island.liberties, func(cell: Vector2i) -> bool:
		return extent_map.size() <= island.clue \
				and _visitable.has(cell) \
				and (not _claimed_by_clue.has(cell) or _claimed_by_clue[cell] == island.cells.front()))
	for cell: Vector2i in extent_list:
		extent_map[cell] = true
	
	_extent_map_by_clue[island.cells.front()] = extent_map
	SplitTimer.end()


func needs_buffer(island: CellGroup, cell: Vector2i) -> bool:
	return _claimed_by_clue.has(cell) \
		and _claimed_by_clue[cell] != island.cells.front() \
		and board.get_cell(cell) == CELL_EMPTY
