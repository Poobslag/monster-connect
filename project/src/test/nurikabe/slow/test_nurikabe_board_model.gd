extends GutTest

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var grid: Array[String] = []

func test_largest_island_groups_zero() -> void:
	grid = [
		"######",
		"######",
		"######",
	]
	assert_largest_island_groups([])
	
	grid = [
		"",
	]
	assert_largest_island_groups([])


func test_largest_island_groups_one() -> void:
	grid = [
		" . . .",
		"######",
		"######",
	]
	assert_largest_island_groups([[
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)
	]])
	
	grid = [
		"######",
		"   3 .",
		"####  ",
	]
	assert_largest_island_groups([[
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2),
	]])
	
	grid = [
		"      ",
		"      ",
		" 3   3",
	]
	assert_largest_island_groups([[
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2),
	]])


func test_largest_island_groups_many() -> void:
	grid = [
		" 2 .##",
		"######",
		"   3  ",
	]
	assert_largest_island_groups([
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],
	])
	
	grid = [
		"##    ",
		"  ## 5",
		"##    ",
	]
	assert_largest_island_groups([
		[Vector2i(0, 1)],
		[Vector2i(1, 0), Vector2i(1, 2), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
	])


func test_smallest_wall_groups_zero() -> void:
	grid = [
		"",
	]
	assert_smallest_wall_groups([])
	
	grid = [
		"      ",
		"      ",
		"      ",
	]
	assert_smallest_wall_groups([])
	
	grid = [
		" . . .",
		" . 9 .",
		" . . .",
	]
	assert_smallest_wall_groups([])


func test_smallest_wall_groups_one() -> void:
	grid = [
		"######",
	]
	assert_smallest_wall_groups([[
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	]])
	
	grid = [
		" .## .",
		" .## .",
		" 3## 3",
	]
	assert_smallest_wall_groups([[
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
	]])


func test_smallest_wall_groups_many() -> void:
	grid = [
		" 5 .  ",
		"  ##  ",
		"## 3##",
	]
	assert_smallest_wall_groups([
		[Vector2i(0, 2)],
		[Vector2i(1, 1)],
		[Vector2i(2, 2)],
	])
	
	grid = [
		"####  ",
		"   3##",
		"######",
	]
	assert_smallest_wall_groups([
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2)],
	])


func test_joined_islands_ok() -> void:
	grid = [
		" 3## 3",
		"  ##  ",
		"  ##  ",
	]
	assert_rules_valid()


func test_joined_islands_two() -> void:
	grid = [
		" 3## 3",
		"  ##  ",
		"      ",
	]
	assert_rules_invalid({"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})
	
	grid = [
		" 3## 3",
		" .## .",
		" .   .",
	]
	assert_rules_invalid({"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})
	
	grid = [
		" 3## 3",
		" .## .",
		" . . .",
	]
	assert_rules_invalid({"joined_islands_unfixable": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})


func test_joined_islands_three() -> void:
	grid = [
		" 3        ",
		"     3    ",
		"         3",
	]
	assert_rules_invalid({"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2),
		Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
		Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2)]})
	
	grid = [
		" 3        ",
		" . . 3    ",
		"         3",
	]
	assert_rules_invalid({
		"joined_islands": [
			Vector2i(0, 2),
			Vector2i(1, 0), Vector2i(1, 2),
			Vector2i(2, 0), Vector2i(2, 2),
			Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
			Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2)],
		"joined_islands_unfixable": [
			Vector2i(0, 0), Vector2i(0, 1),
			Vector2i(1, 1),
			Vector2i(2, 1)]})


func test_pools_ok() -> void:
	grid = [
		" 5    ",
		"##    ",
		"######",
	]
	assert_rules_valid()


func test_pools_one() -> void:
	grid = [
		" 5    ",
		"####  ",
		"####  ",
	]
	assert_rules_invalid({"pools": [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(1, 2)]})


func test_pools_two() -> void:
	grid = [
		" 3    ",
		"######",
		"######",
	]
	assert_rules_invalid({"pools": [
		Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 1), Vector2i(2, 2)]})


func test_split_walls_ok() -> void:
	grid = [
		"######",
		"  ##  ",
		"   5  ",
	]
	assert_rules_valid()
	
	grid = [
		" 3    ",
		" .    ",
		"## 2  ",
	]
	assert_rules_invalid({"joined_islands": [
		Vector2i(0, 0), Vector2i(0, 1),
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]})


