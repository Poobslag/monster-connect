extends TestFastSolver

func test_clued_islands_add_island_moat() -> void:
	grid = [
		" 2    ",
		" .    ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 0), CELL_WALL, "island_moat (0, 0)"),
		FastDeduction.new(Vector2i(1, 1), CELL_WALL, "island_moat (0, 0)"),
		FastDeduction.new(Vector2i(0, 2), CELL_WALL, "island_moat (0, 0)"),
	]
	assert_deduction(solver.enqueue_clued_islands, expected)


func test_clued_islands_island_expansion() -> void:
	grid = [
		" 4    ",
		"####  ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 0), CELL_ISLAND, "island_expansion (0, 0)"),
	]
	assert_deduction(solver.enqueue_clued_islands, expected)


func test_clued_islands_island_expansion_and_moat() -> void:
	grid = [
		" 2    ",
		"##    ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 0), CELL_ISLAND, "island_expansion (0, 0)"),
		FastDeduction.new(Vector2i(2, 0), CELL_WALL, "island_moat (0, 0)"),
		FastDeduction.new(Vector2i(1, 1), CELL_WALL, "island_moat (0, 0)"),
	]
	assert_deduction(solver.enqueue_clued_islands, expected)


func test_wall_expansions_1() -> void:
	grid = [
		"## 4  ",
		"      ",
		"    ##",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(0, 1), CELL_WALL, "wall_expansion (0, 0)"),
	]
	assert_deduction(solver.enqueue_walls, expected)


func test_island_dividers_1() -> void:
	grid = [
		" .   3",
		" 3    ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 0), CELL_WALL, "island_divider (0, 0) (2, 0)"),
	]
	assert_deduction(solver.enqueue_island_dividers, expected)


func test_pool_triplets_1() -> void:
	grid = [
		" 4    ",
		"    ##",
		"  ####",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 1), CELL_ISLAND, "pool_triplet (1, 2) (2, 1) (2, 2)"),
	]
	assert_deduction(solver.enqueue_walls, expected)


func test_pool_triplets_invalid() -> void:
	grid = [
		" 3#### 3",
		"        ",
		"  ####  ",
	]
	var expected: Array[FastDeduction] = [
	]
	assert_deduction(solver.enqueue_walls, expected)
