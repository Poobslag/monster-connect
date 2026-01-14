class_name GeneratorUtils

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND
const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS

static func best_clue_cells_for_unclued_island(board: SolverBoard, island: CellGroup) -> Array[Vector2i]:
	var nearest_clue_distance_map: Dictionary[Vector2i, int] = generate_nearest_clue_distance_map(board)
	
	# sort island cells by nearest clue distance
	var island_cells_wrapped: Array[Dictionary] = []
	for island_cell: Vector2i in island.cells:
		var island_cell_wrapped: Dictionary[String, Variant] = {
			"cell": island_cell,
			"distance": nearest_clue_distance_map.get(island_cell, 999999)}
		island_cells_wrapped.append(island_cell_wrapped)
	island_cells_wrapped.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
		return a["distance"] < b["distance"])
	
	# select island cells with the minimum clue distance
	var best_clue_cells_wrapped: Array[Dictionary] = \
			island_cells_wrapped.filter(func(a: Dictionary[String, Variant]) -> bool:
				return a["distance"] == island_cells_wrapped[0]["distance"])
	var best_clue_cells: Array[Vector2i] = []
	for best_clue_cell_wrapped: Dictionary[String, Variant] in best_clue_cells_wrapped:
		best_clue_cells.append(best_clue_cell_wrapped["cell"])
	
	return best_clue_cells


static func generate_nearest_clue_distance_map(board: SolverBoard) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	
	# initialize BFS from clues (distance 0)
	var queue: Array[Vector2i] = []
	for clue: Vector2i in board.clues:
		result[clue] = 0
		queue.push_back(clue)
	
	# expand BFS to compute nearest-clue distance
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + dir
			if neighbor in result:
				continue
			if board.get_cell(neighbor) != CELL_INVALID:
				result[neighbor] = result[cell] + 1
				queue.push_back(neighbor)
	
	return result
