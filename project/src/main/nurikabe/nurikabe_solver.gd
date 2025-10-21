class_name NurikabeSolver

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const UNKNOWN_REASON: NurikabeUtils.Reason = NurikabeUtils.UNKNOWN_REASON

## Rules
const JOINED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.JOINED_ISLAND
const UNCLUED_ISLAND: NurikabeUtils.Reason = NurikabeUtils.UNCLUED_ISLAND
const ISLAND_TOO_LARGE: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_LARGE
const ISLAND_TOO_SMALL: NurikabeUtils.Reason = NurikabeUtils.ISLAND_TOO_SMALL
const POOLS: NurikabeUtils.Reason = NurikabeUtils.POOLS
const SPLIT_WALLS: NurikabeUtils.Reason = NurikabeUtils.SPLIT_WALLS

var rules: Array[Callable] = [
	deduce_joined_island,
	deduce_unclued_island,
	deduce_island_too_large,
	deduce_island_too_small,
	deduce_pools,
	deduce_split_walls,
]

func deduce_joined_island(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	
	# Find the number of single-clue islands bordering each empty cell, store it in neighbor_map.
	#
	# -1: invalid
	# 0: bordering 0 islands with exactly one clue
	# 1: bordering 1 island with exactly one clue
	# n: bordering n islands with exactly one clue
	var neighbor_map: Dictionary[Vector2i, int] = {}
	for cell: Vector2i in board.cells:
		neighbor_map[cell] = 0
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		if board.get_clue_cells(group).size() != 1:
			continue
		var seen: Dictionary[Vector2i, bool] = {}
		for cell: Vector2i in group:
			for neighbor_cell: Vector2i in board.get_neighbors(cell):
				if seen.has(neighbor_cell) or board.get_cell_string(neighbor_cell) != CELL_EMPTY:
					continue
				neighbor_map[neighbor_cell] += 1
				seen[neighbor_cell] = true
	
	# Fill in empty cells bordering 2 or more islands with a wall.
	for cell: Vector2i in neighbor_map.keys():
		if neighbor_map[cell] >= 2:
			deductions.append(NurikabeDeduction.new(cell, CELL_WALL, JOINED_ISLAND))
	
	return deductions


func deduce_unclued_island(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	
	# Find islands without any clues. These islands must be walls.
	for group: Array[Vector2i] in board.find_largest_island_groups():
		var only_empty_cells: bool = true
		for cell: Vector2i in group:
			if board.get_cell_string(cell) != CELL_EMPTY:
				only_empty_cells = false
				break
		if only_empty_cells:
			for cell: Vector2i in group:
				deductions.append(NurikabeDeduction.new(cell, CELL_WALL, UNCLUED_ISLAND))
	
	# If making an empty cell a wall creates a new unclued island, this cell must be an island.
	var unclued_island_count: int = _unclued_island_count(board)
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.cells[cell] = CELL_WALL
		var trial_unclued_island_count: int = _unclued_island_count(trial)
		if trial_unclued_island_count > unclued_island_count:
			deductions.append(NurikabeDeduction.new(cell, CELL_ISLAND, UNCLUED_ISLAND))
	
	return deductions


func deduce_island_too_large(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	
	# Find islands which cannot grow any larger, store them in complete_islands.
	var complete_islands: Array[Array] = []
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		var clue_cells: Array[Vector2i] = board.get_clue_cells(group)
		if clue_cells.size() == 1 and board.get_cell_string(clue_cells[0]).to_int() == group.size():
			complete_islands.append(group)
	
	# Fill in all empty cells neighboring a complete island.
	var seen: Dictionary[Vector2i, bool] = {}
	for group: Array[Vector2i] in complete_islands:
		for cell: Vector2i in group:
			for neighbor_cell: Vector2i in board.get_neighbors(cell):
				if seen.has(neighbor_cell) or board.get_cell_string(neighbor_cell) != CELL_EMPTY:
					continue
				deductions.append(NurikabeDeduction.new(neighbor_cell, CELL_WALL, ISLAND_TOO_LARGE))
				seen[neighbor_cell] = true
	
	return deductions


func deduce_island_too_small(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	
	# If making an empty cell a wall creates an uncompletable island, this cell must be an island.
	var uncompletable_island_count: int = _uncompletable_island_count(board)
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.cells[cell] = CELL_WALL
		var trial_uncompletable_island_count: int = _uncompletable_island_count(trial)
		if trial_uncompletable_island_count > uncompletable_island_count:
			deductions.append(NurikabeDeduction.new(cell, CELL_ISLAND, ISLAND_TOO_SMALL))
	
	return deductions


func deduce_pools(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	var pool_count: int = board.get_pool_cells().size()
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.cells[cell] = CELL_WALL
		for group: Array[Vector2i] in _empty_islands(trial):
			for group_cell: Vector2i in group:
				trial.cells[group_cell] = CELL_WALL
		var trial_pool_count: int = trial.get_pool_cells().size()
		if trial_pool_count > pool_count:
			deductions.append(NurikabeDeduction.new(cell, CELL_ISLAND, POOLS))
	return deductions


func deduce_split_walls(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	var wall_count: int = _largest_non_empty_wall_groups(board).size()
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.cells[cell] = CELL_ISLAND
		var trial_wall_count: int = _largest_non_empty_wall_groups(trial).size()
		if trial_wall_count > wall_count:
			trial.find_largest_wall_groups()
			deductions.append(NurikabeDeduction.new(cell, CELL_WALL, SPLIT_WALLS))
	return deductions


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


func _empty_islands(board: NurikabeBoardModel) -> Array[Array]:
	var result: Array[Array] = []
	var groups: Array[Array] = board.find_largest_island_groups()
	for group: Array[Vector2i] in groups:
		if _only_empty_cells(board, group):
			result.append(group)
	return result


func _only_empty_cells(board: NurikabeBoardModel, group: Array[Vector2i]) -> bool:
	var result: bool = true
	for cell: Vector2i in group:
		if board.get_cell_string(cell) != CELL_EMPTY:
			result = false
			break
	return result


func _unclued_island_count(board: NurikabeBoardModel) -> int:
	var result: int = 0
	for group: Array[Vector2i] in board.find_largest_island_groups():
		if _only_empty_cells(board, group):
			continue
		var clue_cells: Array[Vector2i] = board.get_clue_cells(group)
		if clue_cells.size() == 0:
			result += 1
	return result


func _uncompletable_island_count(board: NurikabeBoardModel) -> int:
	var result: int = 0
	for group: Array[Vector2i] in board.find_largest_island_groups():
		var clue_cells: Array[Vector2i] = board.get_clue_cells(group)
		if clue_cells.size() == 1 and board.get_cell_string(clue_cells[0]).to_int() > group.size():
			result += 1
	return result
