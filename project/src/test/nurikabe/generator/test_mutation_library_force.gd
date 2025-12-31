extends TestMutationLibrary

func test_mutate_force_exaggerate() -> void:
	var grid: Array[String] = [
		"          ",
		"          ",
		"11        ",
		"####      ",
		" 5 . .    ",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_force_exaggerate(board)
	
	var solver: Solver = Solver.new()
	solver.board = board
	solver.step_until_done(Solver.SolverPass.BIFURCATION)
	assert_eq(board.is_filled(), true)


func test_mutate_force_exaggerate_single() -> void:
	var grid: Array[String] = [
		"          ",
		"          ",
		"11        ",
		"######    ",
		" 3 . .##  ",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_force_exaggerate(board)
	assert_eq(board.get_clue(Vector2i(0, 2)), 18)


func test_mutate_force_inject() -> void:
	var grid: Array[String] = [
		"          ",
		"          ",
		"11        ",
		"####      ",
		" 5 . .    ",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_force_inject(board)
	
	var solver: Solver = Solver.new()
	solver.board = board
	solver.step_until_done(Solver.SolverPass.BIFURCATION)
	assert_eq(board.is_filled(), true)


func test_mutate_force_partition() -> void:
	var grid: Array[String] = [
		"          ",
		"          ",
		"11        ",
		"####      ",
		" 5 . .    ",
	]
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string("\n".join(grid))
	mutation_library.mutate_force_partition(board)
	assert_eq(1, board.get_clue(Vector2i(0, 2)))
	assert_eq(3, board.get_clue(Vector2i(0, 4)))
	assert_eq(15, board.get_island_for_cell(Vector2i(0, 0)).clue)
