class_name MutationLibrary

enum IslandSplitType {
	HORIZONTAL,
	VERTICAL,
	CELL,
}

const SPLIT_HORIZONTAL: IslandSplitType = IslandSplitType.HORIZONTAL
const SPLIT_VERTICAL: IslandSplitType = IslandSplitType.VERTICAL
const SPLIT_CELL: IslandSplitType = IslandSplitType.CELL

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND
const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS
const ADJACENT_DIRS: Array[Vector2i] = NurikabeUtils.ADJACENT_DIRS

var rng: RandomNumberGenerator = RandomNumberGenerator.new():
	set(value):
		rng = value
		_rng_ops.rng = rng
var _rng_ops: RngOps = RngOps.new(rng)

## Removes a random group of wall cells from a closed wall loop.
func mutate_break_wall_loop(board: SolverBoard) -> bool:
	var cuttable_loop_cells: Array[Vector2i] = find_cuttable_loop_cells(board)
	if cuttable_loop_cells:
		var cuttable_loop_cell: Vector2i = _rng_ops.pick_random(cuttable_loop_cells)
		carve_wall_cells(board, cuttable_loop_cell)
	return not cuttable_loop_cells.is_empty()


## Moves a clue elsewhere within the same island.
func mutate_move_clue(board: SolverBoard) -> bool:
	var island_candidates: Array[CellGroup] = board.islands.filter(func(island: CellGroup) -> bool:
		return island.clue >= 2 and island.size() >= 2)
	if island_candidates.is_empty():
		return false
	
	var chosen_island: CellGroup = _rng_ops.pick_random(island_candidates)
	move_clue(board, chosen_island)
	return true


## Randomly adjust clue numbers for two neighboring islands, ignoring geometry.
func mutate_rebalance_neighbor_islands(board: SolverBoard) -> bool:
	var pairs: Array[CellGroup] = _find_rebalanceable_island_pair(board)
	if pairs.is_empty():
		return false
	
	if pairs[0].clue == 1:
		var tmp: CellGroup = pairs[0]
		pairs[0] = pairs[1]
		pairs[1] = tmp
	
	var total_clue: int = pairs[0].clue + pairs[1].clue
	var new_clue_0: int = rng.randi_range(1, pairs[0].clue - 1)
	var new_clue_1: int = total_clue - new_clue_0
	
	board.set_clue(board.find_clue_cell(pairs[0]), new_clue_0)
	board.set_clue(board.find_clue_cell(pairs[1]), new_clue_1)
	return true


## Finds a dead end on the wall and shrinks it, possibly merging islands.
func mutate_shrink_dead_end_wall(board: SolverBoard) -> bool:
	var dead_end_walls: Array[Vector2i] = find_dead_end_walls(board)
	if dead_end_walls:
		var dead_end_wall: Vector2i = _rng_ops.pick_random(dead_end_walls)
		carve_wall_cells(board, dead_end_wall)
	return not dead_end_walls.is_empty()


## Adds a random wall splitting a clue.
func mutate_split_island(board: SolverBoard) -> bool:
	var island: CellGroup = _find_splittable_island(board)
	if not island:
		return false
	
	var split_options: Array[IslandSplit] = get_possible_island_splits(island)
	if not split_options:
		return false
	
	var split: IslandSplit = _rng_ops.pick_random(split_options)
	split_island(board, island, split)
	return true


## Removes walls enclosed within an island. These are not errors, but cannot be deduced.
func mutate_fix_enclosed_walls(board: SolverBoard) -> bool:
	var queue: Array[Vector2i] = []
	var touched_clue_cells: Dictionary[Vector2i, bool] = {}
	for wall: CellGroup in board.walls:
		for cell: Vector2i in wall.cells:
			_consider_enclosed_wall(board, cell, queue, touched_clue_cells)
	
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		board.set_cell(cell, CELL_ISLAND)
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			_consider_enclosed_wall(board, neighbor, queue, touched_clue_cells)
	
	for touched_clue_cell: Vector2i in touched_clue_cells:
		board.set_clue(touched_clue_cell, board.get_island_for_cell(touched_clue_cell).size())
	
	return not touched_clue_cells.is_empty()


