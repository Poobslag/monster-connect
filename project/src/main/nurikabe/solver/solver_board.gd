class_name SolverBoard

enum ValidationMode {
	COMPLEX,
	SIMPLE,
	STRICT,
}

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS
const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

const VALIDATE_COMPLEX: ValidationMode = ValidationMode.COMPLEX
const VALIDATE_SIMPLE: ValidationMode = ValidationMode.SIMPLE
const VALIDATE_STRICT: ValidationMode = ValidationMode.STRICT

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var cells: Dictionary[Vector2i, int]
var version: int

var groups_by_cell: Dictionary[Vector2i, CellGroup] = {}:
	get:
		_rebuild_groups()
		return groups_by_cell
var islands: Array[CellGroup] = []:
	get:
		_rebuild_groups()
		return islands
var walls: Array[CellGroup] = []:
	get:
		_rebuild_groups()
		return walls

## Forces islands/walls to be rebuilt from scratch.[br]
## [br]
## Set to [code]true[/code] when incremental updates are too costly.
var groups_need_rebuild: bool = true

var _cache: Dictionary[String, Variant] = {}

func perform_bfs(start_cells: Array[Vector2i], filter: Callable) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var visited: Dictionary[Vector2i, bool] = {}
	for start_cell: Vector2i in start_cells:
		visited[start_cell] = true
	var queue: Array[Vector2i] = start_cells.duplicate()
	while not queue.is_empty():
		var next_cell: Vector2i = queue.pop_front()
		if not filter.call(next_cell):
			continue
		result.append(next_cell)
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = next_cell + neighbor_dir
			if not cells.has(neighbor):
				continue
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return result


func duplicate() -> SolverBoard:
	var copy: SolverBoard = SolverBoard.new()
	copy.cells = cells.duplicate()
	copy.version = version
	copy.groups_need_rebuild = groups_need_rebuild
	copy.islands.resize(islands.size())
	for i in islands.size():
		var island: CellGroup = islands[i]
		copy.islands[i] = island.duplicate()
		for cell: Vector2i in island.cells:
			copy.groups_by_cell[cell] = copy.islands[i]
	copy.walls.resize(walls.size())
	for i in walls.size():
		var wall: CellGroup = walls[i]
		copy.walls[i] = wall.duplicate()
		for cell: Vector2i in wall.cells:
			copy.groups_by_cell[cell] = copy.walls[i]
	copy._cache = _cache.duplicate()
	return copy


func from_game_board(game_board: NurikabeGameBoard) -> void:
	groups_need_rebuild = true
	var non_empty_cells: Array[Vector2i] = []
	for cell_pos: Vector2i in game_board.get_used_cells():
		var cell_value: int = game_board.get_cell(cell_pos)
		set_cell(cell_pos, game_board.get_cell(cell_pos))
		if cell_value != CELL_EMPTY:
			non_empty_cells.append(cell_pos)


func get_cell(cell_pos: Vector2i) -> int:
	return cells.get(cell_pos, CELL_INVALID)


func get_flooded_board() -> SolverBoard:
	return _get_cached("get_flooded_board", _build_flooded_board)


func is_filled() -> bool:
	return _get_cached("filled", func() -> int:
		var result: int = true
		for cell: Vector2i in cells:
			if cells[cell] == CELL_EMPTY:
				result = false
				break
		return result)


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


func get_per_clue_extent_map() -> PerClueExtentMap:
	return _get_cached(
		"per_clue_extent_map",
		_build_per_clue_extent_map)


func set_cell(cell_pos: Vector2i, value: int) -> void:
	if get_cell(cell_pos) == value:
		return
	
	if not groups_need_rebuild and get_cell(cell_pos) != CELL_EMPTY:
		push_warning("set_cell called on non-empty cell")
		groups_need_rebuild = true
	
	cells[cell_pos] = value
	
	if not groups_need_rebuild:
		match value:
			CELL_WALL:
				_expand_groups(walls, cell_pos)
				_erase_liberties(islands, cell_pos)
			CELL_ISLAND:
				_expand_groups(islands, cell_pos)
				_erase_liberties(walls, cell_pos)
			_:
				groups_need_rebuild = true
	
	_cache.clear()
	version += 1


