extends GutTest

const TEMP_PUZZLE_INFO_FILENAME := "user://test649.txt.info"

var saver: PuzzleInfoSaver = PuzzleInfoSaver.new()

func after_each() -> void:
	DirAccess.remove_absolute(TEMP_PUZZLE_INFO_FILENAME)


func test_load_puzzle_info() -> void:
	var info: PuzzleInfo = saver.load_puzzle_info("res://assets/test/nurikabe/example_788.txt.info")
	assert_eq(info.version, "0.01")
	assert_eq(info.author, "poobslag v02")
	assert_almost_eq(info.difficulty, 0.031, 0.001)
	assert_eq(info.size, Vector2i(10, 9))
	assert_eq("\n".join([
			" .## . 3###### 3 . .",
			" 9## .#### . 3######",
			" .#### 1## .## 3 .##",
			" . .############ .##",
			" . . .## . .## 1####",
			" .######## 3###### 4",
			"#### . . 3## . .## .",
			" .############ 3## .",
			" . . . . . . 8#### .",
		]), info.solution_string)
	assert_eq("\n".join([
			"30 20 5 - 4 1 0 - 2 2",
			"- 6 21 0 4 2 - 0 1 2",
			"22 23 0 - 0 5 0 - 2 3",
			"29 27 26 0 12 5 5 0 4 3",
			"25 28 17 13 13 6 0 - 0 5",
			"24 23 16 14 0 - 11 0 6 -",
			"19 16 16 4 - 0 11 9 10 7",
			"19 18 15 15 3 13 0 - 8 11",
			"19 16 16 14 14 2 - 0 1 11",
		]), info.order_string)
	assert_eq("\n".join([
			"ix ic ix - wx wx ac - ix ix",
			"- ci ix i1 wx ix - ac wx im",
			"ix wv i1 - i1 ix ac - ix wx",
			"ie p3 wb i1 wx im wx i1 ix wx",
			"ie ie p3 im ix p3 i1 - i1 wx",
			"p3 wv im wx ac - im i1 wx -",
			"im im ix ix - ac ix ix id ix",
			"ix wx ci wx cb wx ac - cb ix",
			"ix ix ix ix ix ix - ac wx ix",
		]), info.reason_string)


func test_save_and_load() -> void:
	var info: PuzzleInfo = PuzzleInfo.new()
	info.version = "0.01"
	info.author = "poobslag v02"
	info.difficulty = 0.031
	info.size = Vector2i(10, 9)
	info.solution_string = "\n".join([
			" .## . 3###### 3 . .",
			" 9## .#### . 3######",
			" .#### 1## .## 3 .##",
			" . .############ .##",
			" . . .## . .## 1####",
			" .######## 3###### 4",
			"#### . . 3## . .## .",
			" .############ 3## .",
			" . . . . . . 8#### .",
		])
	info.order_string = "\n".join([
			"30 20 5 - 4 1 0 - 2 2",
			"- 6 21 0 4 2 - 0 1 2",
			"22 23 0 - 0 5 0 - 2 3",
			"29 27 26 0 12 5 5 0 4 3",
			"25 28 17 13 13 6 0 - 0 5",
			"24 23 16 14 0 - 11 0 6 -",
			"19 16 16 4 - 0 11 9 10 7",
			"19 18 15 15 3 13 0 - 8 11",
			"19 16 16 14 14 2 - 0 1 11",
		])
	info.reason_string = "\n".join([
			"ix ic ix - wx wx ac - ix ix",
			"- ci ix i1 wx ix - ac wx im",
			"ix wv i1 - i1 ix ac - ix wx",
			"ie p3 wb i1 wx im wx i1 ix wx",
			"ie ie p3 im ix p3 i1 - i1 wx",
			"p3 wv im wx ac - im i1 wx -",
			"im im ix ix - ac ix ix id ix",
			"ix wx ci wx cb wx ac - cb ix",
			"ix ix ix ix ix ix - ac wx ix",
		])
	saver.save_puzzle_info(TEMP_PUZZLE_INFO_FILENAME, info)
	
	info = saver.load_puzzle_info(TEMP_PUZZLE_INFO_FILENAME)
	assert_eq(info.version, "0.02")
	assert_eq(info.author, "poobslag v02")
	assert_almost_eq(info.difficulty, 0.031, 0.001)
	assert_eq(info.size, Vector2i(10, 9))
	assert_eq("\n".join([
			" .## . 3###### 3 . .",
			" 9## .#### . 3######",
			" .#### 1## .## 3 .##",
			" . .############ .##",
			" . . .## . .## 1####",
			" .######## 3###### 4",
			"#### . . 3## . .## .",
			" .############ 3## .",
			" . . . . . . 8#### .",
		]), info.solution_string)
	assert_eq("\n".join([
			"30 20 5 - 4 1 0 - 2 2",
			"- 6 21 0 4 2 - 0 1 2",
			"22 23 0 - 0 5 0 - 2 3",
			"29 27 26 0 12 5 5 0 4 3",
			"25 28 17 13 13 6 0 - 0 5",
			"24 23 16 14 0 - 11 0 6 -",
			"19 16 16 4 - 0 11 9 10 7",
			"19 18 15 15 3 13 0 - 8 11",
			"19 16 16 14 14 2 - 0 1 11",
		]), info.order_string)
	assert_eq("\n".join([
			"ix ic ix - wx wx ac - ix ix",
			"- ci ix i1 wx ix - ac wx im",
			"ix wv i1 - i1 ix ac - ix wx",
			"ie p3 wb i1 wx im wx i1 ix wx",
			"ie ie p3 im ix p3 i1 - i1 wx",
			"p3 wv im wx ac - im i1 wx -",
			"im im ix ix - ac ix ix id ix",
			"ix wx ci wx cb wx ac - cb ix",
			"ix ix ix ix ix ix - ac wx ix",
		]), info.reason_string)
