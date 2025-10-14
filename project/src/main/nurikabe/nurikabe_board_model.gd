class_name NurikabeBoardModel

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

const NEIGHBOR_DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var cells: Dictionary[Vector2i, String]

func from_game_board(game_board: NurikabeGameBoard) -> void:
	for cell_pos in game_board.get_used_cells():
		set_cell_string(cell_pos, game_board.get_cell_string(cell_pos))


func get_cell_string(cell_pos: Vector2i) -> String:
	return cells.get(cell_pos, CELL_INVALID)


func set_cell_string(cell_pos: Vector2i, value: String) -> void:
	cells[cell_pos] = value


func surround_island(cell_pos: Vector2i) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	
	var clue_cells: Dictionary[Vector2i, bool] = {}
	var island_cells: Dictionary[Vector2i, bool] = {}
	var ignored_cells: Dictionary[Vector2i, bool] = {}
	var cells_to_check: Dictionary[Vector2i, bool] = {cell_pos: true}
	while not cells_to_check.is_empty():
		var next_cell: Vector2i = cells_to_check.keys().front()
		cells_to_check.erase(next_cell)
		
		var next_cell_string: String = get_cell_string(next_cell)
		if next_cell_string == CELL_ISLAND:
			island_cells[next_cell] = true
		elif next_cell_string.is_valid_int():
			clue_cells[next_cell] = true
		else:
			ignored_cells[next_cell] = true
			continue
		
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor_cell: Vector2i = next_cell + neighbor_dir
			if ignored_cells.has(neighbor_cell) \
					or island_cells.has(neighbor_cell) \
					or clue_cells.has(neighbor_cell) \
					or cells_to_check.has(neighbor_cell) \
					or get_cell_string(neighbor_cell) == CELL_INVALID:
				continue
			cells_to_check[neighbor_cell] = true
	
	if clue_cells.size() == 1 and island_cells.size() == int(get_cell_string(clue_cells.keys().front())) - 1:
		for ignored_cell: Vector2i in ignored_cells:
			if get_cell_string(ignored_cell) == CELL_EMPTY:
				changes.append({"pos": ignored_cell, "value": CELL_WALL})
	
	return changes
