extends TestNurikabeSolver

func test_deduce_island_of_one() -> void:
	grid = [
		"      ",
		"   1  ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, ISLAND_OF_ONE),
		NurikabeDeduction.new(Vector2i(1, 0), CELL_WALL, ISLAND_OF_ONE),
		NurikabeDeduction.new(Vector2i(1, 2), CELL_WALL, ISLAND_OF_ONE),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_WALL, ISLAND_OF_ONE),
	]
	assert_deduction(solver.deduce_island_of_one, expected)


func test_deduce_island_of_one_corners() -> void:
	grid = [
		" 1  ",
		"    ",
		"   1",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, ISLAND_OF_ONE),
		NurikabeDeduction.new(Vector2i(0, 2), CELL_WALL, ISLAND_OF_ONE),
		NurikabeDeduction.new(Vector2i(1, 0), CELL_WALL, ISLAND_OF_ONE),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_WALL, ISLAND_OF_ONE),
	]
	assert_deduction(solver.deduce_island_of_one, expected)


func test_deduce_adjacent_clues_1() -> void:
	grid = [
		" 2    ",
		"      ",
		" 2    ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, ADJACENT_CLUES),
	]
	assert_deduction(solver.deduce_adjacent_clues, expected)


func test_deduce_adjacent_clues_2() -> void:
	grid = [
		" 2   2",
		"      ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_WALL, ADJACENT_CLUES),
	]
	assert_deduction(solver.deduce_adjacent_clues, expected)


func test_deduce_diagonal_clues_1() -> void:
	grid = [
		"          ",
		"   9      ",
		"     2    ",
		"          ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 2), CELL_WALL, DIAGONAL_CLUES),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_WALL, DIAGONAL_CLUES),
	]
	assert_deduction(solver.deduce_adjacent_clues, expected)


func test_deduce_diagonal_clues_2() -> void:
	grid = [
		"          ",
		"       9  ",
		"     2    ",
		"          ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 1), CELL_WALL, DIAGONAL_CLUES),
		NurikabeDeduction.new(Vector2i(3, 2), CELL_WALL, DIAGONAL_CLUES),
	]
	assert_deduction(solver.deduce_adjacent_clues, expected)


func test_deduce_diagonal_clues_3() -> void:
	grid = [
		"           ",
		"   1   1   ",
		"     1     ",
		"           ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 2), CELL_WALL, DIAGONAL_CLUES),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_WALL, ADJACENT_CLUES),
		NurikabeDeduction.new(Vector2i(3, 2), CELL_WALL, DIAGONAL_CLUES),
	]
	assert_deduction(solver.deduce_adjacent_clues, expected)