func _expand_groups(groups: Array[CellGroup], cell: Vector2i) -> void:
	var adjacent_groups: Array[CellGroup]
	for group: CellGroup in groups:
		if group.liberties.has(cell):
			adjacent_groups.append(group)
	
	var primary_group: CellGroup
	if adjacent_groups.size() == 0:
		# 0 adjacent groups; start a new group
		primary_group = CellGroup.new()
		groups.append(primary_group)
	elif adjacent_groups.size() == 1:
		# 1 adjacent group; expand the group
		primary_group = adjacent_groups[0]
	else:
		# 2+ adjacent groups; join the groups
		primary_group = adjacent_groups[0]
		for i in range(1, adjacent_groups.size()):
			var adjacent_group: CellGroup = adjacent_groups[i]
			primary_group.merge(adjacent_group)
			groups.erase(adjacent_group)
			for group_cell: Vector2i in adjacent_group.cells:
				groups_by_cell[group_cell] = primary_group
	primary_group.cells.append(cell)
	primary_group.liberties.erase(cell)
	for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor: Vector2i = cell + neighbor_dir
		if get_cell(neighbor) == CELL_EMPTY and not primary_group.liberties.has(neighbor):
			primary_group.liberties.append(neighbor)
	groups_by_cell[cell] = primary_group


func _erase_liberties(groups: Array[CellGroup], cell: Vector2i) -> void:
	for group: CellGroup in groups:
		group.liberties.erase(cell)


func get_flooded_island_group_map() -> SolverGroupMap:
	return _get_cached(
		"flooded_island_group_map",
		_build_flooded_island_group_map)


func get_flooded_wall_group_map() -> SolverGroupMap:
	return _get_cached(
		"flooded_wall_group_map",
		_build_flooded_wall_group_map)


func get_island_for_cell(cell: Vector2i) -> CellGroup:
	return groups_by_cell.get(cell)


func get_wall_for_cell(cell: Vector2i) -> CellGroup:
	return groups_by_cell.get(cell)


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
	var island: CellGroup = get_island_for_cell(cell)
	if not island or island.clue != island.size():
		return changes
	
	for liberty: Vector2i in island.liberties:
		if get_cell(liberty) == CELL_EMPTY:
			changes.append({"pos": liberty, "value": CELL_WALL})
	
	return changes


func validate(mode: ValidationMode) -> ValidationResult:
	var result: ValidationResult
	match mode:
		VALIDATE_COMPLEX:
			result = _get_cached("complex_validation_result", _build_validation_result.bind(mode))
		VALIDATE_SIMPLE:
			result = _get_cached("simple_validation_result", _build_validation_result.bind(mode))
		VALIDATE_STRICT:
			result = _get_cached("strict_validation_result", _build_strict_validation_result)
	return result


func validate_local(local_cells: Array[Vector2i]) -> String:
	var result: String = ""
	
	var local_walls: Dictionary[CellGroup, bool] = {}
	var local_islands: Dictionary[CellGroup, bool] = {}
	for local_cell: Vector2i in local_cells:
		for cell_dir in NurikabeUtils.NEIGHBOR_DIRS_WITH_SELF:
			var cell: Vector2i = local_cell + cell_dir
			if not cells.has(cell):
				continue
			match cells[cell]:
				CELL_WALL:
					local_walls[get_wall_for_cell(cell)] = true
				CELL_ISLAND:
					local_islands[get_island_for_cell(cell)] = true
	
	# joined islands
	for island: CellGroup in local_islands:
		if island.clue == -1:
			result += "j"
			break
	
	# pools
	for local_cell: Vector2i in local_cells:
		var has_pool: bool = false
		if get_cell(local_cell) != CELL_WALL:
			continue
		for pool_dir: Vector2i in [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]:
			if NurikabeUtils.pool_triplet(local_cell, pool_dir).all(func(pool_cell: Vector2i) -> bool:
					return get_cell(pool_cell) == CELL_WALL):
				has_pool = true
				break
		if has_pool:
			result += "p"
			break
	
	# split walls
	if not local_walls.is_empty():
		for wall: CellGroup in local_walls:
			if wall.liberties.size() == 0 and walls.size() > 1:
				result += "s"
				break
	
	# unclued islands
	for island: CellGroup in local_islands:
		if island.liberties.is_empty() and island.clue == 0:
			result += "u"
			break
	
	# wrong size
	for island: CellGroup in local_islands:
		if island.clue == 0 or island.clue == -1:
			continue
		
		if island.clue < island.size():
			# island is too large
			result += "c"
			break
		
		if island.liberties.is_empty() and island.clue > island.size():
			# island is too small and can't grow
			result += "c"
			break
	
	return result