## Merges two joined clues into one.
func mutate_fix_joined_islands(board: SolverBoard) -> bool:
	var did_mutate: bool = false
	for island: CellGroup in board.islands:
		if island.clue != -1:
			continue
		fix_joined_island(board, island)
		did_mutate = true
	return did_mutate


## Deletes a pool cell, and possibly a cell next to it too.
func mutate_fix_pools(board: SolverBoard) -> bool:
	var validation_result: SolverBoard.ValidationResult \
			= board.validate(SolverBoard.VALIDATE_SIMPLE)
	if validation_result.pools.is_empty():
		return false
	
	var pool_cell: Vector2i = _rng_ops.pick_random(validation_result.pools)
	
	# erase the pool cell
	board.set_cell(pool_cell, CELL_ISLAND)
	
	if rng.randf() < 0.5:
		# also erase a neighboring wall cell
		var neighbor_dirs: Array[Vector2i] = NEIGHBOR_DIRS.duplicate()
		_rng_ops.shuffle(neighbor_dirs)
		for neighbor_dir: Vector2i in neighbor_dirs:
			var neighbor: Vector2i = pool_cell + neighbor_dir
			if board.get_cell(neighbor) == CELL_WALL:
				board.set_cell(neighbor, CELL_ISLAND)
			break
	
	var island: CellGroup = board.get_island_for_cell(pool_cell)
	_renumber_island(board, island)
	return true


## Adds a wall to join two split walls.
func mutate_fix_split_walls(board: SolverBoard) -> bool:
	var did_mutate: bool = false
	for _mercy in 10:
		if board.walls.size() < 2:
			break
		
		var walls_shuffled: Array[CellGroup] = board.walls.duplicate()
		_rng_ops.shuffle(walls_shuffled)
		var join_path: Array[Vector2i] = _find_join_path(board, walls_shuffled[0])
		for join_cell: Vector2i in join_path:
			board.set_cell(join_cell, CELL_WALL)
			did_mutate = true
		_renumber_all_islands(board)
	return did_mutate


## Adds a missing clue to an unclued island.
func mutate_fix_unclued_islands_clue(board: SolverBoard) -> bool:
	var validation_result: SolverBoard.ValidationResult \
			= board.validate(SolverBoard.VALIDATE_SIMPLE)
	if validation_result.unclued_islands.is_empty():
		return false
	
	var unclued_islands: Array[CellGroup] = _find_unclued_islands(board)
	for island: CellGroup in unclued_islands:
		_renumber_island(board, island)
	return true


## Joins an unclued island to a neighboring island.
func mutate_fix_unclued_islands_join(board: SolverBoard) -> bool:
	var did_mutate: bool = false
	var validation_result: SolverBoard.ValidationResult \
			= board.validate(SolverBoard.VALIDATE_SIMPLE)
	if validation_result.unclued_islands.is_empty():
		return did_mutate
	
	var unclued_islands: Array[CellGroup] = _find_unclued_islands(board)
	for island: CellGroup in unclued_islands:
		if _join_unclued_island(board, island):
			did_mutate = true
	return did_mutate


## Renumbers all clues to match the island size.
func mutate_fix_wrong_size(board: SolverBoard) -> bool:
	var did_mutate: bool = false
	for island: CellGroup in board.islands:
		if island.clue > 0 and island.clue != island.size():
			_renumber_island(board, island)
			did_mutate = true
	return did_mutate


