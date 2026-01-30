class_name NaiveScanners

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS

## starting techniques
const ISLAND_OF_ONE: Deduction.Reason = Deduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Deduction.Reason = Deduction.Reason.ADJACENT_CLUES

## basic techniques
const CORNER_BUFFER: Deduction.Reason = Deduction.Reason.CORNER_BUFFER
const CORNER_ISLAND: Deduction.Reason = Deduction.Reason.CORNER_ISLAND
const ISLAND_BUBBLE: Deduction.Reason = Deduction.Reason.ISLAND_BUBBLE
const ISLAND_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_BUFFER
const ISLAND_CHAIN: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN
const ISLAND_CHAIN_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN_BUFFER
const ISLAND_CHOKEPOINT: Deduction.Reason = Deduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: Deduction.Reason = Deduction.Reason.ISLAND_CONNECTOR
const ISLAND_DIVIDER: Deduction.Reason = Deduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: Deduction.Reason = Deduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Deduction.Reason = Deduction.Reason.ISLAND_MOAT
const ISLAND_SNUG: Deduction.Reason = Deduction.Reason.ISLAND_SNUG
const POOL_CHOKEPOINT: Deduction.Reason = Deduction.Reason.POOL_CHOKEPOINT
const POOL_TRIPLET: Deduction.Reason = Deduction.Reason.POOL_TRIPLET
const UNCLUED_LIFELINE: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE
const UNCLUED_LIFELINE_BUFFER: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE_BUFFER
const UNREACHABLE_CELL: Deduction.Reason = Deduction.Reason.UNREACHABLE_CELL
const WALL_BUBBLE: Deduction.Reason = Deduction.Reason.WALL_BUBBLE
const WALL_CONNECTOR: Deduction.Reason = Deduction.Reason.WALL_CONNECTOR
const WALL_EXPANSION: Deduction.Reason = Deduction.Reason.WALL_EXPANSION
const WALL_WEAVER: Deduction.Reason = Deduction.Reason.WALL_WEAVER

## advanced techniques
const ASSUMPTION: Deduction.Reason = Deduction.Reason.ASSUMPTION
const BORDER_HUG: Deduction.Reason = Deduction.Reason.BORDER_HUG
const ISLAND_BATTLEGROUND: Deduction.Reason = Deduction.Reason.ISLAND_BATTLEGROUND
const ISLAND_RELEASE: Deduction.Reason = Deduction.Reason.ISLAND_RELEASE
const ISLAND_STRANGLE: Deduction.Reason = Deduction.Reason.ISLAND_STRANGLE
const WALL_STRANGLE: Deduction.Reason = Deduction.Reason.WALL_STRANGLE

const FUN_TRIVIAL: Deduction.FunAxis = Deduction.FunAxis.FUN_TRIVIAL
const FUN_FAST: Deduction.FunAxis = Deduction.FunAxis.FUN_FAST
const FUN_NOVELTY: Deduction.FunAxis = Deduction.FunAxis.FUN_NOVELTY
const FUN_THINK: Deduction.FunAxis = Deduction.FunAxis.FUN_THINK
const FUN_BIFURCATE: Deduction.FunAxis = Deduction.FunAxis.FUN_BIFURCATE


class AdjacentIslandScanner extends NaiveScanner:
	var neighbor_islands: Dictionary[Vector2i, Array] = {}
	var build_neighbor_island_index: int = 0
	
	var neighbor_island_cells: Array[Vector2i] = []
	var check_cell_index: int = 0
	
	func update(start_time: int) -> bool:
		while build_neighbor_island_index < board.islands.size():
			if out_of_time(start_time):
				break
			_build_neighbor_island(board.islands[build_neighbor_island_index])
			if build_neighbor_island_index == board.islands.size() - 1:
				neighbor_island_cells = neighbor_islands.keys()
			build_neighbor_island_index += 1
		
		while check_cell_index < neighbor_island_cells.size():
			if out_of_time(start_time):
				break
			_check_cell(neighbor_island_cells[check_cell_index])
			check_cell_index += 1
		
		return build_neighbor_island_index >= board.islands.size() \
				and check_cell_index >= neighbor_island_cells.size()
	
	
	func _build_neighbor_island(island: CellGroup) -> void:
		for liberty: Vector2i in island.liberties:
			if not neighbor_islands.has(liberty):
				neighbor_islands[liberty] = [] as Array[CellGroup]
			neighbor_islands[liberty].append(island)
	
	
	func _check_cell(cell: Vector2i) -> void:
		if neighbor_islands[cell].size() <= 1:
			return
		if _is_valid_merged_island(neighbor_islands[cell], 1):
			return
		
		# invalid merged island; calculate the reason
		var neighbor_clue_count: int = 0
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if board.clues.has(neighbor):
				neighbor_clue_count += 1
		var reason: Deduction.Reason = ISLAND_DIVIDER if neighbor_clue_count <= 1 else ADJACENT_CLUES
		
		monster.add_pending_deduction(cell, CELL_WALL, reason)
	
	
	func _is_valid_merged_island(islands: Array[CellGroup], merge_cells: int) -> bool:
		var total_joined_size: int = merge_cells
		var total_clues: int = 0
		var clue_value: int = 0
		
		var result: bool = true
		
		for island: CellGroup in islands:
			total_joined_size += island.size()
			if island.clue >= 1:
				if clue_value > 0:
					result = false
					break
				clue_value = island.clue
				total_clues += 1
				if total_clues >= 2:
					result = false
					break
			if clue_value > 0 and total_joined_size > clue_value:
				result = false
				break
		
		return result


