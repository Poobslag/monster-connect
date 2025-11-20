class_name SolverBoard

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var cells: Dictionary[Vector2i, int]

var _cache: Dictionary[String, Variant] = {}

func perform_bfs(start_cell: Vector2i, filter: Callable) -> void:
	var visited: Dictionary[Vector2i, bool] = {start_cell: true}
	var queue: Array[Vector2i] = [start_cell]
	while not queue.is_empty():
		var next_cell: Vector2i = queue.pop_front()
		if not filter.call(next_cell):
			continue
		for neighbor: Vector2i in get_neighbors(next_cell):
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)


func duplicate() -> SolverBoard:
	var copy: SolverBoard = SolverBoard.new()
	copy.cells = cells.duplicate()
	copy._cache = _cache.duplicate()
	return copy


func from_game_board(game_board: NurikabeGameBoard) -> void:
	for cell_pos in game_board.get_used_cells():
		set_cell(cell_pos, game_board.get_cell(cell_pos))


func get_cell(cell_pos: Vector2i) -> int:
	return cells.get(cell_pos, CELL_INVALID)


## Returns the clue value for the specified group of cells.[br]
## [br]
## If zero clues are present, returns 0. If multiple clues are present, returns -1.
func get_clue_for_island(group: Array[Vector2i]) -> int:
	return 0 if group.is_empty() else get_clue_for_island_cell(group.front())


func get_island_clues() -> Dictionary[Vector2i, int]:
	return _get_cached(
		"island_clues",
		_build_island_clues)


## Returns the clue value for the specified group of cells.[br]
## [br]
## If zero clues are present, returns 0. If multiple clues are present, returns -1.
func get_clue_for_island_cell(cell: Vector2i) -> int:
	return get_island_clues().get(cell, 0)


func get_filled_cell_count() -> int:
	return _get_cached("filled_cell_count", func() -> int:
		var result: int = 0
		for cell: Vector2i in cells:
			if cells[cell] != CELL_EMPTY:
				result += 1
		return result)


func get_flooded_board() -> SolverBoard:
	return _get_cached("get_flooded_board", _build_flooded_board)


func is_filled() -> bool:
	return get_filled_cell_count() == cells.size()


func get_liberties(group: Array[Vector2i]) -> Array[Vector2i]:
	return _get_cached(
		"liberties %s" % ["-" if group.is_empty() else str(group[0])],
		_build_liberties.bind(group))


func get_neighbors(cell_pos: Vector2i) -> Array[Vector2i]:
	return [cell_pos + Vector2i.UP, cell_pos + Vector2i.DOWN, cell_pos + Vector2i.LEFT, cell_pos + Vector2i.RIGHT]


func get_global_reachability_map() -> GlobalReachabilityMap:
	return _get_cached(
		"global_reachability_map",
		_build_global_reachability_map)


func get_island_chokepoint_map() -> SolverChokepointMap:
	return _get_cached(
		"island_chokepoint_map",
		_build_island_chokepoint_map)


func get_wall_chokepoint_map() -> SolverChokepointMap:
	return _get_cached(
		"wall_chokepoint_map",
		_build_wall_chokepoint_map)


func get_per_clue_chokepoint_map() -> PerClueChokepointMap:
	return _get_cached(
		"per_clue_chokepoint_map",
		_build_per_clue_chokepoint_map)


func set_cell(cell_pos: Vector2i, value: int) -> void:
	_cache.clear()
	cells[cell_pos] = value


func get_flooded_island_group_map() -> SolverGroupMap:
	return _get_cached(
		"flooded_island_group_map",
		_build_flooded_island_group_map)


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


func get_island_group_map() -> SolverGroupMap:
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


func get_wall_group_map() -> SolverGroupMap:
	return _get_cached(
		"wall_group_map",
		_build_wall_group_map
	)


