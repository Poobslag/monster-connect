class_name NurikabeSolver

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const UNKNOWN_REASON: NurikabeUtils.Reason = NurikabeUtils.UNKNOWN_REASON

## Starting techniques
const ISLAND_OF_ONE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_OF_ONE
const ADJACENT_CLUES: NurikabeUtils.Reason = NurikabeUtils.ADJACENT_CLUES
const DIAGONAL_CLUES: NurikabeUtils.Reason = NurikabeUtils.DIAGONAL_CLUES

## Rules
const JOINED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.JOINED_ISLAND
const UNCLUED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.UNCLUED_ISLAND
const ISLAND_TOO_LARGE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_LARGE
const ISLAND_TOO_SMALL: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_SMALL
const POOLS: NurikabeUtils.Reason = NurikabeUtils.POOLS
const SPLIT_WALLS: NurikabeUtils.Reason = NurikabeUtils.SPLIT_WALLS

## Basic techniques
const CORNER_ISLAND: NurikabeUtils.Reason = NurikabeUtils.CORNER_ISLAND
const ISLAND_BUBBLE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_BUBBLE
const ISLAND_BUFFER: NurikabeUtils.Reason = NurikabeUtils.ISLAND_BUFFER
const ISLAND_CHOKEPOINT: NurikabeUtils.Reason = NurikabeUtils.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: NurikabeUtils.Reason = NurikabeUtils.ISLAND_CONNECTOR
const ISLAND_DIVIDER: NurikabeUtils.Reason = NurikabeUtils.ISLAND_DIVIDER
const ISLAND_EXPANSION: NurikabeUtils.Reason = NurikabeUtils.ISLAND_EXPANSION
const ISLAND_MOAT: NurikabeUtils.Reason = NurikabeUtils.ISLAND_MOAT
const POOL_TRIPLET: NurikabeUtils.Reason = NurikabeUtils.POOL_TRIPLET
const UNREACHABLE_SQUARE: NurikabeUtils.Reason = NurikabeUtils.UNREACHABLE_SQUARE
const WALL_BUBBLE: NurikabeUtils.Reason = NurikabeUtils.WALL_BUBBLE
const WALL_CONNECTOR: NurikabeUtils.Reason = NurikabeUtils.WALL_CONNECTOR
const WALL_EXPANSION: NurikabeUtils.Reason = NurikabeUtils.WALL_EXPANSION

var starting_techniques: Array[Callable] = [
	deduce_island_of_one,
	deduce_adjacent_clues,
]

var rules: Array[Callable] = [
	deduce_corner_island,
	deduce_island_bubble,
	deduce_island_buffer,
	deduce_island_connector,
	deduce_island_divider,
	deduce_island_expansion,
	deduce_island_moat,
	deduce_pool_triplets,
	deduce_unreachable_square,
	deduce_wall_bubble,
	deduce_wall_expansion,
]

var solver_pass: NurikabeSolverPass = NurikabeSolverPass.new()

func clear() -> void:
	solver_pass.clear()


func deduce_island_of_one(board: NurikabeBoardModel) -> void:
	var island_of_one_neighbors: Dictionary[Vector2i, bool] = {}
	var islands_of_one: Array[Vector2i] = []
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell).is_valid_int() and board.get_cell_string(cell).to_int() == 1:
			islands_of_one.append(cell)
	for island_of_one: Vector2i in islands_of_one:
		for neighbor_cell: Vector2i in board.get_neighbors(island_of_one):
			if board.get_cell_string(neighbor_cell) == CELL_EMPTY:
				island_of_one_neighbors[neighbor_cell] = true
	for neighbor: Vector2i in island_of_one_neighbors:
		solver_pass.add_deduction(neighbor, CELL_WALL, ISLAND_OF_ONE)


func deduce_adjacent_clues(board: NurikabeBoardModel) -> void:
	for cell: Vector2i in board.cells:
		if not _can_deduce(board, cell):
			continue
		var clue_mask: int = _neighbor_mask(board, cell, func(neighbor_value: String) -> bool:
			return neighbor_value.is_valid_int())
		if clue_mask & 3 == 3 or clue_mask & 12 == 12:
			solver_pass.add_deduction(cell, CELL_WALL, ADJACENT_CLUES)
		elif clue_mask & 5 == 5 or clue_mask & 6 == 6 or clue_mask & 9 == 9 or clue_mask & 10 == 10:
			solver_pass.add_deduction(cell, CELL_WALL, DIAGONAL_CLUES)


