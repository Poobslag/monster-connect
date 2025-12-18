extends TestGenerator

func test_find_island_guide_cell_candidates() -> void:
	grid = [
		"## ?##    ",
		"## .      ",
		"##        ",
		"          ",
	]
	generator.board = GeneratorTestUtils.init_board(grid)
	var island: CellGroup = generator.board.solver_board.get_island_for_cell(Vector2i(1, 0))
	var candidates: Array[Vector2i] = generator.find_island_guide_cell_candidates(island)
	candidates.sort()
	assert_eq(candidates, [Vector2i(1, 3), Vector2i(3, 1)])
