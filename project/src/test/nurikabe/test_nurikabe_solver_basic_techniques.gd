extends TestNurikabeSolver

func test_uncompletable_islands_good() -> void:
	grid = [
		" 3   3",
		"      ",
		"      ",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 0)


func test_uncompletable_islands_walled_in_1() -> void:
	grid = [
		" 3## 3",
		"##    ",
		"      ",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 1)


func test_uncompletable_islands_walled_in_2() -> void:
	grid = [
		" 3## 3",
		"  ##  ",
		"####  ",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 1)


func test_uncompletable_islands_walled_in_3() -> void:
	grid = [
		" 3## 3",
		" .## .",
		"#### .",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 1)


func test_uncompletable_islands_too_close_1() -> void:
	grid = [
		" 3## 2",
		" . .  ",
		"      ",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 1)


func test_uncompletable_islands_too_close_2() -> void:
	grid = [
		"#### 3",
		" 3##  ",
		" . .  ",
		"      ",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 1)


func test_uncompletable_islands_too_close_3() -> void:
	grid = [
		"#### 2",
		" . .  ",
		"      ",
		" 4    ",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 1)


func test_uncompletable_islands_too_close_4() -> void:
	grid = [
		" 1## . .",
		"####   5",
		"## . .  ",
		"        ",
		"        ",
		" 5      ",
	]
	var board: NurikabeBoardModel = init_model()
	assert_eq(solver.get_uncompletable_island_count(board), 1)


func test_island_divider_2() -> void:
	grid = [
		" 3   3",
		"      ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_WALL, ISLAND_DIVIDER),
	]
	assert_deduction(solver.deduce_island_divider, expected)


func test_island_divider_3() -> void:
	grid = [
		" 1      ",
		"   2   3",
		"        ",
		"        ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_WALL, ISLAND_DIVIDER),
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, ISLAND_DIVIDER),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_WALL, ISLAND_DIVIDER),
	]
	assert_deduction(solver.deduce_island_divider, expected)


func test_island_divider_mistake() -> void:
	grid = [
		" 2 . 2",
		"      ",
		"      ",
		"      ",
		" 2   2",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 4), CELL_WALL, ISLAND_DIVIDER),
	]
	assert_deduction(solver.deduce_island_divider, expected)


func test_island_divider_none() -> void:
	grid = [
		" 2    ",
		"     2",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_island_divider, expected)


func test_island_divider_invalid() -> void:
	grid = [
		" 1##  ",
		"## 1  ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_island_divider, expected)


func test_wall_bubble_invalid() -> void:
	# the grid already has an island with no clue; don't perform this deduction
	grid = [
		" .##  ",
		"##   2",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_wall_bubble, expected)


func test_wall_bubble_invalid_2() -> void:
	# the grid already has an island with no clue; don't perform this deduction
	grid = [
		"## 3##",
		"## .  ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_wall_bubble, expected)


func test_wall_bubble_surrounded_square() -> void:
	grid = [
		"            ",
		"  ##        ",
		"## 1## 2##  ",
		"  ##  ## 5  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 3), CELL_WALL, WALL_BUBBLE),
		NurikabeDeduction.new(Vector2i(2, 3), CELL_WALL, WALL_BUBBLE),
	]
	assert_deduction(solver.deduce_wall_bubble, expected)


func test_island_connector_chokepoint() -> void:
	grid = [
		"  ##  ",
		" 3   .",
		"  ##  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, ISLAND_CONNECTOR),
	]
	assert_deduction(solver.deduce_island_connector, expected)


func test_island_connector_chokepoint_2() -> void:
	grid = [
		" 5    ",
		"##    ",
		" .    ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_CONNECTOR),
		NurikabeDeduction.new(Vector2i(1, 2), CELL_ISLAND, ISLAND_CONNECTOR),
	]
	assert_deduction(solver.deduce_island_connector, expected)


func test_island_moat_1() -> void:
	grid = [
		" 2 .  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 0), CELL_WALL, ISLAND_MOAT),
	]
	assert_deduction(solver.deduce_island_moat, expected)


func test_island_moat_2() -> void:
	grid = [
		" 2 .  ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, ISLAND_MOAT),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_WALL, ISLAND_MOAT),
		NurikabeDeduction.new(Vector2i(2, 0), CELL_WALL, ISLAND_MOAT),
	]
	assert_deduction(solver.deduce_island_moat, expected)


func test_island_moat_invalid() -> void:
	# the island is already too large; don't perform this deduction
	grid = [
		" 2 . .",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
	]
	assert_deduction(solver.deduce_island_moat, expected)


func test_island_expansion_1() -> void:
	grid = [
		" 3    ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(2, 0), CELL_ISLAND, ISLAND_CHOKEPOINT),
	]
	assert_deduction(solver.deduce_island_expansion, expected)


func test_island_expansion_multiple() -> void:
	grid = [
		" 2      ",
		"##      ",
		"##     4",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_expansion, expected)


func test_island_buffer_multiple() -> void:
	grid = [
		" 2      ",
		"##      ",
		"##     4",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 1), CELL_WALL, ISLAND_BUFFER),
		NurikabeDeduction.new(Vector2i(2, 0), CELL_WALL, ISLAND_BUFFER),
	]
	assert_deduction(solver.deduce_island_buffer, expected)


