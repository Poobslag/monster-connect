extends TestNurikabeSolver

func test_deduce_joined_island_2() -> void:
	grid = [
		" 3   3",
		"      ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_WALL, JOINED_ISLAND),
	]
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_joined_island_3() -> void:
	grid = [
		" 1      ",
		"   2   3",
		"        ",
		"        ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_WALL, JOINED_ISLAND),
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, JOINED_ISLAND),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_WALL, JOINED_ISLAND),
	]
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_joined_island_mistake() -> void:
	grid = [
		" 2 . 2",
		"      ",
		"      ",
		"      ",
		" 2   2",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 4), CELL_WALL, JOINED_ISLAND),
	]
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_joined_island_none() -> void:
	grid = [
		" 2    ",
		"     2",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_joined_island_invalid() -> void:
	grid = [
		" 1##  ",
		"## 1  ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_joined_island(init_model()), expected)


func test_deduce_unclued_island_invalid() -> void:
	# the grid already has an island with no clue; don't perform this deduction
	grid = [
		" .##  ",
		"##   2",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_unclued_island_invalid_2() -> void:
	# the grid already has an island with no clue; don't perform this deduction
	grid = [
		"## 3##",
		"## .  ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		]
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_unclued_island_surrounded_square() -> void:
	grid = [
		"            ",
		"  ##        ",
		"## 1## 2##  ",
		"  ##  ## 5  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 3), CELL_WALL, SURROUNDED_SQUARE),
		NurikabeDeduction.new(Vector2i(2, 3), CELL_WALL, SURROUNDED_SQUARE),
	]
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_unclued_island_chokepoint() -> void:
	grid = [
		"  ##  ",
		" 3   .",
		"  ##  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, UNCLUED_ISLAND),
	]
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_unclued_island_chokepoint_2() -> void:
	grid = [
		" 5    ",
		"##    ",
		" .    ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, UNCLUED_ISLAND),
		NurikabeDeduction.new(Vector2i(1, 2), CELL_ISLAND, UNCLUED_ISLAND),
	]
	assert_deduction(solver.deduce_unclued_island(init_model()), expected)


func test_deduce_island_too_large_1() -> void:
	grid = [
		" 2 .  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 0), CELL_WALL, ISLAND_TOO_LARGE),
	]
	assert_deduction(solver.deduce_island_too_large(init_model()), expected)


func test_deduce_island_too_large_2() -> void:
	grid = [
		" 2 .  ",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, ISLAND_TOO_LARGE),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_WALL, ISLAND_TOO_LARGE),
		NurikabeDeduction.new(Vector2i(2, 0), CELL_WALL, ISLAND_TOO_LARGE),
	]
	assert_deduction(solver.deduce_island_too_large(init_model()), expected)


func test_deduce_island_too_large_invalid() -> void:
	# the island is already too large; don't perform this deduction
	grid = [
		" 2 . .",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
	]
	assert_deduction(solver.deduce_island_too_large(init_model()), expected)


func test_island_too_small_1() -> void:
	grid = [
		" 3    ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(2, 0), CELL_ISLAND, HIDDEN_ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_multiple() -> void:
	grid = [
		" 2    ",
		"##    ",
		"##   3",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_chokepoint() -> void:
	grid = [
		" 4    ",
		"##  ##",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, HIDDEN_ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_chokepoint_2() -> void:
	grid = [
		" 4  ##",
		"##  ##",
		"      ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, HIDDEN_ISLAND_EXPANSION),
		NurikabeDeduction.new(Vector2i(1, 2), CELL_ISLAND, HIDDEN_ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_hidden_island_expansion_1() -> void:
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
		NurikabeDeduction.new(Vector2i(2, 2), CELL_WALL, HIDDEN_ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_hidden_island_expansion_2() -> void:
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
		NurikabeDeduction.new(Vector2i(2, 2), CELL_WALL, HIDDEN_ISLAND_EXPANSION),
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_invalid() -> void:
	grid = [
		" 2      ",
		"  ##    ",
		"   2    ",
		"        ",
		"       6",
	]
	var expected: Array[NurikabeDeduction] = [
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_island_too_small_only_two_directions() -> void:
	# The cell at (2, 3) can't be an island or it would block the 2 island from growing.
	grid = [
		" . . .  ",
		" 7##    ",
		"## 2    ",
		"        ",
		"       1",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(2, 3), CELL_WALL, CORNER_ISLAND),
	]
	assert_deduction(solver.deduce_island_too_small(init_model()), expected)


func test_pools_1() -> void:
	grid = [
		" 4    ",
		"    ##",
		"  ####",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 1), CELL_ISLAND, POOLS),
	]
	assert_deduction(solver.deduce_pools(init_model()), expected)


func test_pools_cut_off() -> void:
	grid = [
		" 5    ",
		"  ##  ",
		"  ##  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_ISLAND, POOLS),
		NurikabeDeduction.new(Vector2i(1, 0), CELL_ISLAND, POOLS),
		NurikabeDeduction.new(Vector2i(2, 0), CELL_ISLAND, POOLS),
		NurikabeDeduction.new(Vector2i(2, 1), CELL_ISLAND, POOLS),
	]
	assert_deduction(solver.deduce_pools(init_model()), expected)


func test_no_split_walls_1() -> void:
	grid = [
		" 3##  ",
		"     3",
		"  ##  ",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(1, 1), CELL_WALL, WALL_CONTINUITY),
	]
	assert_deduction(solver.deduce_split_walls(init_model()), expected)


func test_no_split_walls_2() -> void:
	grid = [
		"## 4  ",
		"      ",
		"    ##",
	]
	var expected: Array[NurikabeDeduction] = [
		NurikabeDeduction.new(Vector2i(0, 1), CELL_WALL, WALL_EXPANSION),
	]
	assert_deduction(solver.deduce_split_walls(init_model()), expected)
