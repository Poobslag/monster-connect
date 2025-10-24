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


func test_dead_end_wall() -> void:
	grid = [
		" 3          ",
		"     3      ",
		"            ",
		"   2       2",
		"            ",
		"       7    ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(4, 4), CELL_WALL, DEAD_END_WALL),
	]
	assert_deduction(solver.deduce_dead_end_wall, expected)


func text_wall_strangle() -> void:
	grid = [
		" . . . .    ",
		" 6####      ",
		"##          ",
		"## 2        ",
		"    ####    ",
		"            ",
		"            ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(4, 4), CELL_WALL, WALL_STRANGLE),
	]
	assert_deduction(solver.deduce_wall_strangle, expected)
