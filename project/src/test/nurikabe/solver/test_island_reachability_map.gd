extends GutTest

var grid: Array[String] = []

func test_get_clue_reachability() -> void:
	grid = [
		"    ##  ",
		"      ##",
		" 2   2  ",
	]
	var trm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(trm.get_clue_reachability(Vector2(0, 0)), IslandReachabilityMap.ClueReachability.UNREACHABLE)
	assert_eq(trm.get_clue_reachability(Vector2(0, 2)), IslandReachabilityMap.ClueReachability.IMPOSSIBLE)
	assert_eq(trm.get_clue_reachability(Vector2(0, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(trm.get_clue_reachability(Vector2(1, 2)), IslandReachabilityMap.ClueReachability.CONFLICT)
	assert_eq(trm.get_clue_reachability(Vector2(2, 0)), IslandReachabilityMap.ClueReachability.IMPOSSIBLE)
	assert_eq(trm.get_clue_reachability(Vector2(3, 0)), IslandReachabilityMap.ClueReachability.IMPOSSIBLE)


func test_get_clue_reachability_avoids_cycles() -> void:
	grid = [
		"       6",
		" 2      ",
		"        ",
	]
	var trm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(trm.get_clue_reachability(Vector2(1, 0)), IslandReachabilityMap.ClueReachability.CHAIN_CYCLE)
	assert_eq(trm.get_clue_reachability(Vector2(1, 2)), IslandReachabilityMap.ClueReachability.CHAIN_CYCLE)


func test_get_clue_reachability_cycles_janko_3() -> void:
	grid = [
		"         3          ",
		"   3##  ##        ##",
		"  ## 3## 3       3##",
		"     .    ##  #### 3",
		"             .## . .",
		" 3        ## 3######",
		"           3## . 3##",
		"     3     .## .## 3",
		"        ########## .",
		" 3      ## 3 . .## .",
	]
	var trm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(trm.get_clue_reachability(Vector2(5, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)


func test_get_clue_reachability_unclued_cycles() -> void:
	grid = [
		"       6",
		" 2      ",
		"     .  ",
	]
	var trm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(trm.get_clue_reachability(Vector2(2, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(trm.get_clue_reachability(Vector2(3, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(trm.get_clue_reachability(Vector2(3, 2)), IslandReachabilityMap.ClueReachability.REACHABLE)


func test_get_nearest_clued_island_cell() -> void:
	grid = [
		"    ##  ",
		"      ##",
		" 2     3",
	]
	var grm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(grm.get_nearest_clued_island_cell(Vector2(2, 1)), Vector2i(3, 2))
	assert_eq(grm.get_nearest_clued_island_cell(Vector2(0, 0)), Vector2i(0, 2))
	assert_eq(grm.get_nearest_clued_island_cell(Vector2(3, 0)), NurikabeUtils.POS_NOT_FOUND)
	grm.board.cleanup()


func init_island_reachability_map() -> IslandReachabilityMap:
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	return IslandReachabilityMap.new(board)
