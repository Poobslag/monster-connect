extends TestFastSolver

func test_islands_of_one() -> void:
	grid = [
		"      ",
		"   1  ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(0, 1), CELL_WALL, "island_of_one (1, 1)"),
		FastDeduction.new(Vector2i(1, 0), CELL_WALL, "island_of_one (1, 1)"),
		FastDeduction.new(Vector2i(1, 2), CELL_WALL, "island_of_one (1, 1)"),
		FastDeduction.new(Vector2i(2, 1), CELL_WALL, "island_of_one (1, 1)"),
	]
	assert_deduction(solver.enqueue_islands_of_one, expected)


func test_deduce_island_of_one_corners() -> void:
	grid = [
		" 1  ",
		"    ",
		"   1",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(0, 1), CELL_WALL, "island_of_one (0, 0)"),
		FastDeduction.new(Vector2i(0, 2), CELL_WALL, "island_of_one (1, 2)"),
		FastDeduction.new(Vector2i(1, 0), CELL_WALL, "island_of_one (0, 0)"),
		FastDeduction.new(Vector2i(1, 1), CELL_WALL, "island_of_one (1, 2)"),
	]
	assert_deduction(solver.enqueue_islands_of_one, expected)


func test_deduce_adjacent_clues_1() -> void:
	grid = [
		" 2    ",
		"      ",
		" 2    ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(0, 1), CELL_WALL, "adjacent_clues (0, 0) (0, 2)"),
	]
	assert_deduction(solver.enqueue_adjacent_clues, expected)


func test_deduce_adjacent_clues_2() -> void:
	grid = [
		" 2   2",
		"      ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 0), CELL_WALL, "adjacent_clues (0, 0) (2, 0)"),
	]
	assert_deduction(solver.enqueue_adjacent_clues, expected)


func test_deduce_diagonal_clues_1() -> void:
	grid = [
		"          ",
		"   9      ",
		"     2    ",
		"          ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 2), CELL_WALL, "adjacent_clues (1, 1) (2, 2)"),
		FastDeduction.new(Vector2i(2, 1), CELL_WALL, "adjacent_clues (2, 2) (1, 1)"),
	]
	assert_deduction(solver.enqueue_adjacent_clues, expected)


func test_deduce_diagonal_clues_2() -> void:
	grid = [
		"          ",
		"       9  ",
		"     2    ",
		"          ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(2, 1), CELL_WALL, "adjacent_clues (2, 2) (3, 1)"),
		FastDeduction.new(Vector2i(3, 2), CELL_WALL, "adjacent_clues (3, 1) (2, 2)"),
	]
	assert_deduction(solver.enqueue_adjacent_clues, expected)


func test_deduce_diagonal_clues_3() -> void:
	grid = [
		"           ",
		"   1   1   ",
		"     1     ",
		"           ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 2), CELL_WALL, "adjacent_clues (1, 1) (2, 2)"),
		FastDeduction.new(Vector2i(2, 1), CELL_WALL, "adjacent_clues (2, 2) (1, 1)"),
		FastDeduction.new(Vector2i(3, 2), CELL_WALL, "adjacent_clues (3, 1) (2, 2)"),
	]
	assert_deduction(solver.enqueue_adjacent_clues, expected)