## Fill in empty cells bordering 2 or more islands with a wall.
func deduce_island_divider(board: NurikabeBoardModel) -> void:
	var clued_neighbor_count_by_cell: Dictionary[Vector2i, int] = _clued_neighbor_count_by_cell(board)
	for cell: Vector2i in clued_neighbor_count_by_cell.keys():
		if not _can_deduce(board, cell):
			continue
		if clued_neighbor_count_by_cell[cell] >= 2:
			solver_pass.add_deduction(cell, CELL_WALL, ISLAND_DIVIDER)


## Find empty areas surrounded by walls. These areas must be walls.
func deduce_wall_bubble(board: NurikabeBoardModel) -> void:
	for group: Array[Vector2i] in board.find_largest_island_groups():
		var only_empty_cells: bool = true
		for cell: Vector2i in group:
			if board.get_cell_string(cell) != CELL_EMPTY:
				only_empty_cells = false
				break
		if not only_empty_cells:
			continue
		for cell: Vector2i in group:
			if cell in solver_pass.deduction_cells:
				continue
			solver_pass.add_deduction(cell, CELL_WALL, WALL_BUBBLE)


## If making an empty cell a wall creates a new unclued island, this cell must be an island.
func deduce_island_connector(board: NurikabeBoardModel) -> void:
	var unclued_island_count: int = _unclued_island_count(board)
	for cell: Vector2i in board.cells:
		if not _can_deduce(board, cell):
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_WALL)
		var trial_unclued_island_count: int = _unclued_island_count(trial)
		if trial_unclued_island_count > unclued_island_count:
			solver_pass.add_deduction(cell, CELL_ISLAND, ISLAND_CONNECTOR)


## Fill in all empty cells neighboring a complete island.
func deduce_island_moat(board: NurikabeBoardModel) -> void:
	# Find islands which cannot grow any larger, store them in complete_islands.
	var complete_islands: Array[Array] = []
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		if board.get_clue_value(group) == group.size():
			complete_islands.append(group)
	
	var seen: Dictionary[Vector2i, bool] = {}
	for group: Array[Vector2i] in complete_islands:
		for cell: Vector2i in group:
			for neighbor_cell: Vector2i in board.get_neighbors(cell):
				if seen.has(neighbor_cell) or not _can_deduce(board, neighbor_cell):
					continue
				solver_pass.add_deduction(neighbor_cell, CELL_WALL, ISLAND_MOAT)
				seen[neighbor_cell] = true


## If an island can only be completed two ways, the corner cell must be a wall.
func deduce_corner_island(board: NurikabeBoardModel) -> void:
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		# If the island is 1 less than its desired size, find its liberties
		if board.get_clue_value(group) != group.size() + 1:
			continue
		var liberty_cells: Array[Vector2i] = _find_liberties(board, group)
		if liberty_cells.size() != 2:
			continue
		# If there are two liberties, and the liberties are diagonal, any blank squares connecting those liberties
		# must be walls.
		var liberty_connectors: Array[Vector2i] = []
		liberty_connectors.assign(Utils.intersection( \
				board.get_neighbors(liberty_cells[0]), board.get_neighbors(liberty_cells[1])))
		for liberty_connector: Vector2i in liberty_connectors:
			if not _can_deduce(board, liberty_connector):
				continue
			solver_pass.add_deduction(liberty_connector, CELL_WALL, CORNER_ISLAND)


## If making an empty cell a wall creates an uncompletable island, this cell must be an island.
func deduce_island_expansion(board: NurikabeBoardModel) -> void:
	var uncompletable_island_count: int = get_uncompletable_island_count(board)
	for cell: Vector2i in board.cells:
		if not _can_deduce(board, cell):
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_WALL)
		var trial_uncompletable_island_count: int = get_uncompletable_island_count(trial)
		if trial_uncompletable_island_count > uncompletable_island_count:
			var reason: NurikabeUtils.Reason = ISLAND_CHOKEPOINT
			var island_mask: int = _neighbor_mask(board, cell, func(neighbor_value: String) -> bool:
				return neighbor_value == CELL_ISLAND or neighbor_value.is_valid_int())
			if island_mask != 0:
				reason = ISLAND_EXPANSION
			solver_pass.add_deduction(cell, CELL_ISLAND, reason)


