class_name FastBoard

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var cells: Dictionary[Vector2i, String]

var _cache: Dictionary[String, Variant] = {}

func from_game_board(game_board: NurikabeGameBoard) -> void:
	for cell_pos in game_board.get_used_cells():
		set_cell_string(cell_pos, game_board.get_cell_string(cell_pos))


func get_cell_string(cell_pos: Vector2i) -> String:
	return cells.get(cell_pos, CELL_INVALID)


## Returns the clue value for the specified group of cells.[br]
## [br]
## If zero clues or multiple clues are present, returns 0.
func get_clue_value(group: Array[Vector2i]) -> int:
	return _get_cached(
		"clue_value %s" % ["-" if group.is_empty() else str(group[0])],
		_build_clue_value.bind(group))


func get_filled_cell_count() -> int:
	return _get_cached("filled_cell_count", func() -> int:
		var result: int = 0
		for cell: Vector2i in cells:
			if cells[cell] in [CELL_ISLAND, CELL_WALL]:
				result += 1
		return result)


func get_liberties(group: Array[Vector2i]) -> Array[Vector2i]:
	return _get_cached(
		"liberties %s" % ["-" if group.is_empty() else str(group[0])],
		_build_liberties.bind(group))


func get_neighbors(cell_pos: Vector2i) -> Array[Vector2i]:
	return [cell_pos + Vector2i.UP, cell_pos + Vector2i.DOWN, cell_pos + Vector2i.LEFT, cell_pos + Vector2i.RIGHT]


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	_cache.clear()
	cells[cell_pos] = value


func get_smallest_island_groups() -> Array[Array]:
	return _get_cached(
		"smallest_island_groups",
		_build_smallest_island_groups)


## Sets the specified cells on the model.[br]
## [br]
## Accepts a dictionary with the following keys:[br]
## 	'pos': (Vector2i) The cell to update.[br]
## 	'value': (String) The value to assign.[br]
func set_cell_strings(changes: Array[Dictionary]) -> void:
	for change: Dictionary in changes:
		set_cell_string(change["pos"], change["value"])


func print_cells() -> void:
	if cells.is_empty():
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


func _build_clue_value(group: Array[Vector2i]) -> int:
	var result: int = 0
	for cell: Vector2i in group:
		if cells[cell].is_valid_int():
			if result > 0:
				# too many clues
				result = 0
				break
			result = cells[cell].to_int()
	return result


func _build_liberties(group: Array[Vector2i]) -> Array[Vector2i]:
	var group_cell_set: Dictionary[Vector2i, bool] = {}
	var liberty_cell_set: Dictionary[Vector2i, bool] = {}
	for group_cell: Vector2i in group:
		group_cell_set[group_cell] = true
	for group_cell: Vector2i in group:
		for neighbor_cell: Vector2i in get_neighbors(group_cell):
			if neighbor_cell in group_cell_set:
				continue
			if get_cell_string(neighbor_cell) != CELL_EMPTY:
				continue
			liberty_cell_set[neighbor_cell] = true
	return liberty_cell_set.keys()


func _build_smallest_island_groups() -> Array[Array]:
	return _find_groups(func(value: String) -> bool:
		return value.is_valid_int() or value == CELL_ISLAND)


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


func _get_cached(cache_key: String, builder: Callable) -> Variant:
	if not _cache.has(cache_key):
		_cache[cache_key] = builder.call()
	return _cache[cache_key]
