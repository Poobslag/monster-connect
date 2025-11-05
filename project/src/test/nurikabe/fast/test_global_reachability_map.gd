extends GutTest

var grid: Array[String] = []

func test_get_clue_reachability() -> void:
	grid = [
		"    ##  ",
		"      ##",
		" 2   2  ",
	]
	var grm: GlobalReachabilityMap = init_global_reachability_map()
	assert_eq(grm.get_clue_reachability(Vector2(0, 0)), GlobalReachabilityMap.ClueReachability.UNREACHABLE)
	assert_eq(grm.get_clue_reachability(Vector2(0, 2)), GlobalReachabilityMap.ClueReachability.IMPOSSIBLE)
	assert_eq(grm.get_clue_reachability(Vector2(0, 1)), GlobalReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(grm.get_clue_reachability(Vector2(1, 2)), GlobalReachabilityMap.ClueReachability.CONFLICT)
	assert_eq(grm.get_clue_reachability(Vector2(2, 0)), GlobalReachabilityMap.ClueReachability.IMPOSSIBLE)
	assert_eq(grm.get_clue_reachability(Vector2(3, 0)), GlobalReachabilityMap.ClueReachability.IMPOSSIBLE)


func test_get_nearest_clue_cell() -> void:
	grid = [
		"      ",
		" 1    ",
		"     2",
	]
	var grm: GlobalReachabilityMap = init_global_reachability_map()
	assert_eq(grm.get_nearest_clue_cell(Vector2(1, 1)), Vector2i(0, 1))
	assert_eq(grm.get_nearest_clue_cell(Vector2(2, 0)), Vector2i(2, 2))
	assert_eq(grm.get_nearest_clue_cell(Vector2(2, 1)), Vector2i(2, 2))


func init_global_reachability_map() -> GlobalReachabilityMap:
	var board: FastBoard = FastTestUtils.init_board(grid)
	return GlobalReachabilityMap.new(board)
