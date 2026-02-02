class_name ScannerBoard
## Time-budgeted board topology model for NaiveSolver scanners.[br]
## [br]
## Builds island groups, wall groups and liberty data incrementally across frames to avoid performance spikes when
## multiple AI agents solve puzzles simultaneously.

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS

var groups_by_cell: Dictionary[Vector2i, CellGroup] = {}
var islands: Array[CellGroup] = []
var walls: Array[CellGroup] = []
var cells: Dictionary[Vector2i, int] = {}
var clues: Dictionary[Vector2i, int] = {}

var _monster: SimMonster
var _cell_list: Array[Vector2i]
var _next_cell_index: int = 0

func _init(init_monster: SimMonster) -> void:
	_monster = init_monster
	
	var board_cells: Dictionary[Vector2i, int] = _monster.solving_board.get_cells()
	for cell: Vector2i in board_cells:
		var cell_value: int = board_cells[cell]
		if NurikabeUtils.is_clue(cell_value):
			clues[cell] = cell_value
			cells[cell] = CELL_ISLAND
		else:
			cells[cell] = cell_value
	
	_cell_list = cells.keys()


func prepare(start_time: int) -> void:
	while _next_cell_index < _cell_list.size():
		_build_group(_cell_list[_next_cell_index])
		_next_cell_index += 1
		if Time.get_ticks_usec() - start_time > NaiveSolver.BUDGET_USEC:
			break


func is_prepared() -> bool:
	return _next_cell_index >= _cell_list.size()


func _build_group(start_cell: Vector2i) -> void:
	if cells[start_cell] == CELL_EMPTY:
		return
	if groups_by_cell.has(start_cell):
		return
	
	# bfs to other matching cells
	var visited: Dictionary[Vector2i, bool] = {start_cell: true}
	var queue: Array[Vector2i] = [start_cell]
	var current_index: int = 0
	var group: CellGroup = CellGroup.new()
	group.cells.append(start_cell)
	while current_index < queue.size():
		var next_cell: Vector2i = queue[current_index]
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = next_cell + neighbor_dir
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			var neighbor_value: int = cells.get(neighbor, CELL_INVALID)
			if neighbor_value == CELL_INVALID:
				continue
			if neighbor_value == CELL_EMPTY:
				group.liberties.append(neighbor)
			elif neighbor_value == cells[next_cell]:
				group.cells.append(neighbor)
				queue.append(neighbor)
		current_index += 1
	
	# assign island clue value
	if cells.get(start_cell) == CELL_ISLAND:
		for cell: Vector2i in group.cells:
			if not clues.has(cell):
				continue
			if group.clue > 0:
				group.clue = -1
				break
			group.clue = clues[cell]
	
	# populate groups_by_cell, walls, islands
	for cell: Vector2i in group.cells:
		groups_by_cell[cell] = group
	if cells.get(start_cell) == CELL_WALL:
		walls.append(group)
	if cells.get(start_cell) == CELL_ISLAND:
		islands.append(group)
