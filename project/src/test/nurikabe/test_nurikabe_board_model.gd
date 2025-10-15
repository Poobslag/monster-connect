extends GutTest

var grid: Array[String] = []

func test_island_groups_zero() -> void:
	grid = [
		"######",
		"######",
		"######",
	]
	assert_island_group_sizes([])
	
	grid = [
		"",
	]
	assert_island_group_sizes([])


func test_island_groups_one() -> void:
	grid = [
		" . . .",
		"######",
		"######",
	]
	assert_island_group_sizes([3])
	
	grid = [
		"######",
		"   3 .",
		"####  ",
	]
	assert_island_group_sizes([4])
	
	grid = [
		"      ",
		"      ",
		" 3   3",
	]
	assert_island_group_sizes([9])


func test_island_groups_many() -> void:
	grid = [
		" 2 .##",
		"######",
		"   3  ",
	]
	assert_island_group_sizes([2, 3])
	
	grid = [
		"##    ",
		"  ## 5",
		"##    ",
	]
	assert_island_group_sizes([1, 5])


func test_wall_groups_zero() -> void:
	grid = [
		"",
	]
	assert_wall_group_sizes([])
	
	grid = [
		"      ",
		"      ",
		"      ",
	]
	assert_wall_group_sizes([])
	
	grid = [
		" . . .",
		" . 9 .",
		" . . .",
	]
	assert_wall_group_sizes([])


func test_wall_groups_one() -> void:
	grid = [
		"######",
	]
	assert_wall_group_sizes([3])
	
	grid = [
		" .## .",
		" .## .",
		" 3## 3",
	]
	assert_wall_group_sizes([3])


func test_wall_groups_many() -> void:
	grid = [
		" 5 .  ",
		"  ##  ",
		"## 3##",
	]
	assert_wall_group_sizes([1, 1, 1])
	
	grid = [
		"####  ",
		"   3##",
		"######",
	]
	assert_wall_group_sizes([2, 4])


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


func assert_rules_valid() -> void:
	_assert_rules({})


func assert_rules_invalid(expected_result_dict: Dictionary) -> void:
	_assert_rules(expected_result_dict)


func assert_island_group_sizes(expected: Array[int]) -> void:
	var model: NurikabeBoardModel = init_model()
	var island_groups: Array[Array] = model.find_island_groups()
	_assert_group_sizes(island_groups, expected, "island")


func assert_wall_group_sizes(expected: Array[int]) -> void:
	var model: NurikabeBoardModel = init_model()
	var wall_groups: Array[Array] = model.find_wall_groups()
	_assert_group_sizes(wall_groups, expected, "wall")


func init_model() -> NurikabeBoardModel:
	var model: NurikabeBoardModel = NurikabeBoardModel.new()
	for y in grid.size():
		var row_string: String = grid[y]
		@warning_ignore("integer_division")
		for x in row_string.length() / 2:
			model.set_cell_string(Vector2i(x, y), row_string.substr(x * 2, 2).strip_edges())
	return model


func _assert_rules(expected_result_dict: Dictionary) -> void:
	var model: NurikabeBoardModel = init_model()
	var validation_result: NurikabeBoardModel.ValidationResult = model.validate()
	for key: String in ["joined_islands", "joined_islands_unfixable",
			"pools", "split_walls", "split_walls_unfixable",
			"unclued_islands", "wrong_size", "wrong_size_unfixable"]:
		var validation_result_value: Array[Vector2i] = validation_result.get(key)
		validation_result_value.sort()
		assert_eq(expected_result_dict.get(key, []), validation_result_value, "Incorrect %s." % [key])


func _assert_group_sizes(got_groups: Array[Array], expected: Array[int], group_name: String) -> void:
	var group_sizes: Array[int] = []
	for group: Array[Vector2i] in got_groups:
		group_sizes.push_back(group.size())
	group_sizes.sort()
	assert_eq(group_sizes, expected, "Incorrect %s group sizes." % [group_name])
