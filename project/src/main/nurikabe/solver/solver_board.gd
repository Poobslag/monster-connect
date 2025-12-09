class_name SolverBoard

enum ValidationMode {
	COMPLEX,
	SIMPLE,
	STRICT,
}

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

const VALIDATE_COMPLEX: ValidationMode = ValidationMode.COMPLEX
const VALIDATE_SIMPLE: ValidationMode = ValidationMode.SIMPLE
const VALIDATE_STRICT: ValidationMode = ValidationMode.STRICT

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const HEAT_RADIUS: int = 2 # how far heat spreads, in cells
const HEAT_HISTORY: int = 50 # how many heat events are remembered
const HEAT_SPREAD_FACTOR: float = 0.5 # how effectively heat spreads to neighboring cells; 0.0 = near, 1.0 = far
const HEAT_FADE_FACTOR: float = 0.9 # how fast heat fades over time; 0.0 = fast, 1.0 = slow

var cells: Dictionary[Vector2i, int]
var version: int

var _heat_by_cell: Dictionary[Vector2i, float] = {}

## Deferred heat calculations. We defer these until they're needed as they're moderately expensive to calculate.
var _pending_heat_changes: Array[Callable] = []
var _cache: Dictionary[String, Variant] = {}

func perform_bfs(start_cell: Vector2i, filter: Callable) -> void:
	var visited: Dictionary[Vector2i, bool] = {start_cell: true}
	var queue: Array[Vector2i] = [start_cell]
	while not queue.is_empty():
		var next_cell: Vector2i = queue.pop_front()
		if not filter.call(next_cell):
			continue
		for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
			var neighbor: Vector2i = next_cell + neighbor_dir
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)


func duplicate() -> SolverBoard:
	var copy: SolverBoard = SolverBoard.new()
	copy.cells = cells.duplicate()
	copy.version = version
	copy._heat_by_cell = _heat_by_cell.duplicate()
	copy._pending_heat_changes = _pending_heat_changes.duplicate()
	copy._cache = _cache.duplicate()
	return copy


func from_game_board(game_board: NurikabeGameBoard) -> void:
	var non_empty_cells: Array[Vector2i] = []
	for cell_pos: Vector2i in game_board.get_used_cells():
		var cell_value: int = game_board.get_cell(cell_pos)
		set_cell(cell_pos, game_board.get_cell(cell_pos))
		if cell_value != CELL_EMPTY:
			non_empty_cells.append(cell_pos)
	increase_heat(non_empty_cells)


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


func get_liberties(group: Array[Vector2i]) -> Array[Vector2i]:
	return _get_cached(
		"liberties %s" % ["-" if group.is_empty() else str(group[0])],
		_build_liberties.bind(group))


func get_group_neighbors(group: Array[Vector2i]) -> Array[Vector2i]:
	return _get_cached(
		"group_neighbors %s" % ["-" if group.is_empty() else str(group[0])],
		_build_group_neighbors.bind(group))


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
	version += 1


func increase_heat(heated_cells: Array[Vector2i]) -> void:
	_pending_heat_changes.append(_apply_heat_increase.bind(heated_cells))
	if _pending_heat_changes.size() > HEAT_HISTORY:
		_pending_heat_changes.pop_front()


func decrease_heat(factor: float = 1.0) -> void:
	_pending_heat_changes.append(_apply_heat_decrease.bind(factor))
	if _pending_heat_changes.size() > HEAT_HISTORY:
		_pending_heat_changes.pop_front()


func get_empty_regions() -> Array[Array]:
	return get_empty_region_group_map().groups


func get_empty_region_group_map() -> SolverGroupMap:
	return _get_cached(
		"empty_region_group_map",
		_build_empty_region_group_map
	)


func get_heat(cell: Vector2i) -> float:
	if _pending_heat_changes:
		_apply_heat_changes()
	return _heat_by_cell.get(cell, 0.0)