func mutate_force_exaggerate(board: SolverBoard) -> bool:
	var island_candidates: Array[CellGroup] = board.islands.filter(func(island: CellGroup) -> bool:
		return island.clue > 0 and not island.liberties.is_empty())
	if island_candidates.is_empty():
		return false
	
	var new_clue_value: int = 99
	var chosen_island: CellGroup = _rng_ops.pick_random(island_candidates)
	var old_clue_cell: Vector2i = board.find_clue_cell(chosen_island)
	if island_candidates.size() == 1:
		var reachable_cells: Array[Vector2i] \
				= board.perform_bfs(chosen_island.cells, func(cell: Vector2i) -> bool:
			var cell_value: int = board.get_cell(cell)
			return (cell_value == CELL_EMPTY or cell_value == CELL_ISLAND))
		new_clue_value = reachable_cells.size()
	board.set_clue(old_clue_cell, new_clue_value)
	return true


func mutate_force_inject(board: SolverBoard) -> bool:
	var did_mutate: bool = false
	var nearest_clue_distance_map: Dictionary[Vector2i, int] = \
			GeneratorUtils.generate_nearest_clue_distance_map(board)
	var island_liberties: Dictionary[Vector2i, bool] = {}
	for island: CellGroup in board.islands:
		for liberty: Vector2i in island.liberties:
			island_liberties[liberty] = true
	var clue_candidates: Array[Vector2i] = board.empty_cells.keys()
	clue_candidates = clue_candidates.filter(func(empty_cell: Vector2i) -> bool:
		return not island_liberties.has(empty_cell))
	
	if not clue_candidates.is_empty():
		clue_candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return nearest_clue_distance_map[a] > nearest_clue_distance_map[b])
		@warning_ignore("integer_division")
		var clue_cell: Vector2i = clue_candidates[rng.randi_range(0, clue_candidates.size() / 10)]
		board.set_clue(clue_cell, 99)
		did_mutate = true
	return did_mutate


func mutate_force_partition(board: SolverBoard) -> bool:
	var did_mutate: bool = false
	for island: CellGroup in board.islands:
		for liberty: Vector2i in island.liberties.duplicate():
			board.set_cell(liberty, CELL_WALL)
			did_mutate = true
	
	for empty_cell: Vector2i in board.empty_cells.duplicate():
		board.set_cell(empty_cell, CELL_ISLAND)
		did_mutate = true
	
	if _renumber_all_islands(board):
		did_mutate = true
	
	return did_mutate


func fix_joined_island(board: SolverBoard, island: CellGroup) -> void:
	if island.clue != -1:
		return
	
	# erase all clues
	var old_clue_cells: Array[Vector2i] = []
	for cell: Vector2i in island.cells:
		if board.has_clue(cell):
			old_clue_cells.append(cell)
			board.set_clue(cell, 0)
	
	# decide best clue to keep
	var nearest_clue_distance_map: Dictionary[Vector2i, int] = \
			GeneratorUtils.generate_nearest_clue_distance_map(board)
	var clue_cells_wrapped: Array[Dictionary] = []
	for old_clue_cell: Vector2i in old_clue_cells:
		var clue_cell_wrapped: Dictionary[String, Variant] = {
			"cell": old_clue_cell,
			"distance": nearest_clue_distance_map.get(old_clue_cell, 999999)}
		clue_cells_wrapped.append(clue_cell_wrapped)
	_rng_ops.shuffle(clue_cells_wrapped)
	clue_cells_wrapped.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
		return a["distance"] < b["distance"])
	
	# reassign the best clue
	board.set_clue(clue_cells_wrapped[0]["cell"], island.size())


func carve_wall_cells(board: SolverBoard, wall_cell: Vector2i) -> void:
	board.set_cell(wall_cell, CELL_ISLAND)
	fix_joined_island(board, board.get_island_for_cell(wall_cell))
	mutate_fix_enclosed_walls(board)


