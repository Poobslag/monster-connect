extends TestMutationLibrary

func test_mutate_fix_enclosed_walls() -> void:
	var grid: Array[String] = [
		" . .######",
		" .#### .##",
		" 8 . . .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_enclosed_walls(board)
	
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).size(), 12)
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).clue, 12)
	assert_eq(board.get_cell(Vector2i(1, 1)), CELL_ISLAND)
	assert_eq(board.get_cell(Vector2i(3, 0)), CELL_ISLAND)


func test_mutate_fix_enclosed_walls_complex() -> void:
	var grid: Array[String] = [
		" . .######",
		" .#### .##",
		" .#### .##",
		"10 . . .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_enclosed_walls(board)
	
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).size(), 16)
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).clue, 16)
	assert_eq(board.get_cell(Vector2i(1, 1)), CELL_ISLAND)
	assert_eq(board.get_cell(Vector2i(3, 0)), CELL_ISLAND)


func test_mutate_fix_enclosed_walls_ok() -> void:
	var grid: Array[String] = [
		" . 5 . . .#### . 2##",
		"########## 3########",
		"## 4 . .## .## . 2##",
		" .## .#### .###### 4",
		" 2#### 1#### .## . .",
		"## 3#### 4## 2#### .",
		"## . .## .#### 3####",
		"######## . .## . .##",
		" 3 . .##############",
		"######## 1## . 3 .##",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_enclosed_walls(board)
	assert_eq(board.to_grid_string(), "\n".join(grid))


func test_mutate_fix_joined_islands() -> void:
	var grid: Array[String] = [
		" . 2######",
		"## .## .##",
		" 5 . . .##",
		"##########",
		" 5 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_joined_islands(board)
	
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).size(), 8)
	assert_eq(board.get_island_for_cell(Vector2i(0, 2)).clue, 8)


func test_mutate_fix_pools() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"##########",
		" 3 . .####",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_pools(board)
	
	var validation_errors: SolverBoard.ValidationResult = board.validate(SolverBoard.VALIDATE_SIMPLE)
	assert_eq([], validation_errors.pools)


func test_mutate_fix_split_walls() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"######## .",
		" 6 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_split_walls(board)
	
	var validation_errors: SolverBoard.ValidationResult = board.validate(SolverBoard.VALIDATE_SIMPLE)
	assert_eq([], validation_errors.split_walls)


func test_mutate_fix_split_walls_wide() -> void:
	var grid: Array[String] = [
		" 1## . . .",
		"#### . . .",
		" . . . . .",
		" . . .####",
		" . . .## 1",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_split_walls(board)
	
	var validation_errors: SolverBoard.ValidationResult = board.validate(SolverBoard.VALIDATE_SIMPLE)
	assert_eq([], validation_errors.split_walls)


func test_mutate_fix_unclued_islands_clue() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"##########",
		" . . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_unclued_islands_clue(board)
	
	var validation_errors: SolverBoard.ValidationResult = board.validate(SolverBoard.VALIDATE_SIMPLE)
	assert_eq([], validation_errors.unclued_islands)


func test_mutate_fix_unclued_islands_join() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"##########",
		" . . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_unclued_islands_join(board)
	
	var validation_errors: SolverBoard.ValidationResult = board.validate(SolverBoard.VALIDATE_SIMPLE)
	assert_eq([], validation_errors.unclued_islands)


func test_mutate_fix_wrong_size() -> void:
	var grid: Array[String] = [
		" . 2######",
		"###### .##",
		" 5 . . .##",
		"##########",
		" 3 . . . .",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_fix_wrong_size(board)
	
	var validation_errors: SolverBoard.ValidationResult = board.validate(SolverBoard.VALIDATE_SIMPLE)
	assert_eq([], validation_errors.wrong_size)
