extends TestSolver

func test_deduce_all_clue_chokepoints_wall_weaver_1() -> void:
	grid = [
		"#### 4 .  ",
		" 7####    ",
		" .   .  ##",
		"      ## 1",
	]
	var expected: Array[String] = [
		"(3, 2)->## wall_weaver (0, 1)",
	]
	assert_deductions(solver.deduce_all_clue_chokepoints, expected)


func test_deduce_all_clue_chokepoints_wall_weaver_2() -> void:
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
	assert_deductions(solver.deduce_all_clue_chokepoints, expected)


func test_deduce_all_clue_chokepoints_wall_weaver_3() -> void:
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
	assert_deductions(solver.deduce_all_clue_chokepoints, expected)


func test_deduce_all_clue_chokepoints_adjacent() -> void:
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
	assert_deductions(solver.deduce_all_clue_chokepoints, expected)


func test_deduce_all_clue_chokepoints_distant() -> void:
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
	assert_deductions(solver.deduce_all_clue_chokepoints, expected)


func test_deduce_all_island_chokepoints_dead_end() -> void:
	grid = [
		"    11 .  ",
		"######    ",
		" 7        ",
		"          ",
		"          ",
	]
	var expected: Array[String] = [
		"(1, 0)->. pool_chokepoint (0, 0) (0, 1) (1, 0) (1, 1)",
	]
	assert_deductions(solver.deduce_all_island_chokepoints, expected)


func test_deduce_all_island_chokepoints_big_dead_end() -> void:
	grid = [
		" 2  ##   3    ",
		"  ## 1##     3",
		"## 1##        ",
		"  ## 1##      ",
		"    ##     9  ",
		"              ",
	]
	var expected: Array[String] = [
		"(1, 5)->. pool_chokepoint (0, 3) (0, 4) (0, 5) (1, 3) (1, 4) (1, 5)"
	]
	assert_deductions(solver.deduce_all_island_chokepoints, expected)


func test_deduce_all_island_chokepoints_false_positive() -> void:
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
	assert_deductions(solver.deduce_all_island_chokepoints, expected)


func test_deduce_all_islands_snug() -> void:
	grid = [
		" .    ",
		" 5    ",
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
	assert_deductions(solver.deduce_all_clued_island_snugs, expected)


func test_deduce_all_island_chokepoints_lifeline() -> void:
	grid = [
		"    ####",
		" 2  ## .",
		"       .",
		"        ",
		" 6      ",
		"       5",
	]
	var expected: Array[String] = [
		"(3, 3)->. unclued_lifeline (3, 5)",
		"(3, 4)->. unclued_lifeline (3, 5)",
	]
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_chokepoints_lifeline_2() -> void:
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
		"(3, 3)->. unclued_lifeline (3, 5)",
		"(3, 4)->. unclued_lifeline (3, 5)",
	]
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_chokepoints_lifeline_3() -> void:
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
		"(1, 2)->. unclued_lifeline (1, 7)",
		"(1, 3)->. unclued_lifeline (1, 7)",
		"(1, 4)->. unclued_lifeline (1, 7)",
		"(1, 5)->. unclued_lifeline (1, 7)",
		"(1, 6)->. unclued_lifeline (1, 7)",
	]
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_chokepoints_lifeline_4() -> void:
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
		"(1, 2)->. unclued_lifeline (1, 7)",
		"(1, 3)->. unclued_lifeline (1, 7)",
		"(1, 4)->. unclued_lifeline (1, 7)",
		"(1, 5)->. unclued_lifeline (1, 7)",
		"(1, 6)->. unclued_lifeline (1, 7)",
	]
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_chokepoints_lifeline_5() -> void:
	grid = [
		"############",
		"## .## 6    ",
		"## 2##      ",
		"####        ",
		" .## 6     .",
		" .######## .",
		" . 6 . .## .",
	]
	var expected: Array[String] = [
		"(3, 4)->. unclued_lifeline (2, 4)",
		"(4, 4)->. unclued_lifeline (2, 4)",
	]
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_chokepoints_lifeline_6() -> void:
	grid = [
		"####     4",
		"## .      ",
		"## .      ",
		"## 8     .",
		"######## .",
		" 2 .  ## .",
	]
	var expected: Array[String] = [
		"(2, 3)->. unclued_lifeline (1, 1)",
		"(3, 3)->. unclued_lifeline (1, 1)",
	]
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_chokepoints_lifeline_invalid_too_short() -> void:
	# the unclued lifeline deduction can't apply to clues which are too close; they could swerve
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
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_chokepoints_lifeline_invalid_bendy() -> void:
	# the unclued lifeline deduction can't apply to diagonal clues
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
	assert_deductions(solver.deduce_unclued_lifeline, expected)


