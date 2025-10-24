class_name NurikabeBoardModel

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var cells: Dictionary[Vector2i, String]


func duplicate() -> NurikabeBoardModel:
	var copy: NurikabeBoardModel = NurikabeBoardModel.new()
	copy.cells = cells.duplicate()
	return copy


func from_game_board(game_board: NurikabeGameBoard) -> void:
	for cell_pos in game_board.get_used_cells():
		set_cell_string(cell_pos, game_board.get_cell_string(cell_pos))


func get_cell_string(cell_pos: Vector2i) -> String:
	return cells.get(cell_pos, CELL_INVALID)


func get_neighbors(cell_pos: Vector2i) -> Array[Vector2i]:
	return [cell_pos + Vector2i.UP, cell_pos + Vector2i.DOWN, cell_pos + Vector2i.LEFT, cell_pos + Vector2i.RIGHT]


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	cells[cell_pos] = value


## Sets the specified cells on the game board model.[br]
## [br]
## Accepts a dictionary with the following keys:[br]
## 	'pos': (Vector2i) The cell to update.[br]
## 	'value': (String) The value to assign.[br]
func set_cell_strings(changes: Array[Dictionary]) -> void:
	for change: Dictionary in changes:
		set_cell_string(change["pos"], change["value"])


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
		
		for neighbor_cell: Vector2i in get_neighbors(next_cell):
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
				changes.append({"pos": ignored_cell, "value": CELL_WALL} as Dictionary[String, Variant])
	
	return changes


func validate() -> ValidationResult:
	var result: ValidationResult = ValidationResult.new()
	var island_groups: Array[Array] = find_largest_island_groups()
	var wall_groups: Array[Array] = find_smallest_wall_groups()
	var potential_wall_groups: Array[Array] = find_largest_wall_groups()
	var potential_island_groups: Array[Array] = find_smallest_island_groups()
	_check_clues(result, island_groups, potential_island_groups)
	_check_pools(result)
	_check_split_walls(result, wall_groups, potential_wall_groups)
	
	return result


## Returns the largest possible groups of island cells, including all empty cells.
func find_largest_island_groups() -> Array[Array]:
	return _find_groups(func(value: String) -> bool:
		return value.is_valid_int() or value in [CELL_EMPTY, CELL_ISLAND])


## Returns the smallest possible groups of wall cells, excluding all empty cells.
func find_smallest_wall_groups() -> Array[Array]:
	return _find_groups(func(value: String) -> bool:
		return value in [CELL_WALL])


## Returns the largest possible groups of wall cells, including all empty cells.
func find_largest_wall_groups() -> Array[Array]:
	return _find_groups(func(value: String) -> bool:
		return value in [CELL_EMPTY, CELL_WALL])


## Returns the smallest possible groups of island cells, excluding all empty cells.
func find_smallest_island_groups() -> Array[Array]:
	return _find_groups(func(value: String) -> bool:
		return value.is_valid_int() or value in [CELL_ISLAND])


func get_clue_cells(group: Array[Vector2i]) -> Array[Vector2i]:
	var clue_cells: Array[Vector2i] = []
	for cell: Vector2i in group:
		if get_cell_string(cell).is_valid_int():
			clue_cells.append(cell)
	return clue_cells


func get_clue_value(group: Array[Vector2i]) -> int:
	var clue_cells: Array[Vector2i] = get_clue_cells(group)
	return get_cell_string(clue_cells[0]).to_int() if clue_cells.size() == 1 else 0


func print_cells() -> void:
	if cells.size() == 0:
		print("(empty)")
		return
	
	var rect: Rect2i = Rect2i(cells.keys()[0].x, cells.keys()[0].y, 0, 0)
	for cell: Vector2i in cells:
		rect = rect.expand(cell)
	
	var header_line: String = "+-"
	for x: int in range(rect.position.x, rect.end.x + 1):
		header_line += "--"
	print(header_line)
	
	for y: int in range(rect.position.y, rect.end.y + 1):
		var line: String = "| "
		for x: int in range(rect.position.x, rect.end.x + 1):
			line += get_cell_string(Vector2i(x, y)).lpad(2, " ")
		print(line)


func get_pool_cells() -> Array[Vector2i]:
	var pool_cells: Dictionary[Vector2i, bool] = {}
	for next_cell: Vector2i in cells:
		if cells.get(next_cell) == CELL_WALL \
				and cells.get(next_cell + Vector2i.RIGHT) == CELL_WALL \
				and cells.get(next_cell + Vector2i.DOWN) == CELL_WALL \
				and cells.get(next_cell + Vector2i(1, 1)) == CELL_WALL:
			pool_cells[next_cell] = true
			pool_cells[next_cell + Vector2i.RIGHT] = true
			pool_cells[next_cell + Vector2i.DOWN] = true
			pool_cells[next_cell + Vector2i(1, 1)] = true
	return pool_cells.keys()


