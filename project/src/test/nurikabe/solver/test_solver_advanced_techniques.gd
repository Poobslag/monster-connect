extends TestSolver

func test_create_island_battleground_probes_invalid_board() -> void:
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
		"(4, 6)->## island_battleground (3, 6) (5, 5)",
	]
	assert_deductions(solver.create_island_battleground_probes, expected)


func test_create_island_battleground_probes() -> void:
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
		"(4, 6)->## island_battleground (3, 6) (5, 5)",
	]
	assert_deductions(solver.create_island_battleground_probes, expected)


func test_create_island_battleground_probes_unclued() -> void:
	# Cannot establish an island battleground with an unclued island.
	grid = [
		"   .",
		"    ",
		" .  ",
		" 7##",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.create_island_battleground_probes, expected)


func test_create_wall_strangle_probes() -> void:
	grid = [
		" . . . .    ",
		" 6####      ",
		"## 2        ",
		"##  ####    ",
		"            ",
		"            ",
	]
	var expected: Array[String] = [
		"(3, 1)->## wall_strangle (1, 1)",
	]
	assert_deductions(solver.create_wall_strangle_probes, expected)


func test_create_wall_strangle_probes_one_wall() -> void:
	grid = [
		" 6 . . .",
		"  ####  ",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.create_wall_strangle_probes, expected)


func test_create_wall_strangle_probes_border_hug() -> void:
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
	assert_deductions(solver.create_wall_strangle_probes, expected)


func test_create_island_strangle_probes() -> void:
	grid = [
		"           7",
		" .          ",
		"     . 4 .  ",
	]
	var expected: Array[String] = [
		"(1, 2)->## island_strangle (2, 2)",
		"(4, 1)->## island_strangle (2, 2)",
	]
	assert_deductions(solver.create_island_strangle_probes, expected)


func test_create_island_release_probes() -> void:
	grid = [
		"      ",
		" 6    ",
		"##    ",
		"      ",
		" 6    ",
	]
	var expected: Array[String] = [
		"(1, 4)->. island_release (0, 4)",
	]
	assert_deductions(solver.create_island_release_probes, expected)


func test_create_island_release_probes_complete() -> void:
	grid = [
		"##    ",
		" . . .",
		" 6 . .",
	]
	var expected: Array[String] = []
	assert_deductions(solver.create_island_release_probes, expected)