func test_island_expansion_chokepoint() -> void:
	grid = [
		" 4    ",
		"##  ##",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, ISLAND_CHOKEPOINT),
	]
	assert_deduction(solver.deduce_island_expansion, expected)


func test_island_expansion_chokepoint_2() -> void:
	grid = [
		" 4  ##",
		"##  ##",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, ISLAND_CHOKEPOINT),
		NurikabeDeduction.new(Vector2i(1, 2), CELL_ISLAND, ISLAND_CHOKEPOINT),
	]
	assert_deduction(solver.deduce_island_expansion, expected)


func test_island_expansion_island_chokepoint_1() -> void:
	# The cell at (2, 2) can't be an island or it would block the top 5 island from growing.
	grid = [
		" 1##    ",
		"####   5",
		"## 3    ",
		"        ",
		"        ",
		"        ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(3, 2), CELL_ISLAND, ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_expansion, expected)


func test_island_buffer_1() -> void:
	# The cell at (2, 2) can't be an island or it would block the top 5 island from growing.
	grid = [
		" 1##    ",
		"####   5",
		"## 3    ",
		"        ",
		"        ",
		"        ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 2), CELL_WALL, ISLAND_BUFFER),
	]
	assert_deduction(solver.deduce_island_buffer, expected)


func test_island_buffer_2() -> void:
	# The cell at (2, 2) can't be an island or it would block the top 5 island from growing.
	grid = [
		" 1## . .",
		"####   5",
		"## .    ",
		"        ",
		"        ",
		" 5      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 2), CELL_WALL, ISLAND_BUFFER)
	]
	assert_deduction(solver.deduce_island_buffer, expected)


func test_island_expansion_3() -> void:
	# The cell at (2, 2) can't be an island or it would block the top 5 island from growing.
	grid = [
		" 1##   5",
		"####    ",
		"## 3    ",
		"        ",
		"        ",
		"        ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(3, 1), CELL_ISLAND, ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(3, 2), CELL_ISLAND, ISLAND_CHOKEPOINT),
	]
	assert_deduction(solver.deduce_island_expansion, expected)


func test_island_buffer_3() -> void:
	# The cell at (2, 2) can't be an island or it would block the top 5 island from growing.
	grid = [
		" 1##   5",
		"####    ",
		"## 3    ",
		"        ",
		"        ",
		"        ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 2), CELL_WALL, ISLAND_BUFFER),
	]
	assert_deduction(solver.deduce_island_buffer, expected)


func test_island_expansion_invalid() -> void:
	grid = [
		" 2      ",
		"  ##    ",
		"   2    ",
		"        ",
		"       6",
	]
	var expected: Array[NurikabeDeduction] = [
	]
	assert_deduction(solver.deduce_island_expansion, expected)


func test_island_expansion_only_two_directions() -> void:
	# The cell at (2, 3) can't be an island or it would block the 2 island from growing.
	grid = [
		" . . .    ",
		" 7##      ",
		"## 2      ",
		"          ",
		"       1  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 3), CELL_WALL, CORNER_ISLAND),
	]
	assert_deduction(solver.deduce_corner_island, expected)


func test_pool_triplets_1() -> void:
	grid = [
		" 4    ",
		"    ##",
		"  ####",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, POOL_TRIPLET),
	]
	assert_deduction(solver.deduce_pool_triplets, expected)


