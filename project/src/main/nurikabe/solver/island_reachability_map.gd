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

const DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var board: SolverBoard

var _adjacent_clues_by_cell: Dictionary[Vector2i, int] = {}
var _reach_scores_by_cell: Dictionary[Vector2i, Dictionary] = {}
var _cycles_by_cell: Dictionary[Vector2i, Vector2i] = {}

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
		if _cycles_by_cell.has(cell):
			reachability = ClueReachability.CHAIN_CYCLE
		else:
			reachability = ClueReachability.IMPOSSIBLE
	return reachability


func get_cycle_root(cell: Vector2i) -> Vector2i:
	return _cycles_by_cell.get(cell, POS_NOT_FOUND)


func has_exclusive_root(cell: Vector2i) -> int:
	return _reach_scores_by_cell.has(cell) \
			and _reach_scores_by_cell[cell].size() == 1 \
			and _reach_scores_by_cell[cell].values().front() >= 1


func get_exclusive_root(cell: Vector2i) -> Vector2i:
	return _reach_scores_by_cell[cell].keys().front()


## Returns the number of additional cells each clued island can still expand into, including this cell.[br]
## [br]
## A reach score of 3 means the island can reach that cell and expand twice. A reach score of 1 means the island can
## reach that cell, but cannot expand any further. A reach score of 0 or less means the island cannot reach the
## cell.[br]
## [br]
## Example: A lone 4 island can expand 3 more cells, so its immediate neighbors have a reach score of 3 and their
## neighbors have a reach score of 2.
## [codeblock]
##   (puzzle)    (reach scores)
##    . . . .     3 2 1 .
##    4 . . . ->  . 3 2 1
##   ## . . .    ## 2 1 .
##    . .####     . 1####
## [/codeblock]
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


func print_cells() -> void:
	if board.cells.is_empty():
		print("(empty)")
		return
	
	var rect: Rect2i = Rect2i(board.cells.keys()[0].x, board.cells.keys()[0].y, 0, 0)
	for cell: Vector2i in board.cells:
		rect = rect.expand(cell)
	
	var header_line: String = "+"
	for x: int in range(rect.position.x, rect.end.x + 1):
		header_line += "----"
	print(header_line)
	
	for y: int in range(rect.position.y, rect.end.y + 1):
		var line: String = ""
		for x: int in range(rect.position.x, rect.end.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			var cell_string: String = _cell_string(cell)
			line += cell_string
		print("|%s" % [line])


func print_reach_scores(root: Vector2i) -> void:
	var reach_scores: Dictionary[Vector2i, int] = {}
	for cell in _reach_scores_by_cell:
		if _reach_scores_by_cell[cell].has(root):
			reach_scores[cell] = _reach_scores_by_cell[cell][root]
	if reach_scores.is_empty():
		print("(empty)")
		return
	
	var rect: Rect2i = Rect2i(reach_scores.keys()[0].x, reach_scores.keys()[0].y, 0, 0)
	for cell: Vector2i in reach_scores:
		rect = rect.expand(cell)
	
	var header_line: String = "+"
	for x: int in range(rect.position.x, rect.end.x + 1):
		header_line += "--"
	print(header_line)
	
	for y: int in range(rect.position.y, rect.end.y + 1):
		var line: String = ""
		for x: int in range(rect.position.x, rect.end.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			var cell_string: String
			if board.get_cell(cell) == CELL_WALL:
				cell_string = NurikabeUtils.CELL_STRING_WALL
			elif reach_scores.has(cell) and reach_scores[cell] >= 1:
				cell_string = str(reach_scores[cell])
			line += cell_string.lpad(2)
		print("|%s" % [line])


func _build() -> void:
	# collect visitable cells (empty cells, or clueless islands)
	var visitable: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in board.empty_cells:
		visitable[cell] = true
		_reach_scores_by_cell[cell] = {} as Dictionary[Vector2i, int]
	
	# initialize _absorbed_islands_by_cell
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
				_reach_scores_by_cell[liberty] = {island.root: 0} as Dictionary[Vector2i, int]
				continue
			var reachability: int = island.get_remaining_capacity()
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
					_cycles_by_cell[neighbor] = root
					continue
				
				_reach_scores_by_cell[neighbor][root] = reach_score - 1
				if not neighbor in queue:
					queue.append(neighbor)
	
	# propagate reachability further, to find nearest clued island cells for exhausted islands
	while not ghost_queue.is_empty():
		var cell: Vector2i = ghost_queue.pop_front()
		var root: Vector2i = _reach_scores_by_cell[cell].keys().front()
		var reach_score: int = _reach_scores_by_cell[cell][root]
		if reach_score > 0:
			# ensure all 'ghost entries' have a negative reachability score
			reach_score -= 1000
		for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not visitable.has(neighbor):
				continue
			if not _reach_scores_by_cell[neighbor].is_empty():
				continue
			_reach_scores_by_cell[neighbor][root] = reach_score - 1
			if not neighbor in ghost_queue:
				ghost_queue.append(neighbor)


func _cell_string(cell: Vector2i) -> String:
	var result: String = ""
	if board.get_cell(cell) == CELL_WALL:
		result = NurikabeUtils.CELL_STRING_WALL
	else:
		var reach_scores: Dictionary[Vector2i, int] = _reach_scores_by_cell.get(cell, {} as Dictionary[Vector2i, int])
		for island_root: Vector2i in reach_scores:
			if reach_scores[island_root] < 1:
				continue
			var clue: int = board.get_island_for_cell(island_root).clue
			if clue >= 0 and clue < DIGITS.length():
				result += DIGITS[clue]
			else:
				result += "!"
			if result.length() >= 3:
				break
	return result.lpad(4, " ")
