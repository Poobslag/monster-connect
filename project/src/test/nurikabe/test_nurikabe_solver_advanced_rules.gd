extends TestNurikabeSolver

func test_bifurcation() -> void:
	grid = [
		"##   .  ",
		"##    ##",
		"## . 7##",
		"##  ####",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, BIFURCATION),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, BIFURCATION),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_ISLAND, BIFURCATION),
		NurikabeDeduction.new(Vector2i(3, 0), CELL_ISLAND, BIFURCATION),
	]
	assert_deduction(solver.deduce_bifurcation, expected)
