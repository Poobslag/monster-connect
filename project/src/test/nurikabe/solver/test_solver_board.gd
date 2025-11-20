extends GutTest

var grid: Array[String]


func test_joined_islands_two() -> void:
	grid = [
		" 3## 3",
		"  ##  ",
		"  ##  ",
	]
	assert_valid_strict()
	
	grid = [
		" 3## 3",
		"  ##  ",
		"      ",
	]
	assert_invalid_strict({"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})
	assert_valid()
	
	grid = [
		" 3## 3",
		" .## .",
		" .   .",
	]
	assert_invalid_strict({"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})
	assert_valid()
	
	grid = [
		" 3## 3",
		" .## .",
		" . . .",
	]
	assert_invalid({"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})


func test_joined_islands_three() -> void:
	grid = [
		" 3        ",
		"     3    ",
		"         3",
	]
	assert_invalid_strict({
		"joined_islands": [
			Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
			Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
			Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2),
			Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
			Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2),
			]})
	assert_valid()
	
	grid = [
		" 3        ",
		" . . 3    ",
		"         3",
	]
	assert_invalid({
		"joined_islands": [
			Vector2i(0, 0), Vector2i(0, 1),
			Vector2i(1, 1),
			Vector2i(2, 1)]})


func test_pools_ok() -> void:
	grid = [
		" 5    ",
		"##    ",
		"######",
	]
	assert_valid_strict()


func test_pools_one() -> void:
	grid = [
		" 5    ",
		"####  ",
		"####  ",
	]
	assert_invalid_strict({"pools": [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(1, 2)]})


func test_pools_two() -> void:
	grid = [
		" 3    ",
		"######",
		"######",
	]
	assert_invalid_strict({"pools": [
		Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 1), Vector2i(2, 2)]})


func test_split_walls_ok() -> void:
	grid = [
		"######",
		"  ##  ",
		"   5  ",
	]
	assert_valid_strict()
	
	grid = [
		" 8    ",
		" .    ",
		"## .  ",
	]
	assert_valid_strict()


func test_split_walls_two() -> void:
	grid = [
		"  ####",
		" 6    ",
		"    ##",
	]
	assert_invalid_strict({"split_walls": [Vector2i(2, 2)]})
	assert_valid()
	
	grid = [
		"  ####",
		" 6   .",
		"    ##",
	]
	assert_valid()
	
	grid = [
		"  ####",
		" 6 . .",
		"    ##",
	]
	assert_invalid({"split_walls": [Vector2i(2, 2)]})


func test_split_walls_three() -> void:
	grid = [
		"##   3",
		"  ##  ",
		" 3  ##",
	]
	assert_invalid_strict({"split_walls": [Vector2i(1, 1), Vector2i(2, 2)]})
	assert_valid()
	
	grid = [
		"## . 3",
		" .## .",
		" 3 .##",
	]
	assert_invalid({"split_walls": [Vector2i(1, 1), Vector2i(2, 2)]})
	
	grid = [
		"##   3",
		"  ## .",
		" 3 .##",
	]
	assert_invalid({"split_walls": [Vector2i(2, 2)]})


func test_unclued_islands() -> void:
	grid = [
		"##    ",
		"#### 3",
		"  ####",
	]
	assert_invalid_strict({"unclued_islands": [Vector2i(0, 2)]})
	assert_valid()
	
	grid = [
		"## .  ",
		"#### 3",
		"  ####",
	]
	assert_valid()
	
	grid = [
		"##    ",
		"#### 3",
		" .####",
	]
	assert_invalid({"unclued_islands": [Vector2i(0, 2)]})


func test_wrong_size() -> void:
	grid = [
		"##   4",
		"##    ",
		"######",
	]
	assert_valid_strict()
	assert_valid()
	
	grid = [
		"#### 4",
		"##    ",
		"######",
	]
	assert_invalid_strict({"wrong_size": [Vector2i(1, 1), Vector2i(2, 0), Vector2i(2, 1)]})
	assert_invalid({"wrong_size": [Vector2i(2, 0)]})
	
	grid = [
		" . . 4",
		"## . .",
		"######",
	]
	assert_invalid_strict({"wrong_size": [
			Vector2i(0, 0),
			Vector2i(1, 0), Vector2i(1, 1),
			Vector2i(2, 0), Vector2i(2, 1)]})
	assert_invalid({"wrong_size": [
			Vector2i(0, 0),
			Vector2i(1, 0), Vector2i(1, 1),
			Vector2i(2, 0), Vector2i(2, 1)]})


func test_wrong_size_neighbors() -> void:
	grid = [
		"##   4",
		"      ",
		" 1  ##",
	]
	assert_valid()
	
	# these clues can't grow to their full size, but our validator is too simple to catch that
	grid = [
		"##   5",
		"      ",
		" 1  ##",
	]
	assert_valid()
	
	# these clues can't grow to their full size, but our validator is too simple to catch that
	grid = [
		"## . 5",
		"   . .",
		" 1  ##",
	]
	assert_invalid({"split_walls": [Vector2i(2, 2)]})


func assert_valid() -> void:
	_assert_validate("validate", {})


func assert_invalid(expected_result_dict: Dictionary) -> void:
	_assert_validate("validate", expected_result_dict)


func assert_valid_strict() -> void:
	_assert_validate("validate_strict", {})


func assert_invalid_strict(expected_result_dict: Dictionary) -> void:
	_assert_validate("validate_strict", expected_result_dict)


func _assert_validate(method: String, expected_result_dict: Dictionary) -> void:
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	var validation_result: SolverBoard.ValidationResult = board.call(method)
	for key: String in ["joined_islands", "pools", "split_walls", "unclued_islands", "wrong_size"]:
		var validation_result_value: Array[Vector2i] = validation_result.get(key)
		validation_result_value.sort()
		assert_eq(expected_result_dict.get(key, []), validation_result_value, "Incorrect %s." % [key])
