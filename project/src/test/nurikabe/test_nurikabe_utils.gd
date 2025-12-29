extends GutTest

func test_load_grid_string_from_file_janko() -> void:
	var grid_string: String = NurikabeUtils.load_grid_string_from_file(
			"assets/demo/nurikabe/puzzles/janko/101.janko")
	assert_eq(grid_string, " 1    \n      \n   5  ")