func get_flooded_island_group_map() -> SolverGroupMap:
	return _get_cached(
		"flooded_island_group_map",
		_build_flooded_island_group_map)


func get_flooded_wall_group_map() -> SolverGroupMap:
	return _get_cached(
		"flooded_wall_group_map",
		_build_flooded_wall_group_map)


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
	
	var local_wall_roots: Dictionary[Vector2i, bool] = {}
	var local_island_roots: Dictionary[Vector2i, bool] = {}
	for local_cell: Vector2i in local_cells:
		for cell_dir in NurikabeUtils.NEIGHBOR_DIRS_WITH_SELF:
			var cell: Vector2i = local_cell + cell_dir
			if not cells.has(cell):
				continue
			match cells[cell]:
				CELL_WALL:
					local_wall_roots[get_wall_root_for_cell(cell)] = true
				CELL_ISLAND:
					local_island_roots[get_island_root_for_cell(cell)] = true
	
	# joined islands
	for island_root: Vector2i in local_island_roots:
		if get_clue_for_island_cell(island_root) == -1:
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
	if not local_wall_roots.is_empty():
		for local_wall_cell: Vector2i in local_wall_roots:
			var wall: Array[Vector2i] = get_wall_for_cell(local_wall_cell)
			if get_liberties(wall).size() == 0 and get_walls().size() > 1:
				result += "s"
				break
	
	# unclued islands
	for local_island_cell: Vector2i in local_island_roots:
		var island: Array[Vector2i] = get_island_for_cell(local_island_cell)
		if get_liberties(island).size() == 0 and get_clue_for_island(island) == 0:
			result += "u"
			break
	
	# wrong size
	for local_island_root: Vector2i in local_island_roots:
		var island: Array[Vector2i] = get_island_for_cell(local_island_root)
		var clue_value: int = get_clue_for_island_cell(local_island_root)
		if clue_value == 0 or clue_value == -1:
			continue
		
		if clue_value < island.size():
			# island is too large
			result += "c"
			break
		
		if get_liberties(island).size() == 0 and clue_value > island.size():
			# island is too small and can't grow
			result += "c"
			break
	
	return result


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
		var clue_value: int = _clue_value_for_cells(island)
		if clue_value == 0:
			continue
		for cell: Vector2i in island:
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


func _build_empty_region_group_map() -> SolverGroupMap:
	var result: SolverGroupMap = SolverGroupMap.new(self, func(value: int) -> bool:
		return value == CELL_EMPTY)
	return result


func _build_liberties(group: Array[Vector2i]) -> Array[Vector2i]:
	return get_group_neighbors(group).filter(func(neighbor: Vector2i) -> bool:
		return get_cell(neighbor) == CELL_EMPTY)


func _build_group_neighbors(group: Array[Vector2i]) -> Array[Vector2i]:
	var group_cell_set: Dictionary[Vector2i, bool] = {}
	var liberty_cell_set: Dictionary[Vector2i, bool] = {}
	for group_cell: Vector2i in group:
		group_cell_set[group_cell] = true
	for group_cell: Vector2i in group:
		for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
			var neighbor: Vector2i = group_cell + neighbor_dir
			if not cells.has(neighbor):
				continue
			if group_cell_set.has(neighbor):
				continue
			liberty_cell_set[neighbor] = true
	return liberty_cell_set.keys()


func _build_island_group_map() -> SolverGroupMap:
	var result: SolverGroupMap = SolverGroupMap.new(self, func(value: int) -> bool:
		return NurikabeUtils.is_clue(value) or value == CELL_ISLAND)
	return result


func _build_flooded_island_group_map() -> SolverGroupMap:
	var group_map: SolverGroupMap = SolverGroupMap.new(self, func(value: int) -> bool:
		return NurikabeUtils.is_clue(value) or value == CELL_EMPTY or value == CELL_ISLAND)
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
			return NurikabeUtils.is_clue(value) or value == CELL_EMPTY or value == CELL_ISLAND,
		func(cell: Vector2i) -> bool:
			var value: int = get_cell(cell)
			return NurikabeUtils.is_clue(value))


