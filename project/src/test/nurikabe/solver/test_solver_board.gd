extends GutTest

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const VALIDATE_STRICT: SolverBoard.ValidationMode = SolverBoard.VALIDATE_STRICT
const VALIDATE_COMPLEX: SolverBoard.ValidationMode = SolverBoard.VALIDATE_COMPLEX
const VALIDATE_SIMPLE: SolverBoard.ValidationMode = SolverBoard.VALIDATE_SIMPLE

var grid: Array[String]

func test_islands() -> void:
	grid = [
		" 3## 2",
		"  ##  ",
		"  ##  ",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	assert_groups(board.islands, [
		{"cells": [Vector2i(0, 0)], "clue": 3, "liberties": [Vector2i(0, 1)]},
		{"cells": [Vector2i(2, 0)], "clue": 2, "liberties": [Vector2i(2, 1)]},
	])


func test_set_cell_island_open_islands() -> void:
	grid = [
		" 5    ",
		" . .  ",
		"  ##  ",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	assert_groups(board.islands, [
		{
			"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
			"clue": 5,
			"liberties": [Vector2i(0, 2), Vector2i(1, 0), Vector2i(2, 1)],
		},
	])
	board.set_cell(Vector2i(2, 1), CELL_ISLAND)
	assert_groups(board.islands, [
		{
			"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
			"clue": 5,
			"liberties": [Vector2i(0, 2), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 2)],
		},
	])


func test_set_cell_island_merge_islands() -> void:
	grid = [
		" 5   .",
		" . .  ",
		"  ##  ",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	assert_groups(board.islands, [
		{
			"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
			"clue": 5,
			"liberties": [Vector2i(0, 2), Vector2i(1, 0), Vector2i(2, 1)],
		},
		{
			"cells": [Vector2i(2, 0)],
			"clue": 0,
			"liberties": [Vector2i(1, 0), Vector2i(2, 1)],
		},
	])
	board.set_cell(Vector2i(1, 0), CELL_ISLAND)
	assert_groups(board.islands, [
		{
			"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 0)],
			"clue": 5,
			"liberties": [Vector2i(0, 2), Vector2i(2, 1)],
		},
	])


func test_set_cell_wall_close_island() -> void:
	grid = [
		" 5    ",
		" . .  ",
		"  ##  ",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	assert_groups(board.islands, [
		{
			"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
			"clue": 5,
			"liberties": [Vector2i(0, 2), Vector2i(1, 0), Vector2i(2, 1)],
		},
	])
	board.set_cell(Vector2i(0, 2), CELL_WALL)
	assert_groups(board.islands, [
		{
			"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
			"clue": 5,
			"liberties": [Vector2i(1, 0), Vector2i(2, 1)],
		},
	])


func test_walls() -> void:
	grid = [
		"## 1##",
		"  ##  ",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	assert_groups(board.walls, [
		{"cells": [Vector2i(0, 0)], "clue": 0, "liberties": [Vector2i(0, 1)]},
		{"cells": [Vector2i(1, 1)], "clue": 0, "liberties": [Vector2i(0, 1), Vector2i(2, 1)]},
		{"cells": [Vector2i(2, 0)], "clue": 0, "liberties": [Vector2i(2, 1)]},
	])


func test_set_cell_walls() -> void:
	grid = [
		"##  ##",
		" 1## 1",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	assert_groups(board.walls, [
		{"cells": [Vector2i(0, 0)], "clue": 0, "liberties": [Vector2i(1, 0)]},
		{"cells": [Vector2i(1, 1)], "clue": 0, "liberties": [Vector2i(1, 0)]},
		{"cells": [Vector2i(2, 0)], "clue": 0, "liberties": [Vector2i(1, 0)]},
	])
	board.set_cell(Vector2i(1, 0), CELL_WALL)
	assert_groups(board.walls, [
		{"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 0)], "clue": 0, "liberties": []},
	])


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


func assert_groups(actual_groups: Array[CellGroup], expected_props_list: Array[Dictionary]) -> void:
	var actual_props_list: Array[Dictionary] = []
	for actual_group: CellGroup in actual_groups:
		actual_props_list.append({
			"cells": actual_group.cells,
			"clue": actual_group.clue,
			"liberties": actual_group.liberties,
		})
	for props_list: Array[Dictionary] in [actual_props_list, expected_props_list]:
		for props: Dictionary in props_list:
			if props.has("liberties"):
				props["liberties"].sort()
			if props.has("cells"):
				props["cells"].sort()
		props_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return a["cells"].front() > b["cells"].front())
	assert_eq(actual_props_list, expected_props_list)


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