## Finds wall cells that are part of simple loops (degree==2 before and after pruning)
func find_cuttable_loop_cells(board: SolverBoard) -> Array[Vector2i]:
	var degree: Dictionary[Vector2i, int] = {}
	for wall: CellGroup in board.walls:
		for cell: Vector2i in wall.cells:
			degree[cell] = 0
	for cell: Vector2i in degree:
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if degree.has(neighbor):
				degree[cell] += 1
	var initial_degree: Dictionary[Vector2i, int] = degree.duplicate()
	
	var queue: Array[Vector2i] = []
	for cell: Vector2i in degree.keys():
		if degree[cell] == 1:
			queue.append(cell)
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		degree.erase(cell)
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not degree.has(neighbor):
				continue
			degree[neighbor] -= 1
			if degree[neighbor] <= 1 and not queue.has(neighbor):
				queue.append(neighbor)
	
	var result: Array[Vector2i] = degree.keys().filter(func(cell: Vector2i) -> bool:
		return initial_degree[cell] == 2)
	return result


func find_dead_end_walls(board: SolverBoard) -> Array[Vector2i]:
	var dead_end_walls: Array[Vector2i] = []
	for wall: CellGroup in board.walls:
		for cell: Vector2i in wall.cells:
			var neighbor_wall_count: int = 0
			for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
				var neighbor: Vector2i = cell + neighbor_dir
				if board.get_cell(neighbor) == CELL_WALL:
					neighbor_wall_count += 1
					if neighbor_wall_count >= 2:
						break
			if neighbor_wall_count >= 2:
				continue
			dead_end_walls.append(cell)
	return dead_end_walls


func get_possible_island_splits(island: CellGroup) -> Array[IslandSplit]:
	var island_splits: Array[IslandSplit] = []
	var bounds: Rect2i = Rect2i(island.cells[0], Vector2i(0, 0))
	for cell: Vector2i in island.cells:
		bounds = bounds.expand(cell)
	for x in range(bounds.position.x + 1, bounds.position.x + bounds.size.x):
		island_splits.append(IslandSplit.new(SPLIT_VERTICAL, Vector2i(x, 0)))
	for y in range(bounds.position.y + 1, bounds.position.y + bounds.size.y):
		island_splits.append(IslandSplit.new(SPLIT_HORIZONTAL, Vector2i(0, y)))
	var chokepoint_map: ChokepointMap = ChokepointMap.new(island.cells)
	var chokepoints: Array[Vector2i] = chokepoint_map.chokepoints_by_cell.keys()
	for chokepoint: Vector2i in chokepoints:
		island_splits.append(IslandSplit.new(SPLIT_CELL, chokepoint))
	return island_splits


func move_clue(board: SolverBoard, island: CellGroup) -> void:
	# erase the old clue
	var old_clue_cell: Vector2i = board.find_clue_cell(island)
	board.set_clue(board.find_clue_cell(island), 0)
	
	# calculate the new clue position
	var nearest_clue_distance_map: Dictionary[Vector2i, int] = \
			GeneratorUtils.generate_nearest_clue_distance_map(board)
	var cell_candidates: Array[Vector2i] = island.cells.duplicate()
	cell_candidates.erase(old_clue_cell)
	var weights: Array[float] = []
	weights.resize(cell_candidates.size())
	for i in cell_candidates.size():
		weights[i] = 1.0 / nearest_clue_distance_map.get(cell_candidates[i], 999999)
	var new_clue_cell: Vector2i = cell_candidates[rng.rand_weighted(weights)]
	
	# set the new clue
	board.set_clue(new_clue_cell, island.size())


func split_island(board: SolverBoard, island: CellGroup, split: IslandSplit) -> void:
	match split.type:
		SPLIT_CELL:
			board.set_cell(split.cell, CELL_WALL)
		SPLIT_HORIZONTAL:
			for cell: Vector2i in island.cells:
				if cell.y == split.cell.y:
					board.set_cell(cell, CELL_WALL)
		SPLIT_VERTICAL:
			for cell: Vector2i in island.cells:
				if cell.x == split.cell.x:
					board.set_cell(cell, CELL_WALL)
	
	var visited: Dictionary[CellGroup, bool] = {}
	for cell: Vector2i in island.cells:
		if board.get_cell(cell) != CELL_ISLAND:
			continue
		var new_island: CellGroup = board.get_island_for_cell(cell)
		if visited.has(new_island):
			continue
		visited[new_island] = true
		_renumber_island(board, new_island)


