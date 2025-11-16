class_name PerClueChokepointMap

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var _board: SolverBoard

var _reachable_clues_by_cell: Dictionary[Vector2i, Dictionary] = {}

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _chokepoint_map_by_clue: Dictionary[Vector2i, ChokepointMap] = {}
var _claimed_by_clue: Dictionary[Vector2i, Vector2i] = {}

var _visitable: Dictionary[Vector2i, bool] = {}

func _init(init_board: SolverBoard) -> void:
	_board = init_board
	
	var islands: Array[Array] = _board.get_islands()
	
	# collect visitable cells (empty cells, or clueless islands)
	var island_clues: Dictionary[Vector2i, int] = _board.get_island_clues()
	for cell: Vector2i in _board.cells:
		if _board.get_cell(cell) in [CELL_ISLAND, CELL_EMPTY] \
				and island_clues.get(cell, 0) == 0:
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


func get_distance_map(island_cell: Vector2i, start_cells: Array[Vector2i]) -> Dictionary[Vector2i, int]:
	return get_chokepoint_map(island_cell).get_distance_map(start_cells)


func get_chokepoint_map(island_cell: Vector2i) -> ChokepointMap:
	if not _has_chokepoint_map(island_cell):
		_init_chokepoint_map(island_cell)
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	return _chokepoint_map_by_clue.get(island_root)


## Returns a mapping from cells to clues which can reach them.[br]
## [br]
## Note: This requires a chokepoint map for every clue in the puzzle, making it O(n^2) if those chokepoint maps have
## not been built.
func get_reachable_clues_by_cell() -> Dictionary[Vector2i, Dictionary]:
	if _reachable_clues_by_cell.is_empty():
		_init_reachable_clues_by_cell()
	return _reachable_clues_by_cell


## If there are any chokepoints which would prevent the island from being completed, this method returns the cell
## changes to preserve the island.
func find_chokepoint_cells(island_cell: Vector2i) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var chokepoint_map: ChokepointMap = get_chokepoint_map(island_cell)
	var clue_value: int = _board.get_clue_for_island_cell(island_cell)
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	
	for chokepoint: Vector2i in chokepoint_map.chokepoints_by_cell:
		var unchoked_cell_count: int = chokepoint_map.get_unchoked_cell_count(chokepoint, island_cell)
		if unchoked_cell_count >= clue_value:
			continue
		
		if _board.get_cell(chokepoint) == CELL_EMPTY:
			# the chokepoint itself must be an island
			result[chokepoint] = CELL_ISLAND
		
		for neighbor: Vector2i in _board.get_neighbors(chokepoint):
			# buffer wall between this and other clued islands
			if needs_buffer(island_root, neighbor):
				result[neighbor] = CELL_WALL
		
		if _board.get_cell(chokepoint) == CELL_ISLAND and _board.get_clue_for_island_cell(chokepoint) == 0:
			# buffer wall for any adjoining unclued islands
			for liberty_cell: Vector2i in _board.get_liberties(_board.get_island_for_cell(chokepoint)):
				if needs_buffer(island_root, liberty_cell):
					result[liberty_cell] = CELL_WALL
	
	return result


func get_component_cell_count(island_cell: Vector2i) -> int:
	return get_chokepoint_map(island_cell).get_component_cell_count(island_cell)


func get_component_cells(island_cell: Vector2i) -> Array[Vector2i]:
	return get_chokepoint_map(island_cell).get_component_cells(island_cell)


## Builds a GroupMap of all wall regions that would exist if this clue's entire reachable island area were filled
## in.[br]
## [br]
## In effect, this "excludes" the clue's component cells by treating them as solid islands, and groups every remaining
## wall or unreachable empty cell into contiguous wall components.[br]
## [br]
## Used to detect whether filling the island could create a split wall.
func get_wall_exclusion_map(island_cell: Vector2i) -> GroupMap:
	var component_cell_set: Dictionary[Vector2i, bool] = {}
	for component_cell in get_component_cells(island_cell):
		component_cell_set[component_cell] = true
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _board.cells:
		var value: int = _board.get_cell(cell)
		if value == CELL_WALL or (value == CELL_EMPTY and not cell in component_cell_set):
			cells.append(cell)
	return GroupMap.new(cells)


func _has_chokepoint_map(island_cell: Vector2i) -> bool:
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	return _chokepoint_map_by_clue.has(island_root)


func _init_chokepoint_map(island_cell: Vector2i) -> void:
	var reach_score_by_cell: Dictionary[Vector2i, int] = {}
	var queue: Array[Vector2i] = [island_cell]
	
	var island: Array[Vector2i] = _board.get_island_for_cell(island_cell)
	var clue_value: int = _board.get_clue_for_island_cell(island_cell)
	var reachability: int = clue_value - island.size()
	for other_island_cell: Vector2i in island:
		reach_score_by_cell[other_island_cell] = reachability + 1
	for liberty: Vector2i in _board.get_liberties(island):
		if not _visitable.has(liberty):
			continue
		if _claimed_by_clue.has(liberty) \
			and _claimed_by_clue[liberty] != island.front():
				continue
		reach_score_by_cell[liberty] = reachability
		queue.append(liberty)
	
	# propagate reachability using breadth-first expansion
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		
		for neighbor: Vector2i in _board.get_neighbors(cell):
			if not _visitable.has(neighbor):
				continue
			if _claimed_by_clue.has(neighbor) \
				and _claimed_by_clue[neighbor] != island.front():
					continue
			if reach_score_by_cell.has(neighbor):
				# already visited
				continue
			
			reach_score_by_cell[neighbor] = reach_score_by_cell[cell] - 1
			if reach_score_by_cell[neighbor] > 1:
				queue.append(neighbor)
	
	_chokepoint_map_by_clue[island.front()] = ChokepointMap.new(reach_score_by_cell.keys())


func _init_reachable_clues_by_cell() -> void:
	for island: Array[Vector2i] in _board.get_islands():
		if _board.get_liberties(island).is_empty():
			continue
		if _board.get_clue_for_island(island) < 1:
			continue
		
		var chokepoint_map: ChokepointMap = get_chokepoint_map(island.front())
		for cell: Vector2i in chokepoint_map.cells:
			if not _reachable_clues_by_cell.has(cell):
				_reachable_clues_by_cell[cell] = {} as Dictionary[Vector2i, bool]
			_reachable_clues_by_cell[cell][island.front()] = true


func needs_buffer(island_root: Vector2i, cell: Vector2i) -> bool:
	return _claimed_by_clue.has(cell) \
		and _claimed_by_clue[cell] != island_root \
		and _board.get_cell(cell) == CELL_EMPTY