func _build_flooded_board() -> SolverBoard:
	var flooded_board: SolverBoard = duplicate()
	flooded_board.groups_need_rebuild = true
	for cell: Vector2i in flooded_board.cells:
		if flooded_board.get_cell(cell) == CELL_EMPTY:
			flooded_board.set_cell(cell, CELL_ISLAND)
	return flooded_board


func _build_global_reachability_map() -> GlobalReachabilityMap:
	return GlobalReachabilityMap.new(self)


func _build_island_clues() -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	for island: CellGroup in islands:
		var clue_value: int = island.clue
		if clue_value == 0:
			continue
		for cell: Vector2i in island.cells:
			result[cell] = clue_value
	return result


func _clue_value_for_cells(island: Array[Vector2i]) -> int:
	var clue_value: int = 0
	for cell: Vector2i in island:
		var cell_value: int = cells[cell]
		if NurikabeUtils.is_clue(cell_value):
			if clue_value > 0:
				clue_value = -1
				break
			clue_value = cell_value
	return clue_value


func _build_group_neighbors(group: Array[Vector2i]) -> Array[Vector2i]:
	var group_cell_set: Dictionary[Vector2i, bool] = {}
	var liberty_cell_set: Dictionary[Vector2i, bool] = {}
	for group_cell: Vector2i in group:
		group_cell_set[group_cell] = true
	for group_cell: Vector2i in group:
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = group_cell + neighbor_dir
			if not cells.has(neighbor):
				continue
			if group_cell_set.has(neighbor):
				continue
			liberty_cell_set[neighbor] = true
	return liberty_cell_set.keys()


func _build_island_group_map() -> SolverGroupMap:
	var result: SolverGroupMap = SolverGroupMap.new(self, func(value: int) -> bool:
		return NurikabeUtils.is_island(value))
	return result


func _build_flooded_island_group_map() -> SolverGroupMap:
	var group_map: SolverGroupMap = SolverGroupMap.new(self, func(value: int) -> bool:
		return NurikabeUtils.is_island_or_empty(value))
	for group: Array[Vector2i] in group_map.groups:
		if group.all(func(cell: Vector2i) -> bool:
				return cells[cell] == CELL_EMPTY):
			group_map.erase_group(group)
	return group_map


func _build_flooded_wall_group_map() -> SolverGroupMap:
	var group_map: SolverGroupMap = SolverGroupMap.new(self, func(value: int) -> bool:
		return value == CELL_EMPTY or value == CELL_WALL)
	for group: Array[Vector2i] in group_map.groups:
		if group.all(func(cell: Vector2i) -> bool:
				return cells[cell] == CELL_EMPTY):
			group_map.erase_group(group)
	return group_map


func _build_island_chokepoint_map() -> SolverChokepointMap:
	return SolverChokepointMap.new(self,
		func(cell: Vector2i) -> bool:
			var value: int = get_cell(cell)
			return NurikabeUtils.is_island_or_empty(value),
		func(cell: Vector2i) -> bool:
			var value: int = get_cell(cell)
			return NurikabeUtils.is_clue(value))


func _build_strict_validation_result() -> ValidationResult:
	return get_flooded_board().validate(VALIDATE_SIMPLE)