func _consider_enclosed_wall(
		board: SolverBoard, cell: Vector2i,
		queue: Array[Vector2i], touched_clue_cells: Dictionary[Vector2i, bool]) -> void:
	if board.get_cell(cell) != CELL_WALL:
		return
	
	# assign 'enclosing_island' if the wall is surrounded by only one island
	var enclosing_island: CellGroup = null
	for adjacent_dir: Vector2i in ADJACENT_DIRS:
		var adjacent_cell: Vector2i = cell + adjacent_dir
		if board.get_cell(adjacent_cell) != CELL_ISLAND:
			continue
		var island: CellGroup = board.get_island_for_cell(adjacent_cell)
		if enclosing_island == null:
			# first discovered island neighbor
			enclosing_island = island
			continue
		if enclosing_island != island:
			# found two island neighbors; the wall is not enclosed
			enclosing_island = null
			break
	
	# unassign 'enclosing_island' if the wall touches a wall or border on three sides
	if enclosing_island:
		var non_island_neighbors: int = 0
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor_cell: Vector2i = cell + neighbor_dir
			if board.get_cell(neighbor_cell) == CELL_ISLAND:
				continue
			non_island_neighbors += 1
			if non_island_neighbors >= 3:
				enclosing_island = null
				break
	
	# enqueue the enclosed island
	if enclosing_island:
		queue.push_back(cell)
		var clue_cell: Vector2i = board.find_clue_cell(enclosing_island)
		if clue_cell != POS_NOT_FOUND:
			touched_clue_cells[clue_cell] = true


func _find_join_path(board: SolverBoard, start_wall: CellGroup) -> Array[Vector2i]:
	# initialize bfs from start wall
	var visited: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in start_wall.cells:
		visited[cell] = true
	var queue: Array[Vector2i] = []
	queue.append_array(start_wall.cells)
	_rng_ops.shuffle(queue)
	var distance: Dictionary[Vector2i, int] = {}
	for cell: Vector2i in start_wall.cells:
		distance[cell] = 0
	var bfs_dirs: Array[Vector2i] = NEIGHBOR_DIRS.duplicate()
	_rng_ops.shuffle(bfs_dirs)
	
	# bfs through island cells until another wall is reached
	var join_path: Array[Vector2i] = []
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for neighbor_dir: Vector2i in bfs_dirs:
			var neighbor: Vector2i = cell + neighbor_dir
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			var neighbor_value: int = board.get_cell(neighbor)
			if neighbor_value == CELL_WALL:
				join_path.append(cell)
				break
			elif neighbor_value == CELL_ISLAND:
				queue.push_back(neighbor)
				distance[neighbor] = distance[cell] + 1
		if not join_path.is_empty():
			break
	
	# walk back through BFS distance gradient to reconstruct path
	if not join_path.is_empty():
		var cell: Vector2i = join_path.back()
		for target_distance in range(distance[cell] - 1, 1, -1):
			for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
				var neighbor: Vector2i = cell + neighbor_dir
				if distance.get(neighbor, 999999) != target_distance:
					continue
				join_path.append(neighbor)
				cell = join_path.back()
				break
	
	return join_path


func _find_neighbor_islands(board: SolverBoard, cell: Vector2i) -> Array[CellGroup]:
	var result: Array[CellGroup] = []
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if board.get_cell(neighbor) != CELL_ISLAND:
			continue
		var island: CellGroup = board.get_island_for_cell(neighbor)
		if not island in result:
			result.append(island)
	return result


