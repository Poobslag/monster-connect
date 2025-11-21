extends GutTest

const VALIDATE_STRICT: SolverBoard.ValidationMode = SolverBoard.VALIDATE_STRICT
const VALIDATE_COMPLEX: SolverBoard.ValidationMode = SolverBoard.VALIDATE_COMPLEX
const VALIDATE_SIMPLE: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE

var grid: Array[String]

func test_joined_islands_two() -> void:
	grid = [
		" 3## 3",
		"  ##  ",
		"  ##  ",
	]
	assert_valid(VALIDATE_STRICT)
	
	grid = [
		" 3## 3",
		"  ##  ",
		"      ",
	]
	assert_invalid(VALIDATE_STRICT, {"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})
	assert_valid(VALIDATE_SIMPLE)
	
	grid = [
		" 3## 3",
		" .## .",
		" .   .",
	]
	assert_invalid(VALIDATE_STRICT, {"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})
	assert_valid(VALIDATE_COMPLEX)
	
	grid = [
		" 3## 3",
		" .## .",
		" . . .",
	]
	assert_invalid(VALIDATE_COMPLEX, {"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})


func test_joined_islands_local() -> void:
	grid = [
		" 3   3",
		" .   .",
		" .## .",
	]
	assert_valid_local([Vector2i(0, 2)])
	
	grid = [
		" 3 . 3",
		" .   .",
		" .## .",
	]
	assert_invalid_local([Vector2i(1, 1)], "j")


func test_joined_islands_three() -> void:
	grid = [
		" 3        ",
		"     3    ",
		"         3",
	]
	assert_invalid(VALIDATE_STRICT, {"joined_islands": [
			Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
			Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
			Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2),
			Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
			Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2),
		]})
	assert_valid(VALIDATE_COMPLEX)
	
	grid = [
		" 3        ",
		" . . 3    ",
		"         3",
	]
	assert_invalid(VALIDATE_COMPLEX, {"joined_islands": [
			Vector2i(0, 0), Vector2i(0, 1),
			Vector2i(1, 1),
			Vector2i(2, 1),
		]})


func test_pools_ok() -> void:
	grid = [
		" 5    ",
		"##    ",
		"######",
	]
	assert_valid(VALIDATE_STRICT)


func test_pools_one() -> void:
	grid = [
		" 5    ",
		"####  ",
		"####  ",
	]
	assert_invalid(VALIDATE_STRICT, {"pools": [
			Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(1, 2)]})


func test_pools_local() -> void:
	grid = [
		"      ",
		"##    ",
		"####  ",
	]
	assert_valid_local([Vector2i(1, 1)])
	
	grid = [
		"      ",
		"####  ",
		"####  ",
	]
	assert_invalid_local([Vector2i(1, 1)], "p")


func test_pools_two() -> void:
	grid = [
		" 3    ",
		"######",
		"######",
	]
	assert_invalid(VALIDATE_STRICT, {"pools": [
			Vector2i(0, 1), Vector2i(0, 2),
			Vector2i(1, 1), Vector2i(1, 2),
			Vector2i(2, 1), Vector2i(2, 2),
		]})


func test_split_walls_ok() -> void:
	grid = [
		"######",
		"  ##  ",
		"   5  ",
	]
	assert_valid(VALIDATE_STRICT)
	
	grid = [
		" 8    ",
		" .    ",
		"## .  ",
	]
	assert_valid(VALIDATE_STRICT)


func test_split_walls_two() -> void:
	grid = [
		"  ####",
		" 6    ",
		"    ##",
	]
	assert_invalid(VALIDATE_STRICT, {"split_walls": [Vector2i(2, 2)]})
	assert_valid(VALIDATE_COMPLEX)
	
	grid = [
		"  ####",
		" 6   .",
		"    ##",
	]
	assert_valid(VALIDATE_COMPLEX)
	
	grid = [
		"  ####",
		" 6 . .",
		"    ##",
	]
	assert_invalid(VALIDATE_COMPLEX, {"split_walls": [Vector2i(2, 2)]})


func test_split_walls_local() -> void:
	grid = [
		"  ####",
		"     .",
		" 6  ##",
	]
	assert_valid_local([Vector2i(2, 1)])
	
	grid = [
		"  ####",
		"     .",
		" 6 .##",
	]
	assert_invalid_local([Vector2i(1, 2)], "s")


func test_split_walls_three() -> void:
	grid = [
		"##   3",
		"  ##  ",
		" 3  ##",
	]
	assert_invalid(VALIDATE_STRICT, {"split_walls": [Vector2i(1, 1), Vector2i(2, 2)]})
	assert_valid(VALIDATE_COMPLEX)
	
	grid = [
		"## . 3",
		" .## .",
		" 3 .##",
	]
	assert_invalid(VALIDATE_COMPLEX, {"split_walls": [Vector2i(1, 1), Vector2i(2, 2)]})
	
	grid = [
		"##   3",
		"  ## .",
		" 3 .##",
	]
	assert_invalid(VALIDATE_COMPLEX, {"split_walls": [Vector2i(2, 2)]})


func test_unclued_islands() -> void:
	grid = [
		"##    ",
		"#### 3",
		"  ####",
	]
	assert_invalid(VALIDATE_STRICT, {"unclued_islands": [Vector2i(0, 2)]})
	assert_valid(VALIDATE_COMPLEX)
	
	grid = [
		"## .  ",
		"#### 3",
		"  ####",
	]
	assert_valid(VALIDATE_COMPLEX)
	
	grid = [
		"##    ",
		"#### 3",
		" .####",
	]
	assert_invalid(VALIDATE_COMPLEX, {"unclued_islands": [Vector2i(0, 2)]})
	
	grid = [
		"####  ",
		"  ## 2",
		" .####",
	]
	assert_invalid(VALIDATE_COMPLEX, {"unclued_islands": [Vector2i(0, 2)]})


func test_unclued_islands_local() -> void:
	grid = [
		"  ####",
		"     .",
		" 6  ##",
	]
	assert_valid_local([Vector2i(2, 1)])
	
	grid = [
		"  ####",
		"  ## .",
		" 6  ##",
	]
	assert_invalid_local([Vector2i(2, 1)], "u")


func test_wrong_size() -> void:
	grid = [
		"##   4",
		"##    ",
		"######",
	]
	assert_valid(VALIDATE_STRICT)
	assert_valid(VALIDATE_SIMPLE)
	
	grid = [
		"#### 4",
		"##    ",
		"######",
	]
	assert_invalid(VALIDATE_STRICT, {"wrong_size": [Vector2i(1, 1), Vector2i(2, 0), Vector2i(2, 1)]})
	assert_invalid(VALIDATE_SIMPLE, {"wrong_size": [Vector2i(2, 0)]})
	
	grid = [
		" . . 4",
		"## . .",
		"######",
	]
	assert_invalid(VALIDATE_STRICT, {"wrong_size": [
			Vector2i(0, 0),
			Vector2i(1, 0), Vector2i(1, 1),
			Vector2i(2, 0), Vector2i(2, 1)]})
	assert_invalid(VALIDATE_SIMPLE, {"wrong_size": [
			Vector2i(0, 0),
			Vector2i(1, 0), Vector2i(1, 1),
			Vector2i(2, 0), Vector2i(2, 1)]})


func test_wrong_size_neighbors() -> void:
	grid = [
		"##   4",
		"      ",
		" 1  ##",
	]
	assert_valid(VALIDATE_COMPLEX)
	assert_valid(VALIDATE_SIMPLE)
	
	grid = [
		"##   5",
		"      ",
		" 1  ##",
	]
	assert_invalid(VALIDATE_COMPLEX, {"wrong_size": [Vector2i(2, 0)]})
	assert_valid(VALIDATE_SIMPLE)
	
	grid = [
		"## . 5",
		"   . .",
		" 1  ##",
	]
	assert_invalid(VALIDATE_COMPLEX, {
			"wrong_size": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 0), Vector2i(2, 1)],
			"split_walls": [Vector2i(2, 2)]})
	assert_invalid(VALIDATE_SIMPLE, {"split_walls": [Vector2i(2, 2)]})


func test_wrong_size_local() -> void:
	grid = [
		" 2    ",
		"     .",
		"     2",
	]
	assert_valid_local([Vector2i(2, 1)])
	
	grid = [
		" 2   .",
		"     .",
		"     2",
	]
	assert_invalid_local([Vector2i(2, 1)], "c")


func test_complex_bug() -> void:
	grid = [
		"##########",
		" 3## . 4##",
		" .   .####",
		"       2  ",
	]
	assert_invalid(VALIDATE_COMPLEX, {"wrong_size": [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 1)]})


func test_increase_heat() -> void:
	grid = [
		"######  ##",
		" 3 .      ",
		"          ",
		"   6      ",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	board.increase_heat([Vector2i(1, 1)])
	
	# heat spreads to adjacent walls and their liberties
	assert_heat(board, Vector2i(0, 0), 0.5)
	assert_heat(board, Vector2i(1, 0), 0.5)
	assert_heat(board, Vector2i(2, 0), 0.5)
	assert_heat(board, Vector2i(3, 0), 0.25)
	assert_heat(board, Vector2i(4, 0), 0.125)
	assert_heat(board, Vector2i(4, 1), 0.125)
	
	# head spreads to islands and their liberties
	assert_heat(board, Vector2i(0, 0), 0.5)
	assert_heat(board, Vector2i(1, 1), 1.0)
	assert_heat(board, Vector2i(2, 1), 0.5)
	assert_heat(board, Vector2i(0, 2), 0.5)
	assert_heat(board, Vector2i(1, 2), 0.5)
	
	# heat spreads nearby
	assert_heat(board, Vector2i(2, 2), 0.25)
	assert_heat(board, Vector2i(1, 3), 0.25)


func test_decrease_heat() -> void:
	grid = [
		"######  ##",
		" 3 .      ",
		"          ",
		"   6      ",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	board.increase_heat([Vector2i(1, 1)])
	assert_heat(board, Vector2i(1, 1), 1.000)
	board.decrease_heat(3)
	assert_heat(board, Vector2i(1, 1), 0.729)


func assert_heat(board: SolverBoard, cell: Vector2i, expected_heat: float) -> void:
	assert_almost_eq(board.get_heat(cell), expected_heat, 0.01)


func assert_valid(mode: SolverBoard.ValidationMode) -> void:
	_assert_validate(mode, {})


func assert_valid_local(local_cells: Array[Vector2i]) -> void:
	_assert_validate_local(local_cells, "")


func assert_invalid_local(local_cells: Array[Vector2i], expected_result: String) -> void:
	_assert_validate_local(local_cells, expected_result)


func assert_invalid(mode: SolverBoard.ValidationMode, expected_result_dict: Dictionary) -> void:
	_assert_validate(mode, expected_result_dict)


func _assert_validate(mode: SolverBoard.ValidationMode, expected_result_dict: Dictionary) -> void:
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	var validation_result: SolverBoard.ValidationResult = board.validate(mode)
	for key: String in ["joined_islands", "pools", "split_walls", "unclued_islands", "wrong_size"]:
		var validation_result_value: Array[Vector2i] = validation_result.get(key)
		validation_result_value.sort()
		assert_eq(expected_result_dict.get(key, []), validation_result_value, "Incorrect %s." % [key])


func _assert_validate_local(local_cells: Array[Vector2i], expected_result: String) -> void:
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	var validation_result: String = board.validate_local(local_cells)
	assert_eq(validation_result, expected_result)