func test_split_walls_two() -> void:
	grid = [
		"  ####",
		" 6    ",
		"    ##",
	]
	assert_rules_invalid({"split_walls": [Vector2i(2, 2)]})
	
	grid = [
		"  ####",
		" 6   .",
		"    ##",
	]
	assert_rules_invalid({"split_walls": [Vector2i(2, 2)]})
	
	grid = [
		"  ####",
		" 6 . .",
		"    ##",
	]
	assert_rules_invalid({"split_walls_unfixable": [Vector2i(2, 2)]})


func test_split_walls_three() -> void:
	grid = [
		"##   3",
		"  ##  ",
		" 3  ##",
	]
	assert_rules_invalid({"split_walls": [Vector2i(1, 1), Vector2i(2, 2)]})
	
	grid = [
		"## . 3",
		" .## .",
		" 3 .##",
	]
	assert_rules_invalid({"split_walls_unfixable": [Vector2i(1, 1), Vector2i(2, 2)]})
	
	grid = [
		"##   3",
		"  ## .",
		" 3 .##",
	]
	assert_rules_invalid({
		"split_walls": [Vector2i(1, 1)],
		"split_walls_unfixable": [Vector2i(2, 2)]})


func test_unclued_islands_bad() -> void:
	grid = [
		"##   3",
		"####  ",
		"  ####",
	]
	assert_rules_invalid({"unclued_islands": [Vector2i(0, 2)]})


func test_wrong_size_ok() -> void:
	grid = [
		"##   4",
		"##    ",
		"######",
	]
	assert_rules_valid()


func test_wrong_size_one() -> void:
	grid = [
		"##   3",
		"##    ",
		"######",
	]
	assert_rules_invalid({"wrong_size": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 0), Vector2i(2, 1)]})
	
	grid = [
		"##   3",
		"######",
	]
	assert_rules_invalid({"wrong_size_unfixable": [Vector2i(1, 0), Vector2i(2, 0)]})
	
	grid = [
		"## . 3",
		"## . .",
		"######",
	]
	assert_rules_invalid({"wrong_size_unfixable": [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 0), Vector2i(2, 1)]})


func test_wrong_size_many() -> void:
	grid = [
		" 1## 2",
		"######",
		" 3## 4",
	]
	assert_rules_invalid({"wrong_size_unfixable": [Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 2)]})


func test_duplicate() -> void:
	grid = [
		" 1## 2",
		"######",
		" 3## 4",
	]
	var model: NurikabeBoardModel = init_model()
	var model_copy: NurikabeBoardModel = model.duplicate()
	model_copy.set_cell_string(Vector2i(1, 0), CELL_ISLAND)
	
	assert_groups(model.find_largest_island_groups(), [
		[Vector2i(0, 0)],
		[Vector2i(0, 2)],
		[Vector2i(2, 0)],
		[Vector2i(2, 2)],
	])
	
	assert_groups(model_copy.find_largest_island_groups(), [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
		[Vector2i(0, 2)],
		[Vector2i(2, 2)],
	])


func assert_largest_island_groups(expected: Array[Array]) -> void:
	var model: NurikabeBoardModel = init_model()
	var actual: Array[Array] = model.find_largest_island_groups()
	assert_groups(actual, expected)


func assert_smallest_wall_groups(expected: Array[Array]) -> void:
	var model: NurikabeBoardModel = init_model()
	var actual: Array[Array] = model.find_smallest_wall_groups()
	assert_groups(actual, expected)


func assert_groups(actual: Array[Array], expected: Array[Array]) -> void:
	var actual_sorted: Array[Array] = NurikabeTestUtils.sort_groups(actual)
	var expected_sorted: Array[Array] = NurikabeTestUtils.sort_groups(expected)
	assert_eq(actual_sorted, expected_sorted)


func assert_rules_valid() -> void:
	_assert_rules({})


func assert_rules_invalid(expected_result_dict: Dictionary) -> void:
	_assert_rules(expected_result_dict)


func init_model() -> NurikabeBoardModel:
	return NurikabeTestUtils.init_model(grid)


func _assert_rules(expected_result_dict: Dictionary) -> void:
	var model: NurikabeBoardModel = init_model()
	var validation_result: NurikabeBoardModel.ValidationResult = model.validate()
	for key: String in ["joined_islands", "joined_islands_unfixable",
			"pools", "split_walls", "split_walls_unfixable",
			"unclued_islands", "wrong_size", "wrong_size_unfixable"]:
		var validation_result_value: Array[Vector2i] = validation_result.get(key)
		validation_result_value.sort()
		assert_eq(expected_result_dict.get(key, []), validation_result_value, "Incorrect %s." % [key])