## If expanding a clued island blocks in another clued island so it can't be completed, this cell must be a wall.
func deduce_island_buffer(board: NurikabeBoardModel) -> void:
	var uncompletable_island_count: int = get_uncompletable_island_count(board)
	for cell: Vector2i in board.cells:
		if not _can_deduce(board, cell):
			continue
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_ISLAND)
		var trial_uncompletable_island_count: int = get_uncompletable_island_count(trial)
		if trial_uncompletable_island_count > uncompletable_island_count:
			solver_pass.add_deduction(cell, CELL_WALL, ISLAND_BUFFER)


func deduce_pool_triplets(board: NurikabeBoardModel) -> void:
	var pool_count: int = board.get_pool_cells().size()
	for cell: Vector2i in board.cells:
		if not _can_deduce(board, cell):
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_WALL)
		for group: Array[Vector2i] in _empty_islands(trial):
			for group_cell: Vector2i in group:
				trial.set_cell_string(group_cell, CELL_WALL)
		var trial_pool_count: int = trial.get_pool_cells().size()
		if trial_pool_count > pool_count:
			solver_pass.add_deduction(cell, CELL_ISLAND, POOL_TRIPLET)


func deduce_wall_expansion(board: NurikabeBoardModel) -> void:
	var wall_count: int = _largest_non_empty_wall_groups(board).size()
	for cell: Vector2i in board.cells:
		if not _can_deduce(board, cell):
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_ISLAND)
		var trial_wall_count: int = _largest_non_empty_wall_groups(trial).size()
		if trial_wall_count > wall_count:
			var wall_mask: int = _neighbor_mask(board, cell, func(neighbor_value: String) -> bool:
				return neighbor_value == CELL_WALL)
			var reason: NurikabeUtils.Reason = WALL_CONNECTOR
			if wall_mask in [0, 1, 2, 4, 8]:
				reason = WALL_EXPANSION
			solver_pass.add_deduction(cell, CELL_WALL, reason)


func deduce_island_bubble(board: NurikabeBoardModel) -> void:
	# Find empty areas surrounded by islands. These areas must be islands.
	for group: Array[Vector2i] in board.find_largest_wall_groups():
		var only_empty_cells: bool = true
		for cell: Vector2i in group:
			if board.get_cell_string(cell) != CELL_EMPTY:
				only_empty_cells = false
				break
		if not only_empty_cells:
			continue
		for cell: Vector2i in group:
			if not _can_deduce(board, cell):
				continue
			solver_pass.add_deduction(cell, CELL_ISLAND, ISLAND_BUBBLE)


func deduce_unreachable_square(board: NurikabeBoardModel) -> void:
	var reachable: Dictionary[Vector2i, bool]
	var clued_groups: Array[Array] = []
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		if board.get_clue_cells(group).size() == 1:
			clued_groups.append(group)
	var clued_neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] \
		= _neighbor_groups_by_empty_cell(board, clued_groups)
	for group: Array[Vector2i] in clued_groups:
		for cell: Vector2i in _flood_reachable_cells(board, group, clued_neighbor_groups_by_empty_cell):
			reachable[cell] = true
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) == CELL_EMPTY and not cell in reachable:
			solver_pass.add_deduction(cell, CELL_WALL, UNREACHABLE_SQUARE)


