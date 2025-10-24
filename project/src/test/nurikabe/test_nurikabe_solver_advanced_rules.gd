extends TestNurikabeSolver

func test_forbidden_courtyard() -> void:
	grid = [
		"         6  ",
		"     4      ",
		" 2  ##      ",
		"     2      ",
		"            ",
		"         7  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 4), CELL_WALL, FORBIDDEN_COURTYARD),
	]
	assert_deduction(solver.deduce_forbidden_courtyard, expected)


func test_last_light() -> void:
	grid = [
		"         6  ",
		"     4      ",
		" 2  ##      ",
		"     2      ",
		"    ##      ",
		"         7  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 5), CELL_ISLAND, LAST_LIGHT),
		NurikabeDeduction.new(Vector2i(2, 5), CELL_ISLAND, LAST_LIGHT),
		NurikabeDeduction.new(Vector2i(3, 5), CELL_ISLAND, LAST_LIGHT),
	]
	assert_deduction(solver.deduce_last_light, expected)
