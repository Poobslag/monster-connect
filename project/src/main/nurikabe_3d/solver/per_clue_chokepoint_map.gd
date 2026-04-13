class_name PerClueChokepointMap
## Calculates chokepoints for each clue.[br]
## [br]
## Uses Tarjan's articulation-point algorithm to calculate whether blocking cells invalidates certain clues. O(n)
## build for each queried clue.

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

var board: SolverBoard

var _reachable_clues_by_cell: Dictionary[Vector2i, Dictionary] = {}

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _chokepoint_map_by_clue: Dictionary[Vector2i, ChokepointMap] = {}
var _claimed_by_clue: Dictionary[Vector2i, Vector2i] = {}

var _visitable: Dictionary[Vector2i, bool] = {}

func _init(init_board: SolverBoard) -> void:
	board = init_board
	
	# collect visitable cells (empty cells, or clueless islands)
	for cell: Vector2i in board.empty_cells:
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
				_claimed_by_clue[liberty] = island.root


func get_distance_map(island: CellGroup, start_cells: Array[Vector2i]) -> Dictionary[Vector2i, int]:
	return get_chokepoint_map(island).get_distance_map(start_cells)


func get_chokepoint_map(island: CellGroup) -> ChokepointMap:
	if not _has_chokepoint_map(island):
		_init_chokepoint_map(island)
	return _chokepoint_map_by_clue.get(island.root)


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
func find_chokepoint_cells(island: CellGroup) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var chokepoint_map: ChokepointMap = get_chokepoint_map(island)
	
	for chokepoint: Vector2i in chokepoint_map.chokepoints_by_cell:
		var unchoked_cell_count: int = chokepoint_map.get_unchoked_cell_count(chokepoint, island.root)
		if unchoked_cell_count >= island.clue or island.clue == CELL_MYSTERY_CLUE:
			continue
		
		if board.get_cell(chokepoint) == CELL_EMPTY:
			# the chokepoint itself must be an island
			result[chokepoint] = CELL_ISLAND
		
		for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
			var neighbor: Vector2i = chokepoint + neighbor_dir
			# buffer wall between this and other clued islands
			if needs_buffer(island, neighbor):
				result[neighbor] = CELL_WALL
		
		# buffer wall for any adjoining unclued islands
		if board.get_cell(chokepoint) != CELL_ISLAND:
			continue
		var chokepoint_island: CellGroup = board.get_island_for_cell(chokepoint)
		for liberty: Vector2i in chokepoint_island.liberties:
			if needs_buffer(island, liberty):
				result[liberty] = CELL_WALL
	
	return result


func get_component_cell_count(island: CellGroup) -> int:
	return get_chokepoint_map(island).get_component_cell_count(island.root)


func get_component_cells(island: CellGroup) -> Array[Vector2i]:
	return get_chokepoint_map(island).get_component_cells(island.root)


func _has_chokepoint_map(island: CellGroup) -> bool:
	return _chokepoint_map_by_clue.has(island.root)


func _init_chokepoint_map(island: CellGroup) -> void:
	var reach_score_by_cell: Dictionary[Vector2i, int] = {}
	var queue: Array[Vector2i] = [island.root]
	
	var reach_score: int = island.get_remaining_capacity()
	for other_island_cell: Vector2i in island.cells:
		reach_score_by_cell[other_island_cell] = reach_score + 1
	for liberty: Vector2i in island.liberties:
		if not _visitable.has(liberty):
			continue
		if _claimed_by_clue.has(liberty) \
			and _claimed_by_clue[liberty] != island.root:
				continue
		reach_score_by_cell[liberty] = reach_score
		queue.append(liberty)
	
	# propagate reach_score using breadth-first expansion
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		
		for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not _visitable.has(neighbor):
				continue
			if _claimed_by_clue.has(neighbor) \
				and _claimed_by_clue[neighbor] != island.root:
					continue
			if reach_score_by_cell.has(neighbor):
				# already visited
				continue
			
			reach_score_by_cell[neighbor] = reach_score_by_cell[cell] - 1
			if reach_score_by_cell[neighbor] > 1:
				queue.append(neighbor)
	
	_chokepoint_map_by_clue[island.root] = ChokepointMap.new(reach_score_by_cell.keys())


func _init_reachable_clues_by_cell() -> void:
	for island: CellGroup in board.islands:
		if island.liberties.is_empty():
			continue
		if island.clue < 1:
			continue
		
		var chokepoint_map: ChokepointMap = get_chokepoint_map(island)
		for cell: Vector2i in chokepoint_map.cells:
			if not _reachable_clues_by_cell.has(cell):
				_reachable_clues_by_cell[cell] = {} as Dictionary[Vector2i, bool]
			_reachable_clues_by_cell[cell][island.root] = true


func needs_buffer(island: CellGroup, cell: Vector2i) -> bool:
	return _claimed_by_clue.has(cell) \
		and _claimed_by_clue[cell] != island.root \
		and board.get_cell(cell) == CELL_EMPTY