## Sets the specified cells on the model.[br]
## [br]
## Accepts a dictionary with the following keys:[br]
## 	'pos': (Vector2i) The cell to update.[br]
## 	'value': (String) The value to assign.[br]
func set_cells(changes: Array[Dictionary]) -> void:
	for change: Dictionary in changes:
		set_cell(change["pos"], change["value"])


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
			var cell_string: String = NurikabeUtils.to_cell_string(get_cell(Vector2i(x, y)))
			line += cell_string.lpad(2, " ")
		print(line)


func surround_island(cell: Vector2i) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	var island: Array[Vector2i] = get_island_for_cell(cell)
	if island.is_empty() or get_clue_for_island_cell(cell) != island.size():
		return changes
	
	var liberties: Array[Vector2i] = get_liberties(island)
	for liberty: Vector2i in liberties:
		if get_cell(liberty) == CELL_EMPTY:
			changes.append({"pos": liberty, "value": CELL_WALL})
	
	return changes


func validate() -> ValidationResult:
	return _get_cached(
		"validation_result",
		_build_validation_result)


func validate_strict() -> ValidationResult:
	return _get_cached(
		"strict_validation_result",
		_build_strict_validation_result)


func _build_flooded_board() -> SolverBoard:
	var flooded_board: SolverBoard = duplicate()
	for cell: Vector2i in flooded_board.cells:
		if flooded_board.get_cell(cell) == CELL_EMPTY:
			flooded_board.set_cell(cell, CELL_ISLAND)
	return flooded_board


func _build_global_reachability_map() -> GlobalReachabilityMap:
	return GlobalReachabilityMap.new(self)


func _build_island_clues() -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	for island: Array[Vector2i] in get_islands():
		var clue_value: int = 0
		for cell: Vector2i in island:
			var cell_value: int = cells[cell]
			if NurikabeUtils.is_clue(cell_value):
				if clue_value > 0:
					clue_value = -1
					break
				clue_value = cell_value
		if clue_value == 0:
			continue
		for cell: Vector2i in island:
			result[cell] = clue_value
	return result


func _build_liberties(group: Array[Vector2i]) -> Array[Vector2i]:
	var group_cell_set: Dictionary[Vector2i, bool] = {}
	var liberty_cell_set: Dictionary[Vector2i, bool] = {}
	for group_cell: Vector2i in group:
		group_cell_set[group_cell] = true
	for group_cell: Vector2i in group:
		for neighbor: Vector2i in get_neighbors(group_cell):
			if neighbor in group_cell_set:
				continue
			if get_cell(neighbor) != CELL_EMPTY:
				continue
			liberty_cell_set[neighbor] = true
	var result: Array[Vector2i] = liberty_cell_set.keys()
	return result


func _build_island_group_map() -> SolverGroupMap:
	var result: SolverGroupMap = SolverGroupMap.new(self, func(value: int) -> bool:
		return NurikabeUtils.is_clue(value) or value == CELL_ISLAND)
	return result


func _build_flooded_island_group_map() -> SolverGroupMap:
	return SolverGroupMap.new(self, func(value: int) -> bool:
		return NurikabeUtils.is_clue(value) or value in [CELL_EMPTY, CELL_ISLAND])


func _build_island_chokepoint_map() -> SolverChokepointMap:
	return SolverChokepointMap.new(self,
		func(cell: Vector2i) -> bool:
			var value: int = get_cell(cell)
			return NurikabeUtils.is_clue(value) or value in [CELL_EMPTY, CELL_ISLAND],
		func(cell: Vector2i) -> bool:
			return NurikabeUtils.is_clue(get_cell(cell)))


func _build_strict_validation_result() -> ValidationResult:
	return get_flooded_board().validate()