func _build_validation_result(mode: ValidationMode) -> ValidationResult:
	var result: ValidationResult = ValidationResult.new()
	
	# joined islands
	for island: CellGroup in islands:
		if island.clue == -1:
			for cell: Vector2i in island.cells:
				result.joined_islands.append(cell)
	
	# pools
	for wall: CellGroup in walls:
		if wall.size() < 4:
			continue
		var wall_cell_set: Dictionary[Vector2i, bool] = {}
		var pool_cell_set: Dictionary[Vector2i, bool] = {}
		for next_wall_cell: Vector2i in wall.cells:
			wall_cell_set[next_wall_cell] = true
		for next_wall_cell: Vector2i in wall.cells:
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
	var flooded_wall_group_map: SolverGroupMap = get_flooded_wall_group_map()
	if flooded_wall_group_map.groups.size() > 1:
		var flooded_wall_groups: Array[Array] = flooded_wall_group_map.groups.duplicate()
		flooded_wall_groups.sort_custom(func(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
			return a.size() > b.size())
		for wall_group_index: int in range(1, flooded_wall_groups.size()):
			var wall_group: Array[Vector2i] = flooded_wall_groups[wall_group_index]
			for cell: Vector2i in wall_group:
				if cells[cell] == CELL_WALL:
					result.split_walls.append(cell)
	
	# unclued islands
	for flooded_island_group: Array[Vector2i] in get_flooded_island_group_map().groups:
		if _clue_value_for_cells(flooded_island_group) != 0:
			continue
		for cell: Vector2i in flooded_island_group:
			if get_cell(cell) == CELL_ISLAND:
				result.unclued_islands.append(cell)
	
	# wrong size
	for island: CellGroup in islands:
		if island.clue == 0 or island.clue == -1:
			continue
		
		if island.clue < island.size():
			# island is too large
			result.wrong_size.append_array(island.cells)
			continue
		
		match mode:
			VALIDATE_COMPLEX:
				var island_max_size: int = get_per_clue_extent_map().get_extent_size(island)
				if island.clue > island_max_size:
					# island is too small and can't grow
					result.wrong_size.append_array(island.cells)
					continue
			VALIDATE_SIMPLE:
				var group_map: SolverGroupMap = get_flooded_island_group_map()
				var flooded_island_group: Array[Vector2i] \
						= group_map.groups_by_cell.get(island.cells.front(), [] as Array[Vector2i])
				if island.clue > flooded_island_group.size():
					# island is too small and can't grow
					result.wrong_size.append_array(island.cells)
					continue
			_:
				push_error("Unexpected validation mode: %s" % [mode])
	
	return result


func _build_wall_chokepoint_map() -> SolverChokepointMap:
	return SolverChokepointMap.new(self,
		func(cell: Vector2i) -> bool:
			var value: int = get_cell(cell)
			return value == CELL_EMPTY or value == CELL_WALL,
		func(cell: Vector2i) -> bool:
			return get_cell(cell) == CELL_WALL)


func _build_per_clue_chokepoint_map() -> PerClueChokepointMap:
	return PerClueChokepointMap.new(self)


func _build_per_clue_extent_map() -> PerClueExtentMap:
	return PerClueExtentMap.new(self)


func _build_wall_group_map() -> SolverGroupMap:
	return SolverGroupMap.new(self, func(value: int) -> bool:
		return value == CELL_WALL)


func _get_cached(cache_key: String, builder: Callable) -> Variant:
	if not _cache.has(cache_key):
		_cache[cache_key] = builder.call()
	return _cache[cache_key]


func _rebuild_groups() -> void:
	if not groups_need_rebuild:
		return
	
	groups_need_rebuild = false
	
	groups_by_cell.clear()
	islands.clear()
	walls.clear()
	
	var visited: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in cells:
		if cell in visited:
			continue
		visited[cell] = true
		var cell_value: int = cells[cell]
		var new_group: CellGroup
		if NurikabeUtils.is_island(cell_value):
			new_group = CellGroup.new()
			new_group.cells = perform_bfs([cell], func(c: Vector2i) -> bool:
				return NurikabeUtils.is_island(get_cell(c)))
			new_group.clue = _clue_value_for_cells(new_group.cells)
			islands.append(new_group)
		elif cell_value == CELL_WALL:
			new_group = CellGroup.new()
			new_group.cells = perform_bfs([cell], func(c: Vector2i) -> bool:
				return get_cell(c) == CELL_WALL)
			walls.append(new_group)
		if not new_group:
			continue
		
		var group_cell_set: Dictionary[Vector2i, bool] = {}
		for group_cell: Vector2i in new_group.cells:
			group_cell_set[group_cell] = true
		
		# populate group liberties
		var liberties: Dictionary[Vector2i, bool] = {}
		for group_cell: Vector2i in new_group.cells:
			for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
				var neighbor: Vector2i = group_cell + neighbor_dir
				if get_cell(neighbor) == CELL_EMPTY and not group_cell_set.has(neighbor):
					liberties[neighbor] = true
		new_group.liberties = liberties.keys()
		
		# populate groups_by_cell
		for group_cell: Vector2i in new_group.cells:
			groups_by_cell[group_cell] = new_group
		
		visited.merge(group_cell_set)


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
	
	
	func _to_string() -> String:
		return JSON.stringify({
			"joined_islands": joined_islands,
			"pools": pools,
			"split_walls": split_walls,
			"unclued_islands": unclued_islands,
			"wrong_size": wrong_size,
		})
