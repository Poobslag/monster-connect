extends GutTest

func test_load_grid_string_from_file_janko() -> void:
	var grid_string: String = NurikabeUtils.load_grid_string_from_file(
			"assets/demo/nurikabe/puzzles/janko/101.janko")
	assert_eq(grid_string, " 1    \n      \n   5  ")


func test_load_grid_string_from_file_janko_big_number() -> void:
	var grid_string: String = NurikabeUtils.load_grid_string_from_file(
			"assets/demo/nurikabe/puzzles/janko/1030.janko")
	assert_eq(true, grid_string.contains("(994)"))


func test_mirror_grid_string() -> void:
	var result: String = NurikabeUtils.mirror_grid_string("\n".join([
		"      ",
		" 1    ",
		"     2",
	]))
	assert_eq(result, "\n".join([
		"      ",
		"     1",
		" 2    ",
	]))


func test_rotate_grid_string_0() -> void:
	var result: String = NurikabeUtils.rotate_grid_string("\n".join([
		" 1  ",
		"    ",
		"   2",
	]), 0)
	assert_eq(result, "\n".join([
		" 1  ",
		"    ",
		"   2",
	]))


func test_rotate_grid_string_1() -> void:
	var result: String = NurikabeUtils.rotate_grid_string("\n".join([
		" 1  ",
		"    ",
		"   2",
	]), 1)
	assert_eq(result, "\n".join([
		"     1",
		" 2    ",
	]))


func test_rotate_grid_string_2() -> void:
	var result: String = NurikabeUtils.rotate_grid_string("\n".join([
		" 1  ",
		"    ",
		"   2",
	]), 2)
	assert_eq(result, "\n".join([
		" 2  ",
		"    ",
		"   1",
	]))


func test_rotate_grid_string_3() -> void:
	var result: String = NurikabeUtils.rotate_grid_string("\n".join([
		" 1  ",
		"    ",
		"   2",
	]), 3)
	assert_eq(result, "\n".join([
		"     2",
		" 1    ",
	]))
