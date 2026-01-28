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
const ISLAND_CHOKEPOINT: Deduction.Reason = Deduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: Deduction.Reason = Deduction.Reason.ISLAND_CONNECTOR
const ISLAND_DIVIDER: Deduction.Reason = Deduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: Deduction.Reason = Deduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Deduction.Reason = Deduction.Reason.ISLAND_MOAT
const ISLAND_SNUG: Deduction.Reason = Deduction.Reason.ISLAND_SNUG
const POOL_CHOKEPOINT: Deduction.Reason = Deduction.Reason.POOL_CHOKEPOINT
const POOL_TRIPLET: Deduction.Reason = Deduction.Reason.POOL_TRIPLET
const UNCLUED_LIFELINE: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE
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


class IslandMoatScanner extends NaiveScanner:
	var next_island_index: int = 0
	
	func update(start_time: int) -> bool:
		while next_island_index < scanner_board.islands.size():
			if out_of_time(start_time):
				break
			_check_island(scanner_board.islands[next_island_index])
			next_island_index += 1
		return next_island_index >= scanner_board.islands.size()
	
	
	func _check_island(island: CellGroup) -> void:
		if island.clue != island.size():
			return
		
		for liberty: Vector2i in island.liberties:
			if not should_deduce(liberty):
				continue
			var reason: Deduction.Reason = ISLAND_OF_ONE if island.clue == 1 else ISLAND_MOAT
			monster.add_pending_deduction(liberty, CELL_WALL, reason)


class AdjacentIslandScanner extends NaiveScanner:
	var next_island_index: int = 0
	var all_liberties: Dictionary[Vector2i, bool] = {}
	
	func update(start_time: int) -> bool:
		while next_island_index < scanner_board.islands.size():
			if out_of_time(start_time):
				break
			_check_island(scanner_board.islands[next_island_index])
			next_island_index += 1
		return next_island_index >= scanner_board.islands.size()
	
	
	func _check_island(island: CellGroup) -> void:
		for liberty: Vector2i in island.liberties:
			if not all_liberties.has(liberty):
				all_liberties[liberty] = true
				continue
			
			var neighbor_clue_count: int = 0
			for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
				var neighbor: Vector2i = liberty + neighbor_dir
				if scanner_board.clues.has(neighbor):
					neighbor_clue_count += 1
			var reason: Deduction.Reason = ISLAND_DIVIDER if neighbor_clue_count <= 1 else ADJACENT_CLUES
			monster.add_pending_deduction(liberty, CELL_WALL, reason)