func test_pool_triplets_cut_off() -> void:
	grid = [
		" 5    ",
		"  ##  ",
		"  ##  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_ISLAND, POOL_TRIPLET),
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, POOL_TRIPLET),
		NurikabeDeduction.new(Vector2i(2, 0), CELL_ISLAND, POOL_TRIPLET),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_ISLAND, POOL_TRIPLET),
	]
	assert_deduction(solver.deduce_pool_triplets, expected)


func test_wall_expansion_1() -> void:
	grid = [
		" 3##  ",
		"     3",
		"  ##  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 1), CELL_WALL, WALL_CONNECTOR),
	]
	assert_deduction(solver.deduce_wall_expansion, expected)


func test_wall_expansion_2() -> void:
	grid = [
		"## 4  ",
		"      ",
		"    ##",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, WALL_EXPANSION),
	]
	assert_deduction(solver.deduce_wall_expansion, expected)


func test_island_bubble_1() -> void:
	grid = [
		"      ",
		"##   .",
		"## 4  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 2), CELL_ISLAND, ISLAND_BUBBLE),
	]
	assert_deduction(solver.deduce_island_bubble, expected)


func test_island_bubble_2() -> void:
	grid = [
		"      ",
		"     .",
		"   4  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 2), CELL_ISLAND, ISLAND_BUBBLE),
	]
	assert_deduction(solver.deduce_island_bubble, expected)


func test_island_bubble_3() -> void:
	# The cell at (2, 2) is not an island bubble. It is not enclosed by islands.
	grid = [
		"      ",
		"    ##",
		"   4  ",
	]
	var expected: Array[NurikabeDeduction] = [
	]
	assert_deduction(solver.deduce_island_bubble, expected)


func test_island_bubble_invalid() -> void:
	grid = [
		"      ",
		"      ",
		"   4  ",
	]
	var expected: Array[NurikabeDeduction] = [
	]
	assert_deduction(solver.deduce_island_bubble, expected)


func test_unreachable_square_1() -> void:
	grid = [
		" 4    ",
		"      ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2(2, 2), CELL_WALL, UNREACHABLE_SQUARE),
	]
	assert_deduction(solver.deduce_unreachable_square, expected)


func test_unreachable_square_2() -> void:
	grid = [
		" 4##  ",
		" .    ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2(2, 0), CELL_WALL, UNREACHABLE_SQUARE),
		NurikabeDeduction.new(Vector2(2, 2), CELL_WALL, UNREACHABLE_SQUARE),
	]
	assert_deduction(solver.deduce_unreachable_square, expected)


func test_unreachable_square_3() -> void:
	grid = [
		"   .    ",
		"    ## 2",
		" . 7   .",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2(2, 2), CELL_WALL, UNREACHABLE_SQUARE),
		NurikabeDeduction.new(Vector2(3, 0), CELL_WALL, UNREACHABLE_SQUARE),
	]
	assert_deduction(solver.deduce_unreachable_square, expected)


func test_unreachable_square_blocked() -> void:
	# the upper right cell is reachable by the 4, but it's blocked by the 3
	grid = [
		" 4        ",
		"     3    ",
		"         2",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2(4, 0), CELL_WALL, UNREACHABLE_SQUARE),
	]
	assert_deduction(solver.deduce_unreachable_square, expected)


func test_unreachable_square_unclued_squares() -> void:
	# The center cell at (2, 2) is reachable by the 3, but it's blocked by unclued cells. This isn't deducable with
	# our current techniques. With unclued blobs of arbitrary size it would essentially require solving the knapsack
	# problem.
	grid = [
		" 3   .",
		"      ",
		" .    ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2(1, 2), CELL_WALL, UNREACHABLE_SQUARE),
		NurikabeDeduction.new(Vector2(2, 1), CELL_WALL, UNREACHABLE_SQUARE),
		NurikabeDeduction.new(Vector2(2, 2), CELL_WALL, UNREACHABLE_SQUARE),
	]
	assert_deduction(solver.deduce_unreachable_square, expected)
