class_name FastBoard

enum ClueReachability {
	UNKNOWN,
	REACHABLE,
	UNREACHABLE,
	IMPOSSIBLE,
	CONFLICT,
}

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

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
func get_clue_for_group(group: Array[Vector2i]) -> int:
	return _get_cached(
		"clue_for_group %s" % ["-" if group.is_empty() else str(group[0])],
		_build_clue_value.bind(group))


func get_clue_reachability(cell: Vector2i) -> ClueReachability:
	return get_clue_reachability_by_cell().get(cell, ClueReachability.UNKNOWN)


func get_nearest_clue_cell(cell: Vector2i) -> Vector2i:
	return get_nearest_clue_cell_by_cell().get(cell, POS_NOT_FOUND)


func get_clue_value_for_cell(cell: Vector2i) -> int:
	var group: Array[Vector2i] = get_island_group_map().groups_by_cell.get(cell, [] as Array[Vector2i])
	return get_clue_for_group(group) if group else 0


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


func get_clue_reachability_by_cell() -> Dictionary[Vector2i, ClueReachability]:
	return _get_cached(
		"clue_reachability_by_cell",
		_build_clue_reachability_by_cell)


func get_nearest_clue_cell_by_cell() -> Dictionary[Vector2i, Vector2i]:
	return _get_cached(
		"nearest_clue_cell_by_cell",
		_build_nearest_clue_cell_by_cell)


func get_reachability_map() -> Dictionary[Vector2i, Dictionary]:
	return _get_cached(
		"reachability_map",
		_build_reachability_map)


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	_cache.clear()
	cells[cell_pos] = value


func get_islands() -> Array[Array]:
	return get_island_group_map().groups


func get_islands_by_cell() -> Dictionary[Vector2i, Array]:
	return get_island_group_map().groups_by_cell


func get_island_for_cell(cell: Vector2i) -> Array[Vector2i]:
	return get_islands_by_cell().get(cell, [] as Array[Vector2i])


func get_island_roots_by_cell() -> Dictionary[Vector2i, Vector2i]:
	return get_island_group_map().roots_by_cell


func get_island_root_for_cell(cell: Vector2i) -> Vector2i:
	return get_island_roots_by_cell().get(cell, POS_NOT_FOUND)


func get_island_group_map() -> FastGroupMap:
	return _get_cached(
		"island_group_map",
		_build_island_group_map
	)


func get_walls() -> Array[Array]:
	return get_wall_group_map().groups


func get_walls_by_cell() -> Dictionary[Vector2i, Array]:
	return get_wall_group_map().groups_by_cell


func get_wall_for_cell(cell: Vector2i) -> Array[Vector2i]:
	return get_walls_by_cell().get(cell, [] as Array[Vector2i])


func get_wall_roots_by_cell() -> Dictionary[Vector2i, Vector2i]:
	return get_wall_group_map().roots_by_cell


func get_wall_root_for_cell(cell: Vector2i) -> Vector2i:
	return get_wall_roots_by_cell().get(cell, POS_NOT_FOUND)


func get_wall_group_map() -> FastGroupMap:
	return _get_cached(
		"wall_group_map",
		_build_wall_group_map
	)


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


func _build_clue_reachability() -> Dictionary[Vector2i, Dictionary]:
	var reachability_map: Dictionary[Vector2i, Dictionary] = get_reachability_map()
	return reachability_map


func _build_clue_reachability_by_cell() -> Dictionary[Vector2i, ClueReachability]:
	var reachability_by_cell: Dictionary[Vector2i, ClueReachability] = {}
	var reachability_map: Dictionary[Vector2i, Dictionary] = get_reachability_map()
	for cell: Vector2i in cells:
		var cell_info: Dictionary[String, Variant] = reachability_map.get(cell, {} as Dictionary[String, Variant])
		var reachability: ClueReachability = ClueReachability.UNKNOWN
		if cell_info.is_empty():
			reachability = ClueReachability.IMPOSSIBLE
		elif cell_info["adjacent_clues"] >= 2:
			reachability = ClueReachability.CONFLICT
		elif cell_info["cell_info"] >= 1:
			reachability = ClueReachability.REACHABLE
		else:
			reachability = ClueReachability.UNREACHABLE
		reachability_by_cell[cell] = reachability
	return reachability_by_cell


func _build_nearest_clue_cell_by_cell() -> Dictionary[Vector2i, Vector2i]:
	var nearest_clue_cell_by_cell: Dictionary[Vector2i, Vector2i] = {}
	var reachability_map: Dictionary[Vector2i, Dictionary] = get_reachability_map()
	for cell: Vector2i in reachability_map:
		nearest_clue_cell_by_cell[cell] = reachability_map[cell]["nearest_clue_root"]
	return nearest_clue_cell_by_cell


func _build_reachability_map() -> Dictionary[Vector2i, Dictionary]:
	var islands: Array[Array] = get_islands()
	var reachability_map: Dictionary[Vector2i, Dictionary] = {}
	
	var visitable: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in cells:
		if get_cell_string(cell) in [CELL_ISLAND, CELL_EMPTY] \
				and get_clue_value_for_cell(cell) == 0:
			visitable[cell] = true
	
	var queue: Array[Vector2i] = []
	for island: Array[Vector2i] in islands:
		var clue_value: int = get_clue_for_group(island)
		if clue_value == 0:
			continue
		var cell_info: int = clue_value - island.size()
		for liberty: Vector2i in get_liberties(island):
			if reachability_map.has(liberty):
				# cell is adjacent to two or more islands, so no islands can reach it
				reachability_map[liberty]["cell_info"] = 0
				reachability_map[liberty]["adjacent_clues"] += 1
				continue
			
			reachability_map[liberty] = {
				"cell_info": cell_info,
				"nearest_clue_root": island.front(),
				"adjacent_clues": 1,
			} as Dictionary[String, Variant]
			queue.append(liberty)
	
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var cell_info: Dictionary[String, Variant] = reachability_map[cell]
		
		for neighbor: Vector2i in get_neighbors(cell):
			if not visitable.has(neighbor):
				continue
			if reachability_map.has(neighbor):
				var neighbor_cell_info: Dictionary[String, Variant] = reachability_map[neighbor]
				if neighbor_cell_info["adjacent_clues"] >= 1:
					# cell is adjacent to an island, so only one island can reach it
					continue
				if neighbor_cell_info["cell_info"] >= cell_info["cell_info"] - 1:
					# cell is closer to another island
					continue
			
			reachability_map[neighbor] = {
				"cell_info": cell_info["cell_info"] - 1,
				"nearest_clue_root": cell_info["nearest_clue_root"],
				"adjacent_clues": 0,
			} as Dictionary[String, Variant]
			queue.append(neighbor)
	
	return reachability_map


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


func _build_island_group_map() -> FastGroupMap:
	return FastGroupMap.new(self, func(value: String) -> bool:
		return value.is_valid_int() or value == CELL_ISLAND)


func _build_wall_group_map() -> FastGroupMap:
	return FastGroupMap.new(self, func(value: String) -> bool:
		return value == CELL_WALL)


func _get_cached(cache_key: String, builder: Callable) -> Variant:
	if not _cache.has(cache_key):
		_cache[cache_key] = builder.call()
	return _cache[cache_key]
