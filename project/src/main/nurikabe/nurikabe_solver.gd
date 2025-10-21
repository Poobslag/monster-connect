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
const SURROUNDED_SQUARE: NurikabeUtils.Reason = NurikabeUtils.SURROUNDED_SQUARE
const WALL_EXPANSION: NurikabeUtils.Reason = NurikabeUtils.WALL_EXPANSION
const WALL_CONTINUITY: NurikabeUtils.Reason = NurikabeUtils.WALL_CONTINUITY
const ISLAND_EXPANSION: NurikabeUtils.Reason = NurikabeUtils.ISLAND_EXPANSION
const CORNER_ISLAND: NurikabeUtils.Reason = NurikabeUtils.CORNER_ISLAND
const HIDDEN_ISLAND_EXPANSION: NurikabeUtils.Reason = NurikabeUtils.HIDDEN_ISLAND_EXPANSION

var starting_techniques: Array[Callable] = [
	deduce_island_of_one,
	deduce_adjacent_clues,
]

var rules: Array[Callable] = [
	deduce_joined_island,
	deduce_unclued_island,
	deduce_island_too_large,
	deduce_island_too_small,
	deduce_pools,
	deduce_split_walls,
]

func deduce_island_of_one(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
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
		deductions.append(NurikabeDeduction.new(neighbor, CELL_WALL, ISLAND_OF_ONE))
	return deductions


func deduce_adjacent_clues(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		var clue_mask: int = _neighbor_mask(board, cell, func(neighbor_value: String) -> bool:
			return neighbor_value.is_valid_int())
		if clue_mask & 3 == 3 or clue_mask & 12 == 12:
			deductions.append( \
					NurikabeDeduction.new(cell, CELL_WALL, ADJACENT_CLUES))
		elif clue_mask & 5 == 5 or clue_mask & 6 == 6 or clue_mask & 9 == 9 or clue_mask & 10 == 10:
			deductions.append( \
					NurikabeDeduction.new(cell, CELL_WALL, DIAGONAL_CLUES))
	return deductions


func deduce_joined_island(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	var clued_neighbor_count_by_cell: Dictionary[Vector2i, int] = _clued_neighbor_count_by_cell(board)
	# Fill in empty cells bordering 2 or more islands with a wall.
	for cell: Vector2i in clued_neighbor_count_by_cell.keys():
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		if clued_neighbor_count_by_cell[cell] >= 2:
			deductions.append(NurikabeDeduction.new(cell, CELL_WALL, JOINED_ISLAND))
	
	return deductions


func deduce_unclued_island(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deduction_cells: Dictionary[Vector2i, bool] = {}
	var deductions: Array[NurikabeDeduction] = []
	
	# Find islands without any clues. These islands must be walls.
	for group: Array[Vector2i] in board.find_largest_island_groups():
		var only_empty_cells: bool = true
		for cell: Vector2i in group:
			if board.get_cell_string(cell) != CELL_EMPTY:
				only_empty_cells = false
				break
		if not only_empty_cells:
			continue
		if group.size() == 1:
			deduction_cells[group[0]] = true
			deductions.append(NurikabeDeduction.new(group[0], CELL_WALL, SURROUNDED_SQUARE))
			continue
		for cell: Vector2i in group:
			deduction_cells[cell] = true
			deductions.append(NurikabeDeduction.new(cell, CELL_WALL, UNCLUED_ISLAND))
	
	# If making an empty cell a wall creates a new unclued island, this cell must be an island.
	var unclued_island_count: int = _unclued_island_count(board)
	for cell: Vector2i in board.cells:
		if cell in deduction_cells:
			continue
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_WALL)
		var trial_unclued_island_count: int = _unclued_island_count(trial)
		if trial_unclued_island_count > unclued_island_count:
			deduction_cells[cell] = true
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
	var deduction_cells: Dictionary[Vector2i, bool] = {}
	var deductions: Array[NurikabeDeduction] = []
	
	# If an island can only be completed two ways, the corner cell must be a wall.
	for group: Array[Vector2i] in board.find_smallest_island_groups():
		# If the island is 1 less than its desired size, find its liberties
		var clue_cells: Array[Vector2i] = board.get_clue_cells(group)
		if clue_cells.size() != 1:
			continue
		if board.get_cell_string(clue_cells[0]).to_int() != group.size() + 1:
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
			if liberty_connector in deduction_cells:
				continue
			if board.get_cell_string(liberty_connector) != CELL_EMPTY:
				continue
			deduction_cells[liberty_connector] = true
			deductions.append(NurikabeDeduction.new(liberty_connector, CELL_WALL, CORNER_ISLAND))
	
	# If making an empty cell a wall creates an uncompletable island, this cell must be an island.
	var uncompletable_island_count: int = _uncompletable_island_count(board)
	for cell: Vector2i in board.cells:
		if cell in deduction_cells:
			continue
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_WALL)
		var trial_uncompletable_island_count: int = _uncompletable_island_count(trial)
		if trial_uncompletable_island_count > uncompletable_island_count:
			var reason: NurikabeUtils.Reason = HIDDEN_ISLAND_EXPANSION
			var island_mask: int = _neighbor_mask(board, cell, func(neighbor_value: String) -> bool:
				return neighbor_value == CELL_ISLAND or neighbor_value.is_valid_int())
			if island_mask != 0:
				reason = ISLAND_EXPANSION
			deductions.append(NurikabeDeduction.new(cell, CELL_ISLAND, reason))
			deduction_cells[cell] = true
	
	# If expanding a clued island blocks in another clued island so it can't be completed, this cell must be a wall.
	var island_neighbor_count_by_cell: Dictionary[Vector2i, int] = _island_neighbor_count_by_cell(board)
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		if cell in deduction_cells:
			continue
		# For each cell adjacent to exactly one numbered clue, try making it an island...
		if island_neighbor_count_by_cell.get(cell, -1) != 1:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_ISLAND)
		
		# Fill in all cells adjacent to two numbered clues, or a massive blob and a small clue
		var trial_neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] = _neighbor_groups_by_empty_cell(trial)
		for trial_cell: Vector2i in trial.cells:
			if trial.get_cell_string(trial_cell) != CELL_EMPTY:
				continue
			if trial_neighbor_groups_by_empty_cell.get(trial_cell, []).size() < 2:
				continue
			var joined_size: int = 1
			var total_clues: int = 0
			var biggest_clue: int = 0
			for group: Array[Vector2i] in trial_neighbor_groups_by_empty_cell[trial_cell]:
				var clue_cells: Array[Vector2i] = trial.get_clue_cells(group)
				joined_size += group.size()
				total_clues += clue_cells.size()
				for clue_cell in clue_cells:
					biggest_clue = max(biggest_clue, trial.get_cell_string(clue_cell).to_int())
			if total_clues >= 2 or joined_size > biggest_clue:
				trial.set_cell_string(trial_cell, CELL_WALL)
		
		# If any clues can't be completed, the cell must be a wall
		var trial_uncompletable_island_count: int = _uncompletable_island_count(trial)
		if trial_uncompletable_island_count > uncompletable_island_count:
			deduction_cells[cell] = true
			deductions.append(NurikabeDeduction.new(cell, CELL_WALL, HIDDEN_ISLAND_EXPANSION))
	
	return deductions


