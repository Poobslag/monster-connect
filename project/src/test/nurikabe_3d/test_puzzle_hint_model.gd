extends GutTest

var hint_model: PuzzleHintModel

func test_init() -> void:
	var puzzle_info: PuzzleInfo = PuzzleInfoSaver.new() \
			.load_puzzle_info("res://assets/test/nurikabe/example_474.txt.info")
	hint_model = PuzzleHintModel.new(puzzle_info)
	
	assert_eq(hint_model.solution_grid.get(Vector2i(0, 0)), 3)
	assert_eq(hint_model.solution_grid.get(Vector2i(0, 2)), 1)
	
	assert_eq(hint_model.order_grid.get(Vector2i(3, 0)), 5)
	assert_eq(hint_model.order_grid.get(Vector2i(2, 1)), 4)
	assert_eq(hint_model.order_grid.has(Vector2i(0, 0)), false)
	
	assert_eq(hint_model.reason_grid.get(Vector2i(0, 1)), Deduction.Reason.ISLAND_OF_ONE)
	assert_eq(hint_model.reason_grid.get(Vector2i(1, 1)), Deduction.Reason.WALL_EXPANSION)
	assert_eq(hint_model.reason_grid.has(Vector2i(0, 0)), false)


func test_init_mirrored() -> void:
	var puzzle_info: PuzzleInfo = PuzzleInfoSaver.new() \
			.load_puzzle_info("res://assets/test/nurikabe/example_474.txt.info")
	hint_model = PuzzleHintModel.new(puzzle_info, true, 0)
	
	assert_eq(hint_model.solution_grid.get(Vector2i(4, 0)), 3)
	assert_eq(hint_model.solution_grid.get(Vector2i(4, 2)), 1)
	
	assert_eq(hint_model.order_grid.get(Vector2i(3, 0)), 5)
	assert_eq(hint_model.order_grid.get(Vector2i(2, 1)), 4)
	
	assert_eq(hint_model.reason_grid.get(Vector2i(4, 1)), Deduction.Reason.ISLAND_OF_ONE)
	assert_eq(hint_model.reason_grid.get(Vector2i(3, 1)), Deduction.Reason.WALL_EXPANSION)


func test_init_rotated() -> void:
	var puzzle_info: PuzzleInfo = PuzzleInfoSaver.new() \
			.load_puzzle_info("res://assets/test/nurikabe/example_474.txt.info")
	hint_model = PuzzleHintModel.new(puzzle_info, false, 1)
	
	assert_eq(hint_model.solution_grid.get(Vector2i(7, 0)), 3)
	assert_eq(hint_model.solution_grid.get(Vector2i(5, 0)), 1)
	
	assert_eq(hint_model.order_grid.get(Vector2i(7, 1)), 5)
	assert_eq(hint_model.order_grid.get(Vector2i(6, 2)), 4)
	
	assert_eq(Deduction.Reason.ISLAND_OF_ONE, hint_model.reason_grid.get(Vector2i(6, 0)))
	assert_eq(Deduction.Reason.WALL_EXPANSION, hint_model.reason_grid.get(Vector2i(6, 1)))
