extends TestSolver

func test_islands_of_one() -> void:
	grid = [
		"      ",
		"   1  ",
		"      ",
	]
	var expected: Array[String] = [
		"(0, 1)->## island_of_one (1, 1)",
		"(1, 0)->## island_of_one (1, 1)",
		"(1, 2)->## island_of_one (1, 1)",
		"(2, 1)->## island_of_one (1, 1)",
	]
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_island_of_one_corners() -> void:
	grid = [
		" 1  ",
		"    ",
		"   1",
	]
	var expected: Array[String] = [
		"(0, 1)->## island_of_one (0, 0)",
		"(0, 2)->## island_of_one (1, 2)",
		"(1, 0)->## island_of_one (0, 0)",
		"(1, 1)->## island_of_one (1, 2)",
	]
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_adjacent_clues_1() -> void:
	grid = [
		" 2    ",
		"      ",
		" 2    ",
	]
	var expected: Array[String] = [
		"(0, 1)->## adjacent_clues (0, 0) (0, 2)",
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)


func test_deduce_adjacent_clues_2() -> void:
	grid = [
		" 2   2",
		"      ",
		"      ",
	]
	var expected: Array[String] = [
		"(1, 0)->## adjacent_clues (0, 0) (2, 0)",
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)


func test_deduce_diagonal_clues_1() -> void:
	grid = [
		"          ",
		"   9      ",
		"     2    ",
		"          ",
	]
	var expected: Array[String] = [
		"(1, 2)->## adjacent_clues (1, 1) (2, 2)",
		"(2, 1)->## adjacent_clues (1, 1) (2, 2)",
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)


func test_deduce_diagonal_clues_2() -> void:
	grid = [
		"          ",
		"       9  ",
		"     2    ",
		"          ",
	]
	var expected: Array[String] = [
		"(2, 1)->## adjacent_clues (2, 2) (3, 1)",
		"(3, 2)->## adjacent_clues (2, 2) (3, 1)",
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)


func test_deduce_diagonal_clues_3() -> void:
	grid = [
		"           ",
		"   1   1   ",
		"     1     ",
		"           ",
	]
	var expected: Array[String] = [
		"(1, 2)->## adjacent_clues (1, 1) (2, 2)",
		"(2, 1)->## adjacent_clues (1, 1) (2, 2) (3, 1)",
		"(3, 2)->## adjacent_clues (2, 2) (3, 1)",
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)
