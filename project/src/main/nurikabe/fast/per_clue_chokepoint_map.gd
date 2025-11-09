class_name PerClueChokepointMap

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var _board: FastBoard

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _chokepoint_map_by_clue: Dictionary[Vector2i, ChokepointMap] = {}
var _claimed_by_clue: Dictionary[Vector2i, Vector2i] = {}

var _visitable: Dictionary[Vector2i, bool] = {}

func _init(init_board: FastBoard) -> void:
	_board = init_board
	
	var islands: Array[Array] = _board.get_islands()
	
	# collect visitable cells (empty cells, or clueless islands)
	for cell: Vector2i in _board.cells:
		if _board.get_cell_string(cell) in [CELL_ISLAND, CELL_EMPTY] \
				and _board.get_clue_value_for_cell(cell) == 0:
			_visitable[cell] = true
	
	# seed queue from islands
	for island: Array[Vector2i] in islands:
		var clue_value: int = _board.get_clue_for_group(island)
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
				_visitable.erase(liberty)


func get_chokepoint_map(island_cell: Vector2i) -> ChokepointMap:
	if not _has_chokepoint_map(island_cell):
		_init_chokepoint_map(island_cell)
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	return _chokepoint_map_by_clue.get(island_root)


## If there are any chokepoints which would prevent the island from being completed, this method returns the cell
## changes to preserve the island.
func find_chokepoint_cells(island_cell: Vector2i) -> Dictionary[Vector2i, String]:
	var result: Dictionary[Vector2i, String] = {}
	var chokepoint_map: ChokepointMap = get_chokepoint_map(island_cell)
	var clue_value: int = _board.get_clue_value_for_cell(island_cell)
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	
	for chokepoint: Vector2i in chokepoint_map.chokepoints_by_cell:
		var unchoked_cell_count: int = chokepoint_map.get_unchoked_cell_count(chokepoint, island_cell)
		if unchoked_cell_count >= clue_value:
			continue
		
		if _board.get_cell_string(chokepoint) == CELL_EMPTY:
			# the chokepoint itself must be an island
			result[chokepoint] = CELL_ISLAND
		
		for neighbor: Vector2i in _board.get_neighbors(chokepoint):
			# buffer wall between this and other clued islands
			if _needs_buffer(island_root, neighbor):
				result[neighbor] = CELL_WALL
		
		if _board.get_cell_string(chokepoint) == CELL_ISLAND and _board.get_clue_value_for_cell(chokepoint) == 0:
			# buffer wall for any adjoining unclued islands
			for liberty_cell in _board.get_liberties(_board.get_island_for_cell(chokepoint)):
				if _needs_buffer(island_root, liberty_cell):
					result[liberty_cell] = CELL_WALL
	
	return result


## If there is exactly enough space for the island to grow, this method returns the cell changes to complete the
## island.
func find_snug_cells(island_cell: Vector2i) -> Dictionary[Vector2i, String]:
	var result: Dictionary[Vector2i, String] = {}
	var chokepoint_map: ChokepointMap = get_chokepoint_map(island_cell)
	var clue_value: int = _board.get_clue_value_for_cell(island_cell)
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	
	if chokepoint_map.get_component_cell_count(island_cell) == clue_value:
		var component_cells: Array[Vector2i] = chokepoint_map.get_component_cells(island_cell)
		for component_cell: Vector2i in component_cells:
			if _board.get_cell_string(component_cell) == CELL_EMPTY:
				result[component_cell] = CELL_ISLAND
			for neighbor: Vector2i in _board.get_neighbors(component_cell):
				if _needs_buffer(island_root, neighbor):
					result[neighbor] = CELL_WALL
	
	return result


func _has_chokepoint_map(island_cell: Vector2i) -> bool:
	var island_root: Vector2i = _board.get_island_root_for_cell(island_cell)
	return _chokepoint_map_by_clue.has(island_root)


func _init_chokepoint_map(island_cell: Vector2i) -> void:
	var reach_score_by_cell: Dictionary[Vector2i, int] = {}
	var queue: Array[Vector2i] = [island_cell]
	
	var island: Array[Vector2i] = _board.get_island_for_cell(island_cell)
	var clue_value: int = _board.get_clue_value_for_cell(island_cell)
	var reachability: int = clue_value - island.size()
	for other_island_cell: Vector2i in island:
		reach_score_by_cell[other_island_cell] = reachability + 1
	for liberty: Vector2i in _board.get_liberties(island):
		if reach_score_by_cell.has(liberty):
			# cell is adjacent to two or more islands, so no islands can reach it
			reach_score_by_cell[liberty] = 0
			_adjacent_clues_by_cell[liberty] += 1
			continue
		reach_score_by_cell[liberty] = reachability
		queue.append(liberty)
	
	# propagate reachability using breadth-first expansion
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		
		for neighbor: Vector2i in _board.get_neighbors(cell):
			if not _visitable.has(neighbor):
				continue
			if reach_score_by_cell.has(neighbor):
				# already visited
				continue
			
			reach_score_by_cell[neighbor] = reach_score_by_cell[cell] - 1
			if reach_score_by_cell[neighbor] > 1:
				queue.append(neighbor)
	
	_chokepoint_map_by_clue[island.front()] = ChokepointMap.new(reach_score_by_cell.keys())


func _needs_buffer(island_root: Vector2i, cell: Vector2i) -> bool:
	return _claimed_by_clue.has(cell) \
		and _claimed_by_clue[cell] != island_root \
		and _board.get_cell_string(cell) == CELL_EMPTY