## Finds a pair of nearby islands with clues which sum to >= 3.
func _find_rebalanceable_island_pair(board: SolverBoard) -> Array[CellGroup]:
	var result: Array[CellGroup] = []
	if not board.walls:
		return result
	
	for _mercy in 10:
		var wall: CellGroup = _rng_ops.pick_random(board.walls)
		var cell: Vector2i = _rng_ops.pick_random(wall.cells)
		var nearby_islands_set: Dictionary[CellGroup, bool] = {}
		for adjacent_dir: Vector2i in ADJACENT_DIRS:
			var adjacent_cell: Vector2i = cell + adjacent_dir
			if board.get_cell(adjacent_cell) == CELL_ISLAND:
				nearby_islands_set[board.get_island_for_cell(adjacent_cell)] = true
		var nearby_islands: Array[CellGroup] = nearby_islands_set.keys()
		_rng_ops.shuffle(nearby_islands)
		if nearby_islands.size() < 2:
			continue
		if nearby_islands[0].clue < 1:
			continue
		if nearby_islands[1].clue < 1:
			continue
		if nearby_islands[0].clue + nearby_islands[1].clue < 3:
			continue
		result = [nearby_islands[0], nearby_islands[1]]
		break
	
	return result


func _find_splittable_island(board: SolverBoard) -> CellGroup:
	var splittable_islands: Array[CellGroup] = board.islands.duplicate()
	splittable_islands = splittable_islands.filter(func(island: CellGroup) -> bool:
		return island.size() >= 3)
	var weights: Array[float] = []
	weights.resize(splittable_islands.size())
	for i in splittable_islands.size():
		weights[i] = float(splittable_islands[i].size())
	var chosen_island: CellGroup
	if splittable_islands:
		chosen_island = splittable_islands[rng.rand_weighted(weights)]
	return chosen_island


func _find_unclued_islands(board: SolverBoard) -> Array[CellGroup]:
	var validation_result: SolverBoard.ValidationResult \
			= board.validate(SolverBoard.VALIDATE_SIMPLE)
	var visited: Dictionary[CellGroup, bool] = {}
	for cell: Vector2i in validation_result.unclued_islands:
		var island: CellGroup = board.get_island_for_cell(cell)
		visited[island] = true
	return visited.keys()


func _join_unclued_island(board: SolverBoard, island: CellGroup) -> bool:
	var did_mutate: bool = false
	
	var island_joiners: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in island.cells:
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if _is_wall_bordering_clued_island(board, neighbor):
				island_joiners[neighbor] = true
	
	if not island_joiners.is_empty():
		var island_joiner: Vector2i = _rng_ops.pick_random(island_joiners.keys())
		board.set_cell(island_joiner, CELL_ISLAND)
		mutate_fix_enclosed_walls(board)
		did_mutate = true
	
	return did_mutate


func _is_wall_bordering_clued_island(board: SolverBoard, cell: Vector2i) -> bool:
	var result: bool = false
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if board.get_cell(neighbor) != CELL_ISLAND:
			continue
		var island: CellGroup = board.get_island_for_cell(neighbor)
		if island.clue == 0:
			continue
		result = true
		break
	return result


func _renumber_all_islands(board: SolverBoard) -> bool:
	var did_mutate: bool = false
	for island: CellGroup in board.islands:
		if _renumber_island(board, island):
			did_mutate = true
	return did_mutate


func _renumber_island(board: SolverBoard, island: CellGroup) -> bool:
	if island.clue == island.size():
		return false
	
	var clue_cell: Vector2i = POS_NOT_FOUND
	if island.clue > 0:
		clue_cell = board.find_clue_cell(island)
	if clue_cell == POS_NOT_FOUND:
		var clue_cells: Array[Vector2i] = GeneratorUtils.best_clue_cells_for_unclued_island(board, island)
		clue_cell = _rng_ops.pick_random(clue_cells)
	board.set_clue(clue_cell, island.size())
	return true


class IslandSplit:
	var type: IslandSplitType
	var cell: Vector2i
	
	func _init(init_type: IslandSplitType, init_cell: Vector2i) -> void:
		type = init_type
		cell = init_cell

	func _to_string() -> String:
		return "%s %s" % [Utils.enum_to_snake_case(IslandSplitType, type), cell]