class IslandMoatScanner extends NaiveScanner:
	var next_island_index: int = 0
	
	func update(start_time: int) -> bool:
		while next_island_index < board.islands.size():
			if out_of_time(start_time):
				break
			_check_island(board.islands[next_island_index])
			next_island_index += 1
		return next_island_index >= board.islands.size()
	
	
	func _check_island(island: CellGroup) -> void:
		if island.clue != island.size():
			return
		
		for liberty: Vector2i in island.liberties:
			if not should_deduce(liberty):
				continue
			var reason: Deduction.Reason = ISLAND_OF_ONE if island.clue == 1 else ISLAND_MOAT
			monster.add_pending_deduction(liberty, CELL_WALL, reason)


class IslandExpansionScanner extends NaiveScanner:
	var next_island_index: int = 0
	
	func update(start_time: int) -> bool:
		while next_island_index < board.islands.size():
			if out_of_time(start_time):
				break
			_check_island(board.islands[next_island_index])
			next_island_index += 1
		return next_island_index >= board.islands.size()
	
	
	func _check_island(island: CellGroup) -> void:
		if island.liberties.size() != 1 or island.clue <= island.size():
			return
		if not should_deduce(island.liberties[0]):
			return
		
		monster.add_pending_deduction(island.liberties[0], CELL_ISLAND, ISLAND_EXPANSION)


class PoolScanner extends NaiveScanner:
	var next_wall_index: int = 0
	
	func update(start_time: int) -> bool:
		while next_wall_index < board.walls.size():
			if out_of_time(start_time):
				break
			_check_wall(board.walls[next_wall_index])
			next_wall_index += 1
		return next_wall_index >= board.walls.size()
	
	
	func _check_wall(wall: CellGroup) -> void:
		if wall.size() < 3 or wall.liberties.is_empty():
			return
		
		for liberty: Vector2i in wall.liberties:
			if not should_deduce(liberty):
				continue
			
			for pool_dir: Vector2i in [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]:
				var pool_triplet_cells: Array[Vector2i] =  [
					liberty + pool_dir,
					liberty + Vector2i(pool_dir.x, 0),
					liberty + Vector2i(0, pool_dir.y)]
				if pool_triplet_cells.all(func(pool_triplet_cell: Vector2i) -> bool:
						return board.cells.get(pool_triplet_cell, CELL_INVALID) == CELL_WALL):
					pool_triplet_cells.sort()
					monster.add_pending_deduction(liberty, CELL_ISLAND, POOL_TRIPLET)


class UnreachableScanner extends NaiveScanner:
	var adjacent_clue_cells: Dictionary[Vector2i, bool] = {}
	var reachability_by_cell: Dictionary[Vector2i, int] = {}
	var visitable: Dictionary[Vector2i, bool] = {}
	var queue: Array[Vector2i] = []
	
	func update(start_time: int) -> bool:
		for island: CellGroup in board.islands:
			var reachability: int = island.clue - island.size()
			for liberty: Vector2i in island.liberties:
				adjacent_clue_cells[liberty] = true
				if reachability > 0:
					reachability_by_cell[liberty] = reachability
		
		for cell: Vector2i in board.cells:
			if board.cells[cell] == CELL_EMPTY and not adjacent_clue_cells.has(cell):
				visitable[cell] = true
		
		queue = reachability_by_cell.keys()
		while not queue.is_empty():
			#if out_of_time(start_time):
				#break
			
			_propogate_bfs(queue.pop_front())
		
		if queue.is_empty():
			for cell: Vector2i in visitable:
				if not should_deduce(cell):
					continue
				if reachability_by_cell.get(cell, 0) == 0:
					monster.add_pending_deduction(cell, CELL_WALL, UNREACHABLE_CELL)
		
		return queue.is_empty()
	
	
	func _propogate_bfs(cell: Vector2i) -> void:
		var reachability: int = reachability_by_cell[cell]
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not visitable.has(neighbor):
				continue
			if reachability_by_cell.get(neighbor, 0) >= reachability - 1:
				continue
			reachability_by_cell[neighbor] = reachability - 1
			if reachability >= 3 and not queue.has(neighbor):
				queue.append(neighbor)


class WallExpansionScanner extends NaiveScanner:
	var next_wall_index: int = 0
	
	func update(start_time: int) -> bool:
		while next_wall_index < board.walls.size():
			if out_of_time(start_time):
				break
			_check_wall(board.walls[next_wall_index])
			next_wall_index += 1
		return next_wall_index >= board.walls.size()
	
	
	func _check_wall(wall: CellGroup) -> void:
		@warning_ignore("integer_division")
		if wall.liberties.size() != 1 \
				or board.walls.size() <= 1 and wall.size() < board.cells.size() / 2:
			return
		if not should_deduce(wall.liberties[0]):
			return
		
		monster.add_pending_deduction(wall.liberties[0], CELL_WALL, WALL_EXPANSION)
