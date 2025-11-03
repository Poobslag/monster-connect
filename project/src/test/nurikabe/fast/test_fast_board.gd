extends GutTest

var grid: Array[String] = []


func test_get_nearest_clue_cell() -> void:
	grid = [
		"      ",
		" 1    ",
		"     2",
	]
	var board: FastBoard = FastTestUtils.init_board(grid)
	assert_eq(board.get_nearest_clue_cell(Vector2(1, 1)), Vector2i(0, 1))
	assert_eq(board.get_nearest_clue_cell(Vector2(2, 0)), Vector2i(2, 2))
	assert_eq(board.get_nearest_clue_cell(Vector2(2, 1)), Vector2i(2, 2))


func test_get_clue_reachability() -> void:
	grid = [
		"    ##  ",
		"      ##",
		" 2   2  ",
	]
	var board: FastBoard = FastTestUtils.init_board(grid)
	assert_eq(board.get_clue_reachability(Vector2(0, 0)), FastBoard.ClueReachability.UNREACHABLE)
	assert_eq(board.get_clue_reachability(Vector2(0, 2)), FastBoard.ClueReachability.IMPOSSIBLE)
	assert_eq(board.get_clue_reachability(Vector2(0, 1)), FastBoard.ClueReachability.REACHABLE)
	assert_eq(board.get_clue_reachability(Vector2(1, 2)), FastBoard.ClueReachability.CONFLICT)
	assert_eq(board.get_clue_reachability(Vector2(2, 0)), FastBoard.ClueReachability.IMPOSSIBLE)
	assert_eq(board.get_clue_reachability(Vector2(3, 0)), FastBoard.ClueReachability.IMPOSSIBLE)
