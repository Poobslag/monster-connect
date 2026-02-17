extends TestMutationLibrary

func test_find_dead_end_walls() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var dead_end_walls: Array[Vector2i] = mutation_library.find_dead_end_walls(board)
	assert_eq(dead_end_walls, [Vector2i(0, 1), Vector2i(0, 3)])


func test_carve_wall_cells() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.carve_wall_cells(board, Vector2i(0, 1))
	
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).clue, 12)
	assert_eq(12, board.get_clue(Vector2i(0, 2)))
	assert_eq(board.get_cell(Vector2i(0, 1)), CELL_ISLAND)
	assert_eq(board.get_cell(Vector2i(3, 0)), CELL_ISLAND)


func test_get_possible_island_splits() -> void:
	var grid: Array[String] = [
		"15## 2## .",
		" .## .## .",
		" .###### .",
		" . . . . .",
		" . . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var split_options: Array[MutationLibrary.IslandSplit] \
			= mutation_library.get_possible_island_splits(board.get_island_for_cell(Vector2i(0, 0)))
	var split_option_strings: Array[String] = []
	for split_option: MutationLibrary.IslandSplit in split_options:
		split_option_strings.append(str(split_option))
	split_option_strings.sort()
	assert_eq(split_option_strings, [
		"cell (0, 1)",
		"cell (0, 2)",
		"cell (0, 3)",
		"cell (4, 1)",
		"cell (4, 2)",
		"cell (4, 3)",
		"horizontal (0, 1)",
		"horizontal (0, 2)",
		"horizontal (0, 3)",
		"vertical (1, 0)",
		"vertical (2, 0)",
		"vertical (3, 0)",
		])
	board.cleanup()


func test_cleave_island_cell() -> void:
	var grid: Array[String] = [
		"15## 2## .",
		" .## .## .",
		" .###### .",
		" . . . . .",
		" . . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var island: CellGroup = board.get_island_for_cell(Vector2i(0, 0))
	var island_split: MutationLibrary.IslandSplit = \
			MutationLibrary.IslandSplit.new(MutationLibrary.SPLIT_CELL, Vector2i(0, 2))
	mutation_library.cleave_island(board, island, island_split)
	
	assert_board(board, [
			" 2## 2##13",
			" .## .## .",
			"######## .",
			" . . . . .",
			" . . . . .",
		])
	board.cleanup()


func test_cleave_island_horizontal() -> void:
	var grid: Array[String] = [
		"15## .## .",
		" .## 2## .",
		" .###### .",
		" . . . . .",
		" . . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var island: CellGroup = board.get_island_for_cell(Vector2i(0, 2))
	var island_split: MutationLibrary.IslandSplit = \
			MutationLibrary.IslandSplit.new(MutationLibrary.SPLIT_HORIZONTAL, Vector2i(0, 2))
	mutation_library.cleave_island(board, island, island_split)
	
	assert_board(board, [
			" 2## .## .",
			" .## 2## 2",
			"##########",
			" . .10 . .",
			" . . . . .",
		])
	board.cleanup()


func test_cleave_island_vertical() -> void:
	var grid: Array[String] = [
		"15## .## .",
		" .## 2## .",
		" .###### .",
		" . . . . .",
		" . . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var island: CellGroup = board.get_island_for_cell(Vector2i(0, 2))
	var island_split: MutationLibrary.IslandSplit = \
			MutationLibrary.IslandSplit.new(MutationLibrary.SPLIT_VERTICAL, Vector2i(1, 0))
	mutation_library.cleave_island(board, island, island_split)
	
	assert_board(board, [
			" 5## .## .",
			" .## 2## .",
			" .###### .",
			" .## 9 . .",
			" .## . . .",
		])
	board.cleanup()


func test_mutate_break_wall_loop() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### 2##",
		" 2 .## .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_break_wall_loop(board)
	var cuttable_loop_cells: Array[Vector2i] = mutation_library.find_cuttable_loop_cells(board)
	assert_eq(cuttable_loop_cells, [])
	board.cleanup()


func test_find_cuttable_loop_cells() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### 2##",
		" 2 .## .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var cuttable_loop_cells: Array[Vector2i] = mutation_library.find_cuttable_loop_cells(board)
	cuttable_loop_cells.sort()
	
	assert_eq(cuttable_loop_cells, [
			Vector2i(2, 0), Vector2i(2, 2),
			Vector2i(3, 0), Vector2i(3, 3),
			Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3),
		])
	board.cleanup()


func test_mutate_rebalance_neighbor_islands() -> void:
	var grid: Array[String] = [
		" 3 . .####",
		"######## .",
		" 7 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_rebalance_neighbor_islands(board)
	assert_ne(board.get_clue(Vector2i(0, 0)), 3)
	assert_ne(board.get_clue(Vector2i(0, 2)), 7)
	board.cleanup()


func test_move_clue() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var island: CellGroup = board.get_island_for_cell(Vector2i(0, 2))
	mutation_library.move_clue(board, island)
	assert_eq(board.has_clue(Vector2i(0, 2)), false)
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).clue, 5)
	board.cleanup()


func test_move_clue_single() -> void:
	var grid: Array[String] = [
		"##########",
		" 4 . . .##",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	var island: CellGroup = board.get_island_for_cell(Vector2i(0, 1))
	mutation_library.move_clue(board, island)
	assert_eq(board.has_clue(Vector2i(0, 1)), false)
	assert_eq(board.get_island_for_cell(Vector2i(0, 1)).clue, 4)
	board.cleanup()


func assert_board(board: SolverBoard, expected: Array[String]) -> void:
	assert_eq(board.to_grid_string().split("\n"), PackedStringArray(expected))