func get_uncompletable_island_count(board: NurikabeBoardModel) -> int:
	var uncompletable_islands: Dictionary[Array, bool] = {}
	var complete_islands: Dictionary[Array, bool] = {}
	var unclued_groups: Dictionary[Array, bool] = {}
	var clued_groups: Dictionary[Array, bool] = {}
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		var clue_count: int = board.get_clue_cells(group).size()
		if clue_count == 0:
			unclued_groups[group] = true
		elif clue_count == 1:
			clued_groups[group] = true
	var unclued_neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] \
			= _neighbor_groups_by_empty_cell(board, unclued_groups.keys())
	var clued_neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] \
			= _neighbor_groups_by_empty_cell(board, clued_groups.keys())
	
	for group: Array[Vector2i] in clued_groups:
		# Ignore complete/invalid islands.
		var clue_value: int = board.get_clue_value(group)
		if clue_value <= group.size():
			complete_islands[group] = true
	
	for group: Array[Vector2i] in clued_groups:
		# Evaluate the liberties of each incomplete group, to ensure that it can grow by one square.
		if group in uncompletable_islands or group in complete_islands:
			continue
		var has_valid_liberty: bool = false
		var clue_value: int = board.get_clue_value(group)
		for liberty: Vector2i in _find_liberties(board, group):
			var total_joined_size: int = 1
			var total_clues: int = 0
			var total_biggest_clue: int = 0
			
			for joined_group: Array[Vector2i] in \
					clued_neighbor_groups_by_empty_cell.get(liberty):
				var joined_clue_cells: Array[Vector2i] = board.get_clue_cells(joined_group)
				total_clues += joined_clue_cells.size()
				total_joined_size += joined_group.size()
				if joined_clue_cells:
					total_biggest_clue = max(total_biggest_clue, \
							board.get_cell_string(joined_clue_cells[0]).to_int())
			
			for joined_group: Array[Vector2i] in \
					unclued_neighbor_groups_by_empty_cell.get(liberty, [] as Array[Vector2i]):
				total_joined_size += joined_group.size()
			
			if total_clues == 1 and total_joined_size <= clue_value:
				has_valid_liberty = true
		if not has_valid_liberty:
			uncompletable_islands[group] = true
	
	for group: Array[Vector2i] in clued_groups:
		# Make each clued group as large as possible without joining other clued groups to ensure it can grow large
		# enough.
		if group in uncompletable_islands or group in complete_islands:
			continue
		var clue_value: int = board.get_clue_value(group)
		var group_cells: Dictionary[Vector2i, bool] = {}
		var queue: Dictionary[Vector2i, bool] = {}
		for group_cell: Vector2i in group:
			queue[group_cell] = true
		while not queue.is_empty() and group_cells.size() < clue_value:
			var next_cell: Vector2i = queue.keys()[0]
			queue.erase(next_cell)
			group_cells[next_cell] = true
			for neighbor_cell: Vector2i in board.get_neighbors(next_cell):
				if group_cells.has(neighbor_cell):
					continue
				if board.get_cell_string(neighbor_cell) in [CELL_WALL, CELL_INVALID]:
					continue
				var neighbor_groups: Array[Array] \
						= clued_neighbor_groups_by_empty_cell.get(neighbor_cell, [] as Array[Array])
				var has_clued_neighbor_group: bool = false
				for neighbor_group: Array[Vector2i] in neighbor_groups:
					if neighbor_group != group and neighbor_group in clued_groups:
						has_clued_neighbor_group = true
						break
				if has_clued_neighbor_group:
					continue
				queue[neighbor_cell] = true
		if group_cells.size() < clue_value:
			uncompletable_islands[group] = true
	
	return uncompletable_islands.size()


func _can_deduce(board: NurikabeBoardModel, cell: Vector2i) -> bool:
	return board.get_cell_string(cell) == CELL_EMPTY and not cell in solver_pass.deduction_cells


## Returns the number of single-clue islands bordering each empty cell.
func _clued_neighbor_count_by_cell(board: NurikabeBoardModel) -> Dictionary[Vector2i, int]:
	var clued_neighbor_count_by_cell: Dictionary[Vector2i, int] = {}
	var neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] = _neighbor_groups_by_empty_cell(board)
	for cell: Vector2i in neighbor_groups_by_empty_cell:
		clued_neighbor_count_by_cell[cell] = 0
		for group: Array[Vector2i] in neighbor_groups_by_empty_cell[cell]:
			if board.get_clue_cells(group).size() == 1:
				clued_neighbor_count_by_cell[cell] += 1
	return clued_neighbor_count_by_cell


func _empty_islands(board: NurikabeBoardModel) -> Array[Array]:
	var result: Array[Array] = []
	var groups: Array[Array] = board.find_largest_island_groups()
	for group: Array[Vector2i] in groups:
		if _only_empty_cells(board, group):
			result.append(group)
	return result


func _find_liberties(board: NurikabeBoardModel, group: Array[Vector2i]) -> Array[Vector2i]:
	var liberties: Array[Vector2i] = []
	var seen: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in group:
		for neighbor_cell in board.get_neighbors(cell):
			if board.get_cell_string(neighbor_cell) == CELL_EMPTY:
				liberties.append(neighbor_cell)
			seen[neighbor_cell] = true
	return liberties