func _check_clues(result: ValidationResult, island_groups: Array[Array],
		potential_island_groups: Array[Array]) -> ValidationResult:
	for group: Array[Vector2i] in island_groups:
		var clue_cells: Array[Vector2i] = get_clue_cells(group)
		if clue_cells.size() == 0:
			result.unclued_islands.append_array(group)
		if clue_cells.size() == 1 and get_cell_string(clue_cells.front()).to_int() < group.size():
			result.wrong_size.append_array(group)
		elif clue_cells.size() == 1 and get_cell_string(clue_cells.front()).to_int() > group.size():
			# unfixable wrong size -- the group is too small even if all empty cells are islands
			result.wrong_size_unfixable.append_array(group)
		if clue_cells.size() >= 2:
			result.joined_islands.append_array(group)
	
	for group: Array[Vector2i] in potential_island_groups:
		var clue_cells: Array[Vector2i] = []
		for cell: Vector2i in group:
			if get_cell_string(cell).is_valid_int():
				clue_cells.append(cell)
		if clue_cells.size() >= 2:
			# unfixable joined islands -- they are joined even if all empty cells are walls
			result.joined_islands_unfixable.append_array(group)
			result.joined_islands.assign(Utils.subtract(result.joined_islands, group))
		if clue_cells.size() == 1 and get_cell_string(clue_cells.front()).to_int() < group.size():
			# unfixable wrong size -- the group is too big even if all empty cells are walls
			result.wrong_size_unfixable.append_array(group)
			result.wrong_size.assign(Utils.subtract(result.wrong_size, group))
	
	return result


func _check_pools(result: ValidationResult) -> ValidationResult:
	result.pools.append_array(get_pool_cells())
	return result


func _check_split_walls(result: ValidationResult, wall_groups: Array[Array],
		potential_wall_groups: Array[Array]) -> ValidationResult:
	if wall_groups.size() >= 2:
		var largest_group: Array[Vector2i] = wall_groups[0]
		for group: Array[Vector2i] in wall_groups:
			if group.size() > largest_group.size():
				largest_group = group
		for group: Array[Vector2i] in wall_groups:
			if group == largest_group:
				continue
			result.split_walls.append_array(group)
	
	var potential_wall_groups_with_a_wall: Array[Array] \
			= potential_wall_groups.filter(func(group: Array[Vector2i]) -> bool:
				for cell: Vector2i in group:
					if get_cell_string(cell) == CELL_WALL:
						return true
				return false)
	if potential_wall_groups_with_a_wall.size() >= 2:
		var largest_group: Array[Vector2i] = potential_wall_groups_with_a_wall[0]
		for group: Array[Vector2i] in potential_wall_groups_with_a_wall:
			if group.size() > largest_group.size():
				largest_group = group
		for group: Array[Vector2i] in potential_wall_groups_with_a_wall:
			if group == largest_group:
				continue
			var unfixable_wall_cells: Array[Vector2i] = group.filter(func(cell: Vector2i) -> bool:
				return get_cell_string(cell) == CELL_WALL)
			result.split_walls_unfixable.append_array(unfixable_wall_cells)
			result.split_walls.assign(Utils.subtract(result.split_walls, unfixable_wall_cells))
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
			groups.append([] as Array[Vector2i])
		else:
			# pop the next cell from the queue
			next_cell = queue.pop_front()
		
		# append the next cell to this group
		groups.back().append(next_cell)
		
		# recurse to neighboring cells
		for neighbor_cell: Vector2i in get_neighbors(next_cell):
			if neighbor_cell in remaining_cells:
				queue.push_back(neighbor_cell)
				remaining_cells.erase(neighbor_cell)
	
	return groups


class ValidationResult:
	var joined_islands: Array[Vector2i] = []
	var joined_islands_unfixable: Array[Vector2i] = []
	var pools: Array[Vector2i] = []
	var split_walls: Array[Vector2i] = []
	var split_walls_unfixable: Array[Vector2i] = []
	var unclued_islands: Array[Vector2i] = []
	var wrong_size: Array[Vector2i] = []
	var wrong_size_unfixable: Array[Vector2i] = []
	var error_count: int:
		get:
			return joined_islands.size() + joined_islands_unfixable.size() \
					+ pools.size() + split_walls.size() + split_walls_unfixable.size() \
					+ unclued_islands.size() + wrong_size.size() + + wrong_size_unfixable.size()
	var unfixable_error_count: int:
		get:
			return joined_islands_unfixable.size() \
					+ pools.size() + split_walls_unfixable.size() \
					+ wrong_size_unfixable.size()
	
	func _to_string() -> String:
		return str({
			"joined_islands": joined_islands,
			"joined_islands_unfixable": joined_islands_unfixable,
			"pools": pools,
			"split_walls": split_walls,
			"split_walls_unfixable": split_walls_unfixable,
			"unclued_islands": unclued_islands,
			"wrong_size": wrong_size,
			"wrong_size_unfixable": wrong_size_unfixable,
		})
