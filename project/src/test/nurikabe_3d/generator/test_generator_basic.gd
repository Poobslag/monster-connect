extends TestGenerator

func test_find_island_guide_cell_candidates() -> void:
	grid = [
		"## ?##    ",
		"## .      ",
		"##        ",
		"          ",
	]
	generator.board = GeneratorTestUtils.init_board(grid)
	var island: CellGroup = generator.board.get_island_for_cell(Vector2i(1, 0))
	var candidates: Array[Vector2i] = generator.find_island_guide_cell_candidates(island)
	candidates.sort()
	assert_eq(candidates, [Vector2i(1, 3), Vector2i(3, 1)])
	generator.board.cleanup()


func test_attempt_island_buffer_from() -> void:
	grid = [
		"########  ",
		"## ? .    ",
		" ?##      ",
		" .        ",
		"          ",
	]
	generator.board = GeneratorTestUtils.init_board(grid)
	var island: CellGroup = generator.board.get_island_for_cell(Vector2i(1, 1))
	var expected: Array[String] = [
		"(3, 2)->## island_buffer (1, 1)",
		"(4, 2)->? island_buffer (1, 1)",
	]
	var callable: Callable = generator.attempt_island_buffer_from.bind( \
			island, Vector2i(3, 2), [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT] as Array[Vector2i])
	assert_placements(callable, expected)
	assert_clue_minimum_changes(["{ \"pos\": (1, 1), \"value\": 3 }"])
	generator.board.cleanup()