func _flood_reachable_cells( \
		board: NurikabeBoardModel,
		group: Array[Vector2i],
		clued_neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var queue: Array[Vector2i] = group.duplicate()
	var min_group_size_by_cell: Dictionary[Vector2i, int] = {}
	var visited: Dictionary[Vector2i, bool] = {}
	var clue_value: int = board.get_clue_value(group)
	for cell: Vector2i in group:
		min_group_size_by_cell[cell] = group.size()
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if visited.has(cell):
			continue
		visited[cell] = true
		result.append(cell)
		if min_group_size_by_cell[cell] == clue_value:
			continue
		for neighbor_cell in board.get_neighbors(cell):
			if visited.has(neighbor_cell):
				continue
			if board.get_cell_string(neighbor_cell) not in [CELL_EMPTY, CELL_ISLAND]:
				continue
			var clued_neighbor_groups: Array[Array]\
					= clued_neighbor_groups_by_empty_cell.get(neighbor_cell, [] as Array[Array])
			if clued_neighbor_groups.size() > 1 \
					or clued_neighbor_groups.size() == 1 and clued_neighbor_groups[0] != group:
				continue
			queue.append(neighbor_cell)
			min_group_size_by_cell[neighbor_cell] = min(
					min_group_size_by_cell.get(neighbor_cell, 99), min_group_size_by_cell[cell] + 1)
	return result


## Returns the number of islands bordering each empty cell.
func _island_neighbor_count_by_cell(board: NurikabeBoardModel) -> Dictionary[Vector2i, int]:
	var island_neighbor_count_by_cell: Dictionary[Vector2i, int] = {}
	var neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] = _neighbor_groups_by_empty_cell(board)
	for cell: Vector2i in neighbor_groups_by_empty_cell:
		island_neighbor_count_by_cell[cell] = neighbor_groups_by_empty_cell[cell].size()
	return island_neighbor_count_by_cell


func _largest_non_empty_wall_groups(board: NurikabeBoardModel) -> Array[Array]:
	var result: Array[Array] = []
	for group: Array[Vector2i] in board.find_largest_wall_groups():
		var only_empty_cells: bool = true
		for cell: Vector2i in group:
			if board.get_cell_string(cell) != CELL_EMPTY:
				only_empty_cells = false
				break
		if not only_empty_cells:
			result.append(group)
	return result


func _neighbor_groups_by_empty_cell(
			board: NurikabeBoardModel,
			smallest_island_groups: Array[Array] = board.find_smallest_island_groups()
		) -> Dictionary[Vector2i, Array]:
	
	var neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] = {}
	for group: Array[Vector2i] in smallest_island_groups:
		for cell: Vector2i in group:
			for neighbor: Vector2i in board.get_neighbors(cell):
				if not neighbor in neighbor_groups_by_empty_cell:
					neighbor_groups_by_empty_cell[neighbor] = [] as Array[Array]
				if not group in neighbor_groups_by_empty_cell[neighbor]:
					neighbor_groups_by_empty_cell[neighbor].append(group)
	return neighbor_groups_by_empty_cell


## Returns a 4-bit mask of neighbor cells which satisfy [param predicate].[br]
## [br]
## Bit mask: 1=up, 2=down, 4=left, 8=right.
func _neighbor_mask(board: NurikabeBoardModel, cell: Vector2i, predicate: Callable) -> int:
	var mask: int = 0
	mask |= 1 if predicate.call(board.get_cell_string(cell + Vector2i.UP)) else 0
	mask |= 2 if predicate.call(board.get_cell_string(cell + Vector2i.DOWN)) else 0
	mask |= 4 if predicate.call(board.get_cell_string(cell + Vector2i.LEFT)) else 0
	mask |= 8 if predicate.call(board.get_cell_string(cell + Vector2i.RIGHT)) else 0
	return mask


func _only_empty_cells(board: NurikabeBoardModel, group: Array[Vector2i]) -> bool:
	var result: bool = true
	for cell: Vector2i in group:
		if board.get_cell_string(cell) != CELL_EMPTY:
			result = false
			break
	return result


func _unclued_island_sizes_by_cell(board: NurikabeBoardModel) -> Dictionary[Vector2i, int]:
	var unclued_island_sizes_by_cell: Dictionary[Vector2i, int] = {}
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		if board.get_clue_cells(group).size() != 0:
			continue
		for cell: Vector2i in group:
			unclued_island_sizes_by_cell[cell] = group.size()
	return unclued_island_sizes_by_cell


func _unclued_island_count(board: NurikabeBoardModel) -> int:
	var result: int = 0
	for group: Array[Vector2i] in board.find_largest_island_groups():
		if _only_empty_cells(board, group):
			continue
		var clue_cells: Array[Vector2i] = board.get_clue_cells(group)
		if clue_cells.size() == 0:
			result += 1
	return result
