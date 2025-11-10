extends TestSolver

func test_enqueue_island_chokepoints_wall_weaver_1() -> void:
	grid = [
		"#### 4 .  ",
		" 7####    ",
		" .   .  ##",
		"      ## 1",
	]
	var expected: Array[String] = [
		"(3, 2)->## wall_weaver (0, 1)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_wall_weaver_2() -> void:
	grid = [
		"## 6    ##",
		"##      ##",
		"##    ## 4",
		" 1##     .",
		"##   3## .",
		"          ",
	]
	var expected: Array[String] = [
		"(1, 2)->## wall_weaver (1, 0)",
		"(3, 1)->## wall_weaver (1, 0)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_wall_weaver_3() -> void:
	grid = [
		"###### . . . .",
		"## 2## .#### .",
		"## .####10## 7",
		" 1##     .####",
		"##        ## 3",
		"## .         .",
		"############  ",
	]
	var expected: Array[String] = [
		"(1, 4)->## wall_weaver (4, 2)",
		"(2, 3)->## wall_weaver (4, 2)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_adjacent() -> void:
	grid = [
		"   4  ",
		"####  ",
		"      ",
		" 3    ",
	]
	var expected: Array[String] = [
		"(2, 0)->. island_expansion (1, 0)",
		"(2, 1)->. island_chokepoint (1, 0)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_distant() -> void:
	grid = [
		"   2####",
		"       5",
		"        ",
	]
	var expected: Array[String] = [
		"(1, 1)->## island_buffer (3, 1)",
		"(1, 2)->. island_chokepoint (3, 1)",
		"(2, 2)->. island_chokepoint (3, 1)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_dead_end() -> void:
	grid = [
		"    11 .  ",
		"######    ",
		" 7        ",
		"          ",
		"          ",
	]
	var expected: Array[String] = [
		"(1, 0)->. pool_chokepoint (0, 0)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_false_positive() -> void:
	grid = [
		"  ####  ",
		"   4    ",
		"       8",
		"        ",
		"        ",
		"        ",
		"        ",
		"        ",
		"    ##  ",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_snug() -> void:
	grid = [
		" . .  ",
		" 5##  ",
		"  ####",
		"    ##",
		"   . 5",
	]
	var expected: Array[String] = [
		"(0, 2)->## island_buffer (1, 4)",
		"(0, 3)->. island_snug (1, 4)",
		"(0, 4)->. island_snug (1, 4)",
		"(1, 3)->. island_snug (1, 4)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_long() -> void:
	grid = [
		"    ####",
		" 2  ## .",
		"       .",
		"        ",
		" 6      ",
		"       5",
	]
	var expected: Array[String] = [
		"(3, 3)->. long_island (3, 5)",
		"(3, 4)->. long_island (3, 5)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_long_2() -> void:
	grid = [
		"    ####",
		" 2  ## .",
		"       .",
		"        ",
		" 5      ",
		"       .",
		"     7 .",
	]
	var expected: Array[String] = [
		"(3, 3)->. long_island (3, 5)",
		"(3, 4)->. long_island (3, 5)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_long_3() -> void:
	grid = [
		"  ##  ",
		"   .  ",
		"      ",
		"      ",
		"      ",
		"      ",
		"      ",
		"   7  ",
	]
	var expected: Array[String] = [
		"(1, 2)->. long_island (1, 7)",
		"(1, 3)->. long_island (1, 7)",
		"(1, 4)->. long_island (1, 7)",
		"(1, 5)->. long_island (1, 7)",
		"(1, 6)->. long_island (1, 7)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_long_4() -> void:
	grid = [
		"  ##  ",
		"   .  ",
		"      ",
		"      ",
		"      ",
		"      ",
		"      ",
		"   8  ",
	]
	var expected: Array[String] = [
		"(1, 2)->. long_island (1, 7)",
		"(1, 3)->. long_island (1, 7)",
		"(1, 4)->. long_island (1, 7)",
		"(1, 5)->. long_island (1, 7)",
		"(1, 6)->. long_island (1, 7)",
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_long_invalid_too_short() -> void:
	# the long island deduction can't apply to clues which are too close; they could swerve
	grid = [
		"  ##  ",
		"   .  ",
		"      ",
		"      ",
		"      ",
		"      ",
		"      ",
		"   9  ",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_chokepoints_long_invalid_bendy() -> void:
	# the long island deduction can't apply to diagonal clues
	grid = [
		"    ####",
		" 2  ## .",
		"       .",
		"        ",
		" 7      ",
		"       .",
		"     5 .",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.enqueue_island_chokepoints, expected)


func test_enqueue_island_dividers() -> void:
	grid = [
		" .   3",
		" 3    ",
		"      ",
	]
	var expected: Array[String] = [
		"(1, 0)->## island_divider (0, 0) (2, 0)",
	]
	assert_deductions(solver.enqueue_island_dividers, expected)


func test_enqueue_islands_corner_island() -> void:
	# The cell at (1, 1) can't be an island or it would block the 2 island from growing.
	grid = [
		" 2  ####",
		"    ## 1",
	]
	var expected: Array[String] = [
		"(1, 1)->## corner_island (0, 0)",
	]
	assert_deductions(solver.enqueue_islands, expected)


func test_enqueue_islands_island_expansion_1() -> void:
	grid = [
		" 4    ",
		"####  ",
		"      ",
	]
	var expected: Array[String] = [
		"(1, 0)->. island_expansion (0, 0)",
	]
	assert_deductions(solver.enqueue_islands, expected)


func test_enqueue_islands_island_expansion_and_moat() -> void:
	grid = [
		" 2    ",
		"##    ",
		"      ",
	]
	var expected: Array[String] = [
		"(1, 0)->. island_expansion (0, 0)",
		"(1, 1)->## island_moat (0, 0)",
		"(2, 0)->## island_moat (0, 0)",
	]
	assert_deductions(solver.enqueue_islands, expected)


func test_enqueue_islands_island_connector() -> void:
	grid = [
		"     6",
		"##    ",
		" .    ",
	]
	var expected: Array[String] = [
		"(1, 2)->. island_connector (0, 2)",
	]
	assert_deductions(solver.enqueue_islands, expected)


func test_enqueue_islands_island_moat() -> void:
	grid = [
		" 2    ",
		" .    ",
		"      ",
	]
	var expected: Array[String] = [
		"(0, 2)->## island_moat (0, 0)",
		"(1, 0)->## island_moat (0, 0)",
		"(1, 1)->## island_moat (0, 0)",
	]
	assert_deductions(solver.enqueue_islands, expected)


func test_enqueue_islands_island_snug() -> void:
	grid = [
		"   4  ",
		"####  ",
	]
	var expected: Array[String] = [
		"(0, 0)->. island_snug (1, 0)",
		"(2, 0)->. island_snug (1, 0)",
		"(2, 1)->. island_snug (1, 0)",
	]
	assert_deductions(solver.enqueue_islands, expected)


func test_enqueue_unreachable_squares_1() -> void:
	grid = [
		" 4    ",
		"      ",
		"      ",
	]
	var expected: Array[String] = [
		"(2, 2)->## unreachable_cell (0, 0)",
	]
	assert_deductions(solver.enqueue_unreachable_squares, expected)


func test_enqueue_unreachable_squares_2() -> void:
	grid = [
		" 4##  ",
		" .    ",
		"      ",
	]
	var expected: Array[String] = [
		"(2, 0)->## unreachable_cell (0, 0)",
		"(2, 2)->## unreachable_cell (0, 0)",
	]
	assert_deductions(solver.enqueue_unreachable_squares, expected)


func test_enqueue_unreachable_squares_3() -> void:
	grid = [
		"   .    ",
		"    ## 2",
		" . 7   .",
	]
	var expected: Array[String] = [
		"(2, 2)->## island_divider (0, 2) (3, 1)",
		"(3, 0)->## unreachable_cell (3, 1)",
	]
	assert_deductions(solver.enqueue_unreachable_squares, expected)


func test_enqueue_unreachable_squares_blocked() -> void:
	# the upper right cell is reachable by the 4, but it's blocked by the 3
	grid = [
		" 4        ",
		"     3    ",
		"         2",
	]
	var expected: Array[String] = [
		"(4, 0)->## unreachable_cell (4, 2)",
	]
	assert_deductions(solver.enqueue_unreachable_squares, expected)


func test_enqueue_unreachable_squares_wall_bubble() -> void:
	grid = [
		" 3  ######  ",
		"  ####      ",
		"## 1## 2##  ",
		"  ##  ## 5  ",
	]
	var expected: Array[String] = [
		"(0, 3)->## wall_bubble",
		"(2, 3)->## wall_bubble",
	]
	assert_deductions(solver.enqueue_unreachable_squares, expected)


func test_enqueue_wall_chokepoints() -> void:
	grid = [
		" 3##  ",
		"     3",
		"####  ",
	]
	var expected: Array[String] = [
		"(1, 1)->## wall_connector (1, 0)",
	]
	assert_deductions(solver.enqueue_wall_chokepoints, expected)


func test_enqueue_walls_pool_triplet_1() -> void:
	grid = [
		" 4    ",
		"    ##",
		"  ####",
	]
	var expected: Array[String] = [
		"(1, 1)->. pool_triplet (1, 2) (2, 1) (2, 2)",
	]
	assert_deductions(solver.enqueue_walls, expected)


func test_pool_triplets_2() -> void:
	grid = [
		" 3    ",
		"##  ##",
		"######",
	]
	var expected: Array[String] = [
		"(1, 1)->. pool_triplet (0, 1) (0, 2) (1, 2)",
	]
	assert_deductions(solver.enqueue_walls, expected)


func test_enqueue_walls_pool_triplets_invalid() -> void:
	grid = [
		" 3#### 3",
		"        ",
		"  ####  ",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.enqueue_walls, expected)


func test_enqueue_walls_wall_expansion_1() -> void:
	grid = [
		"## 4  ",
		"      ",
		"    ##",
	]
	var expected: Array[String] = [
		"(0, 1)->## wall_expansion (0, 0)",
	]
	assert_deductions(solver.enqueue_walls, expected)