func deduce_pools(board: NurikabeBoardModel) -> Array[NurikabeDeduction]:
	var deductions: Array[NurikabeDeduction] = []
	var pool_count: int = board.get_pool_cells().size()
	for cell: Vector2i in board.cells:
		if board.get_cell_string(cell) != CELL_EMPTY:
			continue
		
		var trial: NurikabeBoardModel = board.duplicate()
		trial.set_cell_string(cell, CELL_WALL)
		for group: Array[Vector2i] in _empty_islands(trial):
			for group_cell: Vector2i in group:
				trial.set_cell_string(group_cell, CELL_WALL)
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
		trial.set_cell_string(cell, CELL_ISLAND)
		var trial_wall_count: int = _largest_non_empty_wall_groups(trial).size()
		if trial_wall_count > wall_count:
			var wall_mask: int = _neighbor_mask(board, cell, func(neighbor_value: String) -> bool:
				return neighbor_value == CELL_WALL)
			var reason: NurikabeUtils.Reason = WALL_CONTINUITY
			if wall_mask in [0, 1, 2, 4, 8]:
				reason = WALL_EXPANSION
			deductions.append(NurikabeDeduction.new(cell, CELL_WALL, reason))
	return deductions


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


func _neighbor_groups_by_empty_cell(board: NurikabeBoardModel) -> Dictionary[Vector2i, Array]:
	var neighbor_groups_by_empty_cell: Dictionary[Vector2i, Array] = {}
	var smallest_island_groups: Array[Array] = board.find_smallest_island_groups()
	for group: Array[Vector2i] in smallest_island_groups:
		for cell: Vector2i in group:
			for neighbor: Vector2i in board.get_neighbors(cell):
				if not neighbor in neighbor_groups_by_empty_cell:
					neighbor_groups_by_empty_cell[neighbor] = []
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


func _uncompletable_island_count(board: NurikabeBoardModel) -> int:
	var result: int = 0
	for group: Array[Vector2i] in board.find_largest_island_groups():
		var clue_cells: Array[Vector2i] = board.get_clue_cells(group)
		if clue_cells.size() == 1 and board.get_cell_string(clue_cells[0]).to_int() > group.size():
			result += 1
	return result
