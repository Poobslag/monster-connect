extends TestGenerator

func test_fix_tiny_split_wall() -> void:
	grid = [
		"## . . 3########## 5",
		"######## ?## 6 .## .",
		"## . 2## . .## .## .",
		"###### 1## .## .## .",
		" ?## 2#### .## .## .",
		" .## .## . .## .####",
		" .###### .###### ?##",
		" .## ?  ## ?## . .##",
		" .##    ## .########",
		"## ?## ?###### . . ?",
	]
	var expected: Array[String] = [
		"(0, 9)-> fix_tiny_split_wall (0, 9)",
		"(1, 8)-> fix_tiny_split_wall (0, 9)",
		"(1, 9)-> fix_tiny_split_wall (0, 9)",
		"(2, 9)-> fix_tiny_split_wall (0, 9)",
	]
	assert_placements(generator.fix_tiny_split_wall, expected)


func test_fix_unclued_island() -> void:
	grid = [
		"###### . 2## 2## 2 .",
		"## . 3###### .######",
		"## .## 5## 4## 6## 6",
		"###### .## .## .## .",
		" . 3## .## .## .## .",
		" .#### .## .## .## .",
		"## 4## .###### .## .",
		"## .#### 2 .## .## .",
		"## . .##############",
		"######## 3 . .## . .",
	]
	var expected: Array[String] = [
		"(8, 9)->2 fix_unclued_island",
	]
	assert_placements(generator.fix_all_unclued_islands, expected)


func test_prepare_board_for_mutation() -> void:
	grid = [
		" . 2###### . . . . 5## 4",
		"###### . 5############ .",
		"## . . .## . . . . 5## .",
		"###################### .",
		"## ?## . . . . . . ?####",
		"#### . .############ . .",
		"###### .## . . . .#### .",
		"## . ?########## . .## .",
		"######## ?## . 2## .## .",
		"   ?## .########## 8## .",
		"###### . . . . . .#### 7",
		"## ?############ . ?####",
		"#### . . . . 5###### . 2",
		" .############ . . 5####",
		" .## .## .## . .###### 4",
		" 3## 2## 2######## . . .",
	]
	generator.board = GeneratorTestUtils.init_board(grid)
	var prepared_board: SolverBoard = generator.prepare_board_for_mutation()
	assert_board(prepared_board, [
			" . 2###### . . . . 5## 4",
			"###### . 5############ .",
			"## . . .## . . . . 5## .",
			"###################### .",
			"## 1## . . . . . .10####",
			"#### . .############ . .",
			"###### .## . . . .#### .",
			"## . 2########## . .## .",
			"######## 1## . 2## .## .",
			" . 2## .########## 8## .",
			"###### . . . . . .#### 7",
			"## 1############ . 9####",
			"#### . . . . 5###### . 2",
			" .############ . . 5####",
			" .## .## .## . .###### 4",
			" 3## 2## 2######## . . .",
		])
	generator.board.cleanup()


func test_prepare_board_for_mutation_2() -> void:
	grid = [
		" .## 2## 3## ?## 1##",
		" 2## .## .## .######",
		"######## .## . . .##",
		"## . . 3############",
		"########## 1## 3 .##",
		" . ?## ? .## 2## .##",
		" .## 2## .## .######",
		" .## .######## 2 .##",
		" .####     .########",
		" .           ?## ?  ",
	]
	generator.board = GeneratorTestUtils.init_board(grid)
	var prepared_board: SolverBoard = generator.prepare_board_for_mutation()
	assert_board(prepared_board, [
			" .## 2## 3## 5## 1##",
			" 2## .## .## .######",
			"######## .## . . .##",
			"## . . 3############",
			"########## 1## 3 .##",
			" .15## 3 .## 2## .##",
			" .## 2## .## .######",
			" .## .######## 2 .##",
			" .#### . . .########",
			" . . . . . .15## 2 .",
		])
	generator.board.cleanup()


func assert_board(board: SolverBoard, expected: Array[String]) -> void:
	assert_eq(board.to_grid_string(), "\n".join(expected))
