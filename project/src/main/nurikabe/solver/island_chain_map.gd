class_name IslandChainMap

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

## Virtual root node for islands touching the puzzle border.
var _border_island: CellGroup = CellGroup.new()

var _board: SolverBoard
var _parent_by_island: Dictionary[CellGroup, CellGroup] = {}
var _chain_id_by_island: Dictionary[CellGroup, int] = {}
var _depth_by_island: Dictionary[CellGroup, int] = {}
var _diagonal_island_neighbors: Dictionary[CellGroup, Array] = {}

func _init(init_board: SolverBoard) -> void:
	_board = init_board
	_build_diagonal_island_neighbors()
	_build_chains()


func has_chain_conflict(cell: Vector2i, start_numbered_island_count: int = 0) -> bool:
	return not find_chain_conflicts(cell, start_numbered_island_count).is_empty()


func find_chain_conflicts(cell: Vector2i, start_numbered_island_count: int = 0) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var connected_islands: Array[CellGroup] = []
	for neighbor_dir: Vector2i in [
				Vector2(-1, -1), Vector2(-1,  0), Vector2(-1,  1), Vector2( 0, -1),
				Vector2( 0,  1), Vector2( 1, -1), Vector2( 1,  0), Vector2( 1,  1),
			]:
		var neighbor: Vector2i = cell + neighbor_dir
		if _board.get_cell(neighbor) != CELL_ISLAND:
			continue
		var connected_island: CellGroup = _board.get_island_for_cell(neighbor)
		if not connected_islands.has(connected_island):
			connected_islands.append(connected_island)
	if _board.is_border_cell(cell):
		connected_islands.append(_border_island)
	
	for i: int in connected_islands.size():
		for j: int in range(i + 1, connected_islands.size()):
			var island_1: CellGroup = connected_islands[i]
			var island_2: CellGroup = connected_islands[j]
			if _chain_id_by_island[island_1] != _chain_id_by_island[island_2]:
				continue
			if _illegal_endpoint_connection(island_1, island_2, start_numbered_island_count):
				result = [island_1.root, island_2.root]
				break
		if result:
			break
	
	return result


func _build_diagonal_island_neighbors() -> void:
	for island: CellGroup in _board.islands:
		_diagonal_island_neighbors[island] = []
	for island: CellGroup in _board.islands:
		for cell: Vector2i in island.cells:
			for neighbor_dir: Vector2i in [Vector2i(1, -1), Vector2i(1, 1)]:
				var neighbor: Vector2i = cell + neighbor_dir
				if _board.get_cell(neighbor) != CELL_ISLAND:
					continue
				var neighbor_island: CellGroup = _board.get_island_for_cell(neighbor)
				if neighbor_island == island:
					continue
				if _diagonal_island_neighbors[island].has(neighbor_island):
					continue
				_diagonal_island_neighbors[island].append(neighbor_island)
				_diagonal_island_neighbors[neighbor_island].append(island)


func _build_chains() -> void:
	_parent_by_island[_border_island] = null
	_chain_id_by_island[_border_island] = 0
	_depth_by_island[_border_island] = 0
	
	var central_islands: Array[CellGroup] = []
	var next_chain_id: int = 1
	for island: CellGroup in _board.islands:
		if _chain_id_by_island.has(island):
			continue
		var is_border_island: bool = false
		for cell: Vector2i in island.cells:
			if _board.is_border_cell(cell):
				is_border_island = true
				break
		if is_border_island:
			_parent_by_island[island] = _border_island
			_chain_id_by_island[island] = 0
			_depth_by_island[island] = _depth_by_island[_border_island] + 1
			_expand_chain(island)
		else:
			central_islands.append(island)
	
	for island: CellGroup in central_islands:
		if _chain_id_by_island.has(island):
			continue
		_chain_id_by_island[island] = next_chain_id
		_depth_by_island[island] = 0
		_expand_chain(island)
		next_chain_id += 1


func _expand_chain(start_island: CellGroup) -> void:
	var queue: Array[CellGroup] = [start_island]
	var queue_index: int = 0
	while queue_index < queue.size():
		var island: CellGroup = queue[queue_index]
		queue_index += 1
		
		for neighbor_island: CellGroup in _diagonal_island_neighbors[island]:
			if _chain_id_by_island.has(neighbor_island):
				continue
			_parent_by_island[neighbor_island] = island
			_chain_id_by_island[neighbor_island] = _chain_id_by_island[island]
			_depth_by_island[neighbor_island] = _depth_by_island[island] + 1
			queue.append(neighbor_island)


func _has_clue(island: CellGroup) -> bool:
	return island.clue >= 1 or island.clue == CELL_MYSTERY_CLUE


func _illegal_endpoint_connection(island_1: CellGroup, island_2: CellGroup, start_numbered_island_count: int = 0) -> bool:
	var numbered_island_count: int = start_numbered_island_count
	if _has_clue(island_1): numbered_island_count += 1
	if _has_clue(island_2): numbered_island_count += 1
	if numbered_island_count >= 2:
		return true
	
	var a: CellGroup = island_1
	var b: CellGroup = island_2
	while a != b:
		var visited: CellGroup
		if _depth_by_island[a] > _depth_by_island[b]:
			a = _parent_by_island[a]
			visited = a
		else:
			b = _parent_by_island[b]
			visited = b
		if _has_clue(visited) and a != b:
			numbered_island_count += 1
			if numbered_island_count >= 2:
				break
	
	return numbered_island_count >= 2
