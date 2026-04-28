extends TestSolver

func test_bifurcate_all_island_battlegrounds_invalid_board() -> void:
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
	var expected: Array[String] = [
		"(4, 5)->## island_battleground (5, 5) (3, 6)",
	]
	assert_deductions(solver.bifurcate_all_island_battlegrounds, expected)


func test_bifurcate_all_island_battlegrounds() -> void:
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
	var expected: Array[String] = [
		"(4, 5)->## island_battleground (5, 5) (3, 6)",
	]
	assert_deductions(solver.bifurcate_all_island_battlegrounds, expected)


func test_bifurcate_all_island_battlegrounds_unclued() -> void:
	# Cannot establish an island battleground with an unclued island.
	grid = [
		"   .",
		"    ",
		" .  ",
		" 7##",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.bifurcate_all_island_battlegrounds, expected)


func test_bifurcate_all_wall_strangles() -> void:
	grid = [
		" . . . .    ",
		" 6####      ",
		"## 2        ",
		"##  ####    ",
		"            ",
		"            ",
	]
	var expected: Array[String] = [
		"(2, 2)->## wall_strangle (1, 1)",
	]
	assert_deductions(solver.bifurcate_all_wall_strangles, expected)


func test_bifurcate_all_wall_strangles_one_wall() -> void:
	grid = [
		" 6 . . .",
		"  ####  ",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.bifurcate_all_wall_strangles, expected)


func test_bifurcate_all_wall_strangles_border_hug() -> void:
	grid = [
		"########",
		"     .##",
		"     . 7",
		"      ##",
		"####    ",
		" 1##    ",
	]
	var expected: Array[String] = [
		"(0, 1)->## border_hug (0, 0)",
	]
	assert_deductions(solver.bifurcate_all_wall_strangles, expected)


func test_bifurcate_all_island_strangles() -> void:
	grid = [
		"           7",
		" .          ",
		"     . 4 .  ",
	]
	var expected: Array[String] = [
		"(2, 1)->## island_strangle (2, 2)",
	]
	assert_deductions(solver.bifurcate_all_island_strangles, expected)


func test_bifurcate_all_island_releases() -> void:
	grid = [
		"      ",
		" 6    ",
		"##    ",
		"      ",
		" 6    ",
	]
	var expected: Array[String] = [
		"(0, 0)->. island_release (0, 1)",
	]
	assert_deductions(solver.bifurcate_all_island_releases, expected)


func test_bifurcate_all_island_releases_complete() -> void:
	grid = [
		"##    ",
		" . . .",
		" 6 . .",
	]
	var expected: Array[String] = []
	assert_deductions(solver.bifurcate_all_island_releases, expected)
