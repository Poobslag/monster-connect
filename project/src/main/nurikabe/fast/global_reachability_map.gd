class_name GlobalReachabilityMap
## Calculates whether each empty cell is reachable by a clue.[br]
## [br]
## Expands a multi-source BFS wave from all clues, where each clue's reach decays with distance and remaining quota
## (clue value - island size). Conceptually forms overlapping pyramids of influence. O(n) build.

enum ClueReachability {
	UNKNOWN,
	REACHABLE,
	UNREACHABLE,
	IMPOSSIBLE,
	CONFLICT,
}

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var _board: FastBoard

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _nearest_clue_root_by_cell: Dictionary[Vector2i, Vector2i] = {}
var _reachability_by_cell: Dictionary[Vector2i, ClueReachability] = {}
var _reach_score_by_cell: Dictionary[Vector2i, int] = {}

func _init(init_board: FastBoard) -> void:
	_board = init_board
	_build()


func get_clue_reachability(cell: Vector2i) -> ClueReachability:
	return _reachability_by_cell.get(cell, ClueReachability.UNKNOWN)


## Returns the "most reachable" clue to [param cell].[br]
## [br]
## Reachability accounts for clue distance, clue value, and current island size. A large nearby clue with few existing
## island cells ranks high, while a small distant clue with many existing island cells ranks low.
func get_nearest_clue_cell(cell: Vector2i) -> Vector2i:
	return _nearest_clue_root_by_cell.get(cell, POS_NOT_FOUND)


func _build() -> void:
	var islands: Array[Array] = _board.get_islands()
	
	# collect visitable cells (empty cells, or clueless islands)
	var visitable: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in _board.cells:
		if _board.get_cell_string(cell) in [CELL_ISLAND, CELL_EMPTY] \
				and _board.get_clue_value_for_cell(cell) == 0:
			visitable[cell] = true
	
	# seed queue from islands
	var queue: Array[Vector2i] = []
	for island: Array[Vector2i] in islands:
		var clue_value: int = _board.get_clue_for_group(island)
		if clue_value == 0:
			continue
		var reachability: int = clue_value - island.size()
		for liberty: Vector2i in _board.get_liberties(island):
			if _reach_score_by_cell.has(liberty):
				# cell is adjacent to two or more islands, so no islands can reach it
				_reach_score_by_cell[liberty] = 0
				_adjacent_clues_by_cell[liberty] += 1
				continue
			
			_reach_score_by_cell[liberty] = reachability
			_nearest_clue_root_by_cell[liberty] = island.front()
			_adjacent_clues_by_cell[liberty] = 1
			queue.append(liberty)
	
	# propagate reachability using breadth-first expansion
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		
		for neighbor: Vector2i in _board.get_neighbors(cell):
			if not visitable.has(neighbor):
				continue
			if _reach_score_by_cell.has(neighbor):
				if _adjacent_clues_by_cell[neighbor] >= 1:
					# cell is adjacent to an island, so only one island can reach it
					continue
				if _reach_score_by_cell[neighbor] >= _reach_score_by_cell[cell] - 1:
					# cell is closer to another island
					continue
			
			_reach_score_by_cell[neighbor] = _reach_score_by_cell[cell] - 1
			_nearest_clue_root_by_cell[neighbor] = _nearest_clue_root_by_cell[cell]
			_adjacent_clues_by_cell[neighbor] = 0
			queue.append(neighbor)
	
	# classify each cell into ClueReachability categories
	for cell: Vector2i in _board.cells:
		var reachability: ClueReachability = ClueReachability.UNKNOWN
		if not _reach_score_by_cell.has(cell):
			reachability = ClueReachability.IMPOSSIBLE
		elif _adjacent_clues_by_cell[cell] >= 2:
			reachability = ClueReachability.CONFLICT
		elif _reach_score_by_cell[cell] >= 1:
			reachability = ClueReachability.REACHABLE
		else:
			reachability = ClueReachability.UNREACHABLE
		_reachability_by_cell[cell] = reachability
