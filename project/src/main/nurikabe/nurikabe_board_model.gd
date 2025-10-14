class_name NurikabeBoardModel

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const NEIGHBOR_DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var cells: Dictionary[Vector2i, String]

func from_game_board(game_board: NurikabeGameBoard) -> void:
	for cell_pos in game_board.get_used_cells():
		set_cell_string(cell_pos, game_board.get_cell_string(cell_pos))


func get_cell_string(cell_pos: Vector2i) -> String:
	return cells.get(cell_pos, CELL_INVALID)


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	cells[cell_pos] = value


func surround_island(cell_pos: Vector2i) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	
	var clue_cells: Dictionary[Vector2i, bool] = {}
	var island_cells: Dictionary[Vector2i, bool] = {}
	var ignored_cells: Dictionary[Vector2i, bool] = {}
	var cells_to_check: Dictionary[Vector2i, bool] = {cell_pos: true}
	while not cells_to_check.is_empty():
		var next_cell: Vector2i = cells_to_check.keys().front()
		cells_to_check.erase(next_cell)
		
		var next_cell_string: String = get_cell_string(next_cell)
		if next_cell_string == CELL_ISLAND:
			island_cells[next_cell] = true
		elif next_cell_string.is_valid_int():
			clue_cells[next_cell] = true
		else:
			ignored_cells[next_cell] = true
			continue
		
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor_cell: Vector2i = next_cell + neighbor_dir
			if ignored_cells.has(neighbor_cell) \
					or island_cells.has(neighbor_cell) \
					or clue_cells.has(neighbor_cell) \
					or cells_to_check.has(neighbor_cell) \
					or get_cell_string(neighbor_cell) == CELL_INVALID:
				continue
			cells_to_check[neighbor_cell] = true
	
	if clue_cells.size() == 1 and island_cells.size() == int(get_cell_string(clue_cells.keys().front())) - 1:
		for ignored_cell: Vector2i in ignored_cells:
			if get_cell_string(ignored_cell) == CELL_EMPTY:
				changes.append({"pos": ignored_cell, "value": CELL_WALL})
	
	return changes


func validate() -> ValidationResult:
	var result: ValidationResult = ValidationResult.new()
	var island_groups: Array[Array] = find_island_groups()
	var wall_groups: Array[Array] = find_wall_groups()
	_check_clues(result, island_groups)
	_check_pools(result)
	_check_split_walls(result, wall_groups)
	return result


func find_island_groups() -> Array[Array]:
	return _find_groups(func(value: String) -> bool:
		return value.is_valid_int() or value in [CELL_EMPTY, CELL_ISLAND])


func find_wall_groups() -> Array[Array]:
	return _find_groups(func(value: String) -> bool:
		return value in [CELL_WALL])


func _check_clues(result: ValidationResult, island_groups: Array[Array]) -> ValidationResult:
	for group: Array[Vector2i] in island_groups:
		var clue_cells: Array[Vector2i] = []
		for cell: Vector2i in group:
			if get_cell_string(cell).is_valid_int():
				clue_cells.append(cell)
		if clue_cells.size() == 0:
			result.unclued_islands.append(group.front())
		if clue_cells.size() == 1 and get_cell_string(clue_cells.front()).to_int() != group.size():
			result.wrong_size.append(clue_cells.front())
		if clue_cells.size() >= 2:
			for clue_cell: Vector2i in clue_cells:
				result.joined_islands.append(clue_cell)
	return result


func _check_pools(result: ValidationResult) -> ValidationResult:
	for next_cell: Vector2i in cells:
		if cells.get(next_cell) == CELL_WALL \
				and cells.get(next_cell + Vector2i.RIGHT) == CELL_WALL \
				and cells.get(next_cell + Vector2i.DOWN) == CELL_WALL \
				and cells.get(next_cell + Vector2i(1, 1)) == CELL_WALL:
			result.pools.append(next_cell)
	return result


func _check_split_walls(result: ValidationResult, wall_groups: Array[Array]) -> ValidationResult:
	if wall_groups.size() >= 2:
		for group: Array[Vector2i] in wall_groups:
			result.split_walls.append(group.front())
	return result


func _find_groups(filter_func: Callable) -> Array[Array]:
	var remaining_cells: Dictionary[Vector2i, bool] = {}
	for next_cell: Vector2i in cells:
		if filter_func.call(cells[next_cell]):
			remaining_cells[next_cell] = true
	
	var groups: Array[Array] = []
	var queue: Array[Vector2i] = []
	while not remaining_cells.is_empty() or not queue.is_empty():
		var next_cell: Vector2i
		if queue.is_empty():
			# start a new group
			next_cell = remaining_cells.keys().front()
			remaining_cells.erase(next_cell)
			groups.append([])
		else:
			# pop the next cell from the queue
			next_cell = queue.pop_front()
		
		# append the next cell to this group
		groups.back().append(next_cell)
		
		# recurse to neighboring cells
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor_cell: Vector2i = next_cell + neighbor_dir
			if neighbor_cell in remaining_cells:
				queue.push_back(neighbor_cell)
				remaining_cells.erase(neighbor_cell)
	
	return groups


class ValidationResult:
	var joined_islands: Array[Vector2i] = []
	var pools: Array[Vector2i] = []
	var split_walls: Array[Vector2i] = []
	var unclued_islands: Array[Vector2i] = []
	var wrong_size: Array[Vector2i] = []
	var error_count: int:
		get:
			return joined_islands.size() + pools.size() + split_walls.size() \
					+ unclued_islands.size() + wrong_size.size()