func _build_strict_validation_result() -> ValidationResult:
	return get_flooded_board().validate(VALIDATE_SIMPLE)


func _build_validation_result(mode: ValidationMode) -> ValidationResult:
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
	for island: Array[Vector2i] in get_islands():
		var island_cell: Vector2i = island.front()
		var clue_value: int = get_clue_for_island_cell(island_cell)
		if clue_value == 0 or clue_value == -1:
			continue
		
		if clue_value < island.size():
			# island is too large
			result.wrong_size.append_array(island)
			continue
		
		match mode:
			VALIDATE_COMPLEX:
				var chokepoint_map: ChokepointMap = get_per_clue_chokepoint_map().get_chokepoint_map(island_cell)
				var island_max_size: int = chokepoint_map.get_component_cells(island_cell).size()
				if clue_value > island_max_size:
					# island is too small and can't grow
					result.wrong_size.append_array(island)
					continue
			VALIDATE_SIMPLE:
				var group_map: SolverGroupMap = get_flooded_island_group_map()
				var flooded_island_group: Array[Vector2i] \
						= group_map.groups_by_cell.get(island_cell, [] as Array[Vector2i])
				if clue_value > flooded_island_group.size():
					# island is too small and can't grow
					result.wrong_size.append_array(island)
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


func _build_wall_group_map() -> SolverGroupMap:
	return SolverGroupMap.new(self, func(value: int) -> bool:
		return value == CELL_WALL)


func _get_cached(cache_key: String, builder: Callable) -> Variant:
	if not _cache.has(cache_key):
		_cache[cache_key] = builder.call()
	return _cache[cache_key]


func _apply_heat_changes() -> void:
	while not _pending_heat_changes.is_empty():
		_pending_heat_changes.pop_front().call()


func _apply_heat_increase(heated_cells: Array[Vector2i]) -> void:
	var visited: Dictionary[Vector2i, bool] = {}
	var queue: Array[Array] = []
	for cell: Vector2i in heated_cells:
		visited[cell] = true
		queue.append([cell, 0])
	
	while not queue.is_empty():
		var queue_item: Array[Variant] = queue.pop_front()
		var cell: Vector2i = queue_item[0]
		var heat_distance: int = queue_item[1]
		
		_increase_heat_for_cell(cell, heat_distance)
		
		var connected_cells: Array[Vector2i]
		match cells[cell]:
			CELL_WALL:
				connected_cells = get_wall_for_cell(cell)
			CELL_ISLAND:
				connected_cells = get_island_for_cell(cell)
			CELL_EMPTY:
				connected_cells = [cell]
			_:
				if NurikabeUtils.is_clue(cells[cell]):
					connected_cells = get_island_for_cell(cell)
		var neighbors: Array[Vector2i] = get_group_neighbors(connected_cells)
		
		for group_cell: Vector2i in connected_cells:
			if visited.has(group_cell):
				continue
			_increase_heat_for_cell(group_cell, heat_distance)
			visited[group_cell] = true
		
		for neighbor: Vector2i in neighbors:
			if visited.has(neighbor):
				continue
			if heat_distance < HEAT_RADIUS:
				queue.append([neighbor, heat_distance + 1])
				visited[neighbor] = true
			else:
				_increase_heat_for_cell(neighbor, heat_distance + 1)
				visited[neighbor] = true


func _apply_heat_decrease(factor: float = 1.0) -> void:
	for cell: Vector2i in _heat_by_cell:
		_heat_by_cell[cell] *= pow(HEAT_FADE_FACTOR, factor)


func _increase_heat_for_cell(cell: Vector2i, distance: int) -> void:
	if not _heat_by_cell.has(cell):
		_heat_by_cell[cell] = 0.0
	_heat_by_cell[cell] += pow(HEAT_SPREAD_FACTOR, distance)


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
