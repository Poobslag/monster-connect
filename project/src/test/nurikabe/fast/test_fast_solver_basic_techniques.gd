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
	assert_deduction(solver.enqueue_islands, expected)


func test_clued_islands_island_expansion() -> void:
	grid = [
		" 4    ",
		"####  ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 0), CELL_ISLAND, "island_expansion (0, 0)"),
	]
	assert_deduction(solver.enqueue_islands, expected)


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
	assert_deduction(solver.enqueue_islands, expected)


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


func test_unreachable_square_1() -> void:
	grid = [
		" 4    ",
		"      ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2(2, 2), CELL_WALL, "unreachable_square (0, 0)"),
	]
	assert_deduction(solver.enqueue_unreachable_squares, expected)


func test_unreachable_square_2() -> void:
	grid = [
		" 4##  ",
		" .    ",
		"      ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2(2, 0), CELL_WALL, "unreachable_square (0, 0)"),
		FastDeduction.new(Vector2(2, 2), CELL_WALL, "unreachable_square (0, 0)"),
	]
	assert_deduction(solver.enqueue_unreachable_squares, expected)


func test_unreachable_square_3() -> void:
	grid = [
		"   .    ",
		"    ## 2",
		" . 7   .",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2(2, 2), CELL_WALL, "island_divider (0, 2) (3, 1)"),
		FastDeduction.new(Vector2(3, 0), CELL_WALL, "unreachable_square (3, 1)"),
	]
	assert_deduction(solver.enqueue_unreachable_squares, expected)


func test_unreachable_square_blocked() -> void:
	# the upper right cell is reachable by the 4, but it's blocked by the 3
	grid = [
		" 4        ",
		"     3    ",
		"         2",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2(4, 0), CELL_WALL, "unreachable_square (4, 2)"),
	]
	assert_deduction(solver.enqueue_unreachable_squares, expected)


func test_wall_bubble_surrounded_square() -> void:
	grid = [
		" 3  ######  ",
		"  ####      ",
		"## 1## 2##  ",
		"  ##  ## 5  ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(0, 3), CELL_WALL, "wall_bubble"),
		FastDeduction.new(Vector2i(2, 3), CELL_WALL, "wall_bubble"),
	]
	assert_deduction(solver.enqueue_unreachable_squares, expected)


func test_island_connector() -> void:
	grid = [
		"     6",
		"##    ",
		" .    ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 2), CELL_ISLAND, "island_connector (0, 2)"),
	]
	assert_deduction(solver.enqueue_islands, expected)