func test_deduce_all_island_dividers() -> void:
	grid = [
		" .   3",
		" 3    ",
		"      ",
	]
	var expected: Array[String] = [
		"(1, 0)->## island_divider (0, 0) (2, 0)",
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)


func test_deduce_all_island_dividers_unclued() -> void:
	grid = [
		" .   .",
		" 3    ",
		"     3",
	]
	var expected: Array[String] = [
		"(1, 0)->## island_divider (0, 0) (2, 0)",
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)


func test_deduce_all_island_dividers_invalid() -> void:
	grid = [
		"      ",
		"     .",
		"   . 6",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.deduce_all_island_dividers, expected)


func test_deduce_all_islands_corner_island() -> void:
	# The cell at (1, 1) can't be an island or it would block the 2 island from growing.
	grid = [
		" 2  ####",
		"    ## 1",
	]
	var expected: Array[String] = [
		"(1, 1)->## corner_island (0, 0)",
	]
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_all_islands_island_expansion_1() -> void:
	grid = [
		" 4    ",
		"####  ",
		"      ",
	]
	var expected: Array[String] = [
		"(1, 0)->. island_expansion (0, 0)",
		"(2, 0)->. island_expansion (0, 0)",
		"(2, 1)->. island_expansion (0, 0)",
		"(2, 2)->## island_moat (0, 0)",
	]
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_all_islands_island_expansion_and_moat() -> void:
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
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_all_islands_island_connector() -> void:
	grid = [
		"     6",
		"##    ",
		" .    ",
	]
	var expected: Array[String] = [
		"(1, 2)->. island_connector (0, 2)",
	]
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_all_islands_island_moat() -> void:
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
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_all_islands_island_snug() -> void:
	grid = [
		"   4  ",
		"####  ",
	]
	var expected: Array[String] = [
		"(0, 0)->. island_snug (1, 0)",
		"(2, 0)->. island_snug (1, 0)",
		"(2, 1)->. island_snug (1, 0)",
	]
	assert_deductions(solver.deduce_all_clued_island_snugs, expected)


func test_deduce_all_islands_corner_buffer_1() -> void:
	grid = [
		"            ",
		"    ########",
		"15  ## 6 . .",
		"          ##",
		"         . .",
	]
	var expected: Array[String] = [
		"(3, 3)->## corner_buffer (3, 2) (4, 4)",
	]
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_all_islands_corner_buffer_2() -> void:
	grid = [
		"            ",
		"    ########",
		"15  ## . . .",
		"          ##",
		"         . 6",
	]
	var expected: Array[String] = [
		"(3, 3)->## corner_buffer (3, 2) (4, 4)",
	]
	assert_deductions(solver.deduce_all_islands, expected)


func test_deduce_all_unreachable_squares_1() -> void:
	grid = [
		" 4    ",
		"      ",
		"      ",
	]
	var expected: Array[String] = [
		"(2, 2)->## unreachable_cell (0, 0)",
	]
	assert_deductions(solver.deduce_all_unreachable_squares, expected)


func test_deduce_all_unreachable_squares_2() -> void:
	grid = [
		" 4##  ",
		" .    ",
		"      ",
	]
	var expected: Array[String] = [
		"(2, 0)->## unreachable_cell (0, 0)",
		"(2, 2)->## unreachable_cell (0, 0)",
	]
	assert_deductions(solver.deduce_all_unreachable_squares, expected)


