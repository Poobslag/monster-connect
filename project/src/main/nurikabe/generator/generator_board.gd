class_name GeneratorBoard

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

var solver_board: SolverBoard = SolverBoard.new()

var version: int:
	get():
		return solver_board.version

var clue_minimums: Dictionary[Vector2i, int]
var clue_maximums: Dictionary[Vector2i, int]

var cells: Dictionary[Vector2i, int]:
	get():
		return solver_board.cells
var clues: Dictionary[Vector2i, int]:
	get():
		return solver_board.clues
var empty_cells: Dictionary[Vector2i, bool] = {}:
	get:
		return solver_board.empty_cells
var groups_by_cell: Dictionary[Vector2i, CellGroup] = {}:
	get:
		return solver_board.groups_by_cell
var islands: Array[CellGroup] = []:
	get:
		return solver_board.islands
var walls: Array[CellGroup] = []:
	get:
		return solver_board.walls

func clear() -> void:
	clue_minimums.clear()
	clue_maximums.clear()
	solver_board.clear()


func from_game_board(game_board: NurikabeGameBoard) -> void:
	solver_board.from_game_board(game_board)
	solver_board.allow_unclued_islands = true


func is_filled() -> bool:
	var result: bool = false
	if solver_board.is_filled():
		result = solver_board.islands.all(func(island: CellGroup) -> bool:
			return island.clue != CELL_MYSTERY_CLUE)
	return result


func set_cell(cell_pos: Vector2i, value: int) -> void:
	solver_board.set_cell(cell_pos, value)


func set_clue_minimum(cell_pos: Vector2i, value: int) -> void:
	clue_maximums[cell_pos] = value


## Sets the specified cells on the model.[br]
## [br]
## Accepts a dictionary with the following keys:[br]
## 	'pos': (Vector2i) The cell to update.[br]
## 	'value': (String) The value to assign.[br]
func set_cells(changes: Array[Dictionary]) -> void:
	solver_board.set_cells(changes)


func set_clue(cell_pos: Vector2i, value: int) -> void:
	solver_board.set_clue(cell_pos, value)


func get_cell(cell_pos: Vector2i) -> int:
	return solver_board.get_cell(cell_pos)


func get_clue(cell_pos: Vector2i) -> int:
	return clues[cell_pos]


func get_island_for_cell(cell: Vector2i) -> CellGroup:
	return solver_board.get_island_for_cell(cell)


func has_clue(cell_pos: Vector2i) -> int:
	return solver_board.has_clue(cell_pos)
