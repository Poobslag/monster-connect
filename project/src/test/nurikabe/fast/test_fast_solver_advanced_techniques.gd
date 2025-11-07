extends TestFastSolver

func test_enqueue_island_battleground_invalid_board() -> void:
	# This board already has a split wall at (0, 4).
	grid = [
		" 8## 3 . .## 2",
		" .########## .",
		" .## 3 . .####",
		" . .###### 1##",
		"## .      ##  ",
		" 2##  ##   3  ",
		" .##   4  ####",
		"##      ## 1##",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(4, 6), CELL_WALL, "island_battleground (3, 6) (5, 5)"),
	]
	assert_deduction(solver.enqueue_island_battleground, expected)


func test_enqueue_island_battleground() -> void:
	grid = [
		" 8## 3 . .## 2",
		" .########## .",
		" .## 3 . .####",
		" . .###### 1##",
		"## .      ##  ",
		"####  ##   3  ",
		" 1##   4  ####",
		"##      ## 1##",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(4, 6), CELL_WALL, "island_battleground (3, 6) (5, 5)"),
	]
	assert_deduction(solver.enqueue_island_battleground, expected)


func test_enqueue_island_battleground_unclued() -> void:
	# Cannot establish an island battleground with an unclued island.
	grid = [
		"   .",
		"    ",
		" .  ",
		" 7##",
	]
	var expected: Array[FastDeduction] = [
	]
	assert_deduction(solver.enqueue_island_battleground, expected)


func test_enqueue_wall_strangle() -> void:
	grid = [
		" . . . .    ",
		" 6####      ",
		"## 2        ",
		"##  ####    ",
		"            ",
		"            ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(3, 1), CELL_WALL, "wall_strangle (1, 1)"),
	]
	assert_deduction(solver.enqueue_wall_strangle, expected)


func test_enqueue_wall_strangle_one_wall() -> void:
	grid = [
		" 6 . . .",
		"  ####  ",
	]
	var expected: Array[FastDeduction] = [
	]
	assert_deduction(solver.enqueue_wall_strangle, expected)


func test_enqueue_island_strangle() -> void:
	grid = [
		"           7",
		" .          ",
		"     . 4 .  ",
	]
	var expected: Array[FastDeduction] = [
		FastDeduction.new(Vector2i(1, 2), CELL_WALL, "island_strangle (2, 2)"),
		FastDeduction.new(Vector2i(2, 1), CELL_WALL, "island_strangle (2, 2)"),
		FastDeduction.new(Vector2i(3, 1), CELL_WALL, "island_strangle (2, 2)"),
		FastDeduction.new(Vector2i(4, 1), CELL_WALL, "island_strangle (2, 2)"),
	]
	assert_deduction(solver.enqueue_island_strangle, expected)