func test_deduce_all_unreachable_squares_3() -> void:
	grid = [
		"   .    ",
		"    ## 2",
		" . 7   .",
	]
	var expected: Array[String] = [
		"(2, 2)->## island_divider (0, 2) (3, 1)",
		"(3, 0)->## unreachable_cell (3, 1)",
	]
	assert_deductions(solver.deduce_all_unreachable_squares, expected)


func test_deduce_all_unreachable_squares_blocked() -> void:
	# the upper right cell is reachable by the 4, but it's blocked by the 3
	grid = [
		" 4        ",
		"     3    ",
		"         2",
	]
	var expected: Array[String] = [
		"(4, 0)->## unreachable_cell (4, 2)",
	]
	assert_deductions(solver.deduce_all_unreachable_squares, expected)


func test_create_empty_region_probes_wall_bubble() -> void:
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
	assert_deductions(solver.deduce_all_bubbles, expected)


func test_create_empty_region_probes_island_bubble() -> void:
	grid = [
		" 9 . .",
		" .  ##",
		" .## 1",
		" .  ##",
		"   . .",
	]
	var expected: Array[String] = [
		"(0, 4)->. island_bubble",
	]
	assert_deductions(solver.deduce_all_bubbles, expected)


func test_deduce_all_wall_chokepoints() -> void:
	grid = [
		"   3##  ",
		"       3",
		"  ####  ",
	]
	var expected: Array[String] = [
		"(2, 1)->## wall_connector (2, 0)",
	]
	assert_deductions(solver.deduce_all_wall_chokepoints, expected)


func test_deduce_all_wall_chokepoints_border_hug_invalid_1() -> void:
	grid = [
		"   6    ## 1",
		"        ####",
		"##    ## . 2",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.deduce_all_wall_chokepoints, expected)


func test_deduce_all_wall_chokepoints_border_hug_invalid_2() -> void:
	grid = [
		"          ## 1",
		"     8    ####",
		"##      ## . 2",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.deduce_all_wall_chokepoints, expected)


func test_deduce_all_wall_chokepoints_border_hug_invalid_3() -> void:
	grid = [
		"####   . 4",
		"## 1## .##",
		"##########",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.deduce_wall_chokepoint.bind(Vector2i(2, 0)), expected)


func test_deduce_all_walls_pool_triplet_1() -> void:
	grid = [
		" 4    ",
		"    ##",
		"  ####",
	]
	var expected: Array[String] = [
		"(1, 1)->. pool_triplet (1, 2) (2, 1) (2, 2)",
	]
	assert_deductions(solver.deduce_all_walls, expected)


func test_pool_triplets_2() -> void:
	grid = [
		" 3    ",
		"##  ##",
		"######",
	]
	var expected: Array[String] = [
		"(1, 1)->. pool_triplet (0, 1) (0, 2) (1, 2)",
	]
	assert_deductions(solver.deduce_all_walls, expected)


func test_deduce_all_walls_pool_triplets_invalid_1() -> void:
	grid = [
		" 3#### 3",
		"        ",
		"  ####  ",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.deduce_all_walls, expected)


func test_deduce_all_walls_pool_triplets_invalid_2() -> void:
	grid = [
		"##########",
		"## 1## 1##",
		"####  ####",
		"          ",
	]
	var expected: Array[String] = [
	]
	assert_deductions(solver.deduce_all_walls, expected)


func test_deduce_all_walls_wall_expansion_1() -> void:
	grid = [
		"## 4  ",
		"      ",
		"    ##",
	]
	var expected: Array[String] = [
		"(0, 1)->## wall_expansion (0, 0)",
	]
	assert_deductions(solver.deduce_all_walls, expected)


func test_deduce_all_walls_wall_expansion_mystery_clue() -> void:
	grid = [
		"     ?",
		"    ##",
		"     ?",
	]
	var expected: Array[String] = [
		"(1, 1)->## wall_expansion (2, 1)",
	]
	assert_deductions(solver.deduce_all_walls, expected)


func test_deduce_all_island_chains() -> void:
	grid = [
		"     3",
		"      ",
		"  2   ",
	]
	var expected: Array[String] = [
		"(1, 1)->## island_chain (1, 2) (2, 0)",
		"(2, 1)->## island_chain (1, 2) (2, 0)",
	]
	assert_deductions(solver.deduce_all_island_chains, expected)