func _build_validation_result() -> ValidationResult:
	var result: ValidationResult = ValidationResult.new()
	
	# joined islands
	for island: Array[Vector2i] in get_islands():
		if get_clue_for_island(island) == -1:
			for cell: Vector2i in island:
				result.joined_islands.append(cell)
	
	# pools
	for wall: Array[Vector2i] in get_walls():
		if wall.size() < 4:
			continue
		var wall_cell_set: Dictionary[Vector2i, bool] = {}
		var pool_cell_set: Dictionary[Vector2i, bool] = {}
		for next_wall_cell: Vector2i in wall:
			wall_cell_set[next_wall_cell] = true
		for next_wall_cell: Vector2i in wall:
			if wall_cell_set.has(next_wall_cell + Vector2i(0, 1)) \
					and wall_cell_set.has(next_wall_cell + Vector2i(1, 0)) \
					and wall_cell_set.has(next_wall_cell + Vector2i(1, 1)):
				pool_cell_set[next_wall_cell] = true
				pool_cell_set[next_wall_cell + Vector2i(0, 1)] = true
				pool_cell_set[next_wall_cell + Vector2i(1, 0)] = true
				pool_cell_set[next_wall_cell + Vector2i(1, 1)] = true
		for pool_cell: Vector2i in pool_cell_set:
			result.pools.append(pool_cell)
	
	# split walls
	var wall_chokepoint_map: SolverChokepointMap = get_wall_chokepoint_map()
	if wall_chokepoint_map.get_subtree_roots().size() > 1:
		var components: Array[Dictionary] = []
		for subtree_root: Vector2i in wall_chokepoint_map.get_subtree_roots():
			var special_count: int = wall_chokepoint_map.get_component_special_count(subtree_root)
			components.append({"root": subtree_root, "special_count": special_count} as Dictionary[String, Variant])
		components.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
			return a["special_count"] > b["special_count"])
		var split_root_set: Dictionary[Vector2i, bool] = {}
		for component_index in range(1, components.size()):
			var component: Dictionary[String, Variant] = components[component_index]
			if component["special_count"] > 0:
				split_root_set[component["root"]] = true
		if not split_root_set.is_empty():
			for wall: Array[Vector2i] in get_walls():
				if split_root_set.has(wall_chokepoint_map.get_subtree_root(wall.front())):
					result.split_walls.append_array(wall)
	
	# unclued islands
	for island: Array[Vector2i] in get_islands():
		if get_liberties(island).size() == 0 and get_clue_for_island(island) == 0:
			result.unclued_islands.append_array(island)
	
	# wrong size
	for island: Array[Vector2i] in get_islands():
		var island_cell: Vector2i = island.front()
		var clue_value: int = get_clue_for_island_cell(island_cell)
		if clue_value == 0 or clue_value == -1:
			continue
		
		if clue_value < island.size():
			# island is too large
			result.wrong_size.append_array(island)
			continue
		
		var group_map: SolverGroupMap = get_flooded_island_group_map()
		var flooded_island_group: Array[Vector2i] \
				= group_map.groups_by_cell.get(island_cell, [] as Array[Vector2i])
		if clue_value > flooded_island_group.size():
			# island is too small and can't grow
			result.wrong_size.append_array(island)
			continue
	
	return result


func _build_wall_chokepoint_map() -> SolverChokepointMap:
	return SolverChokepointMap.new(self,
		func(cell: Vector2i) -> bool:
			var value: int = get_cell(cell)
			return value in [CELL_EMPTY, CELL_WALL],
		func(cell: Vector2i) -> bool:
			return get_cell(cell) == CELL_WALL)


func _build_per_clue_chokepoint_map() -> PerClueChokepointMap:
	return PerClueChokepointMap.new(self)


func _build_wall_group_map() -> SolverGroupMap:
	return SolverGroupMap.new(self, func(value: int) -> bool:
		return value == CELL_WALL)


func _get_cached(cache_key: String, builder: Callable) -> Variant:
	if not _cache.has(cache_key):
		_cache[cache_key] = builder.call()
	return _cache[cache_key]


class ValidationResult:
	var joined_islands: Array[Vector2i] = []
	var pools: Array[Vector2i] = []
	var split_walls: Array[Vector2i] = []
	var unclued_islands: Array[Vector2i] = []
	var wrong_size: Array[Vector2i] = []
	var error_count: int:
		get:
			return joined_islands.size() \
					+ pools.size() + split_walls.size() \
					+ unclued_islands.size() + wrong_size.size()
