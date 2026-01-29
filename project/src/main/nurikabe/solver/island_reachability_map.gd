class_name IslandReachabilityMap
## Calculates whether each empty cell is reachable by a clue.

enum ClueReachability {
	UNKNOWN,
	REACHABLE,
	UNREACHABLE,
	CONFLICT,
	IMPOSSIBLE,
	CHAIN_CYCLE,
}

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var board: SolverBoard

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _reach_scores_by_cell: Dictionary[Vector2i, Dictionary] = {}
var _cycles_by_cell: Dictionary[Vector2i, bool] = {}

func _init(init_board: SolverBoard) -> void:
	board = init_board
	_build()


func get_clue_reachability(cell: Vector2i) -> ClueReachability:
	var reachability: ClueReachability
	if _adjacent_clues_by_cell.get(cell, 0) >= 2:
		reachability = ClueReachability.CONFLICT
	elif _reach_scores_by_cell.has(cell) and not _reach_scores_by_cell[cell].is_empty():
		if _reach_scores_by_cell[cell].values().front() >= 1:
			reachability = ClueReachability.REACHABLE
		elif _cycles_by_cell.has(cell):
			reachability = ClueReachability.CHAIN_CYCLE
		else:
			reachability = ClueReachability.UNREACHABLE
	else:
		reachability = ClueReachability.IMPOSSIBLE
	return reachability


func has_exclusive_root(cell: Vector2i) -> int:
	return _reach_scores_by_cell.has(cell) \
			and _reach_scores_by_cell[cell].size() == 1 \
			and _reach_scores_by_cell[cell].values().front() >= 1


func get_exclusive_root(cell: Vector2i) -> Vector2i:
	return _reach_scores_by_cell[cell].keys().front()


func get_reach_score(cell: Vector2i, root: Vector2i) -> int:
	if not _reach_scores_by_cell.has(cell):
		return 0
	if not _reach_scores_by_cell[cell].has(root):
		return 0
	return _reach_scores_by_cell[cell][root]


func get_nearest_clued_island_cell(cell: Vector2i) -> Vector2i:
	if not _reach_scores_by_cell.has(cell) or _reach_scores_by_cell[cell].is_empty():
		return POS_NOT_FOUND
	
	var roots: Array[Vector2i] = _reach_scores_by_cell[cell].keys()
	var nearest_root: Vector2i = roots.front()
	var nearest_score: int = _reach_scores_by_cell[cell][nearest_root]
	for i in range(1, roots.size()):
		var root: Vector2i = roots[i]
		var score: int = _reach_scores_by_cell[cell][root]
		if score > nearest_score:
			nearest_score = score
			nearest_root = root
	return nearest_root


func _build() -> void:
	# collect visitable cells (empty cells, or clueless islands)
	var visitable: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in board.empty_cells:
		visitable[cell] = true
		_reach_scores_by_cell[cell] = {} as Dictionary[Vector2i, int]
	for island: CellGroup in board.islands:
		if island.clue != 0:
			continue
		for cell: Vector2i in island.cells:
			visitable[cell] = true
			_reach_scores_by_cell[cell] = {} as Dictionary[Vector2i, int]
	
	# seed queue from islands
	var queue: Array[Vector2i] = []
	for island: CellGroup in board.islands:
		if island.clue == 0:
			continue
		for liberty: Vector2i in island.liberties:
			if not _adjacent_clues_by_cell.has(liberty):
				_adjacent_clues_by_cell[liberty] = 0
			_adjacent_clues_by_cell[liberty] += 1
	for island: CellGroup in board.islands:
		if island.clue == 0:
			continue
		for liberty: Vector2i in island.liberties:
			if _adjacent_clues_by_cell[liberty] >= 2:
				# cell is adjacent to two or more islands, so no islands can reach it
				_reach_scores_by_cell[liberty] = {island.root: 0}
				continue
			var reachability: int = island.clue - island.size() if island.clue != CELL_MYSTERY_CLUE else 999999
			_reach_scores_by_cell[liberty][island.root] = reachability
			queue.append(liberty)
	
	# propagate reachability using breadth-first expansion
	var ghost_queue: Array[Vector2i] = []
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		
		for root: Vector2i in _reach_scores_by_cell[cell]:
			var reach_score: int = _reach_scores_by_cell[cell][root]
			if reach_score <= 1:
				if not cell in ghost_queue:
					ghost_queue.append(cell)
				continue
			for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
				var neighbor: Vector2i = cell + neighbor_dir
				if not visitable.has(neighbor):
					continue
				if _reach_scores_by_cell.has(neighbor):
					if _adjacent_clues_by_cell.get(neighbor, 0) >= 1:
						# cell is adjacent to an island, so only one island can reach it
						continue
					if _reach_scores_by_cell[neighbor].get(root, 0) >= reach_score - 1:
						# can already reach island
						continue
				if board.get_cell(neighbor) == CELL_EMPTY \
						and board.get_island_chain_map().causes_chain_conflict(board.get_island_for_cell(root), neighbor):
					_cycles_by_cell[neighbor] = true
					continue
				
				_reach_scores_by_cell[neighbor][root] = reach_score - 1
				if not neighbor in queue:
					queue.append(neighbor)
	
	# propagate reachability further, to find nearest clued island cells for exhausted islands
	while not ghost_queue.is_empty():
		var cell: Vector2i = ghost_queue.pop_front()
		var root: Vector2i = _reach_scores_by_cell[cell].keys().front()
		var reach_score: int = _reach_scores_by_cell[cell][root]
		for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not visitable.has(neighbor):
				continue
			if not _reach_scores_by_cell[neighbor].is_empty():
				continue
			_reach_scores_by_cell[neighbor][root] = reach_score - 1
			if not neighbor in ghost_queue:
				ghost_queue.append(neighbor)
