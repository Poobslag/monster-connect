extends GutTest

var grid: Array[String] = []

func test_get_clue_reachability() -> void:
	grid = [
		"    ##  ",
		"      ##",
		" 2   2  ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_clue_reachability(Vector2(0, 0)), IslandReachabilityMap.ClueReachability.UNREACHABLE)
	assert_eq(irm.get_clue_reachability(Vector2(0, 2)), IslandReachabilityMap.ClueReachability.IMPOSSIBLE)
	assert_eq(irm.get_clue_reachability(Vector2(0, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(irm.get_clue_reachability(Vector2(1, 2)), IslandReachabilityMap.ClueReachability.CONFLICT)
	assert_eq(irm.get_clue_reachability(Vector2(2, 0)), IslandReachabilityMap.ClueReachability.IMPOSSIBLE)
	assert_eq(irm.get_clue_reachability(Vector2(3, 0)), IslandReachabilityMap.ClueReachability.IMPOSSIBLE)


func test_get_clue_reachability_avoids_cycles() -> void:
	grid = [
		"       6",
		" 2      ",
		"        ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_clue_reachability(Vector2(1, 0)), IslandReachabilityMap.ClueReachability.CHAIN_CYCLE)
	assert_eq(irm.get_clue_reachability(Vector2(1, 2)), IslandReachabilityMap.ClueReachability.CHAIN_CYCLE)


func test_get_clue_reachability_avoids_cycles_2() -> void:
	grid = [
		"#### 4 .  ",
		" 7####    ",
		" .   .  ##",
		"      ## 1",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_clue_reachability(Vector2(3, 2)), IslandReachabilityMap.ClueReachability.CHAIN_CYCLE)


func test_get_clue_reachability_avoids_large_islands() -> void:
	grid = [
		" 3    ",
		"      ",
		"   .  ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_clue_reachability(Vector2(0, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(irm.get_clue_reachability(Vector2(0, 2)), IslandReachabilityMap.ClueReachability.UNREACHABLE)
	assert_eq(irm.get_clue_reachability(Vector2(1, 0)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(irm.get_clue_reachability(Vector2(1, 1)), IslandReachabilityMap.ClueReachability.UNREACHABLE)


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
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_clue_reachability(Vector2(5, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)


func test_get_clue_reachability_janko_8() -> void:
	# janko 8
	grid = [
		"   2    ## 4 . . .##",
		"          ##########",
		"        ## . .## 1##",
		"        ## 3###### 3",
		"         9#### .## .",
		"##         .## 2## .",
		"## .       . .######",
		"## 6## 6    #### 1##",
		" 3####    ## 2 .## 2",
		" . .##    ######## .",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_reach_score(Vector2(5, 5), irm.board.get_island_for_cell(Vector2i(4, 4)).root), 5)
	assert_eq(irm.get_reach_score(Vector2(5, 6), irm.board.get_island_for_cell(Vector2i(4, 4)).root), 5)
	assert_eq(irm.get_reach_score(Vector2(6, 6), irm.board.get_island_for_cell(Vector2i(4, 4)).root), 5)
	assert_eq(irm.get_reach_score(Vector2(5, 5), irm.board.get_island_for_cell(Vector2i(3, 7)).root), 1)
	assert_eq(irm.get_reach_score(Vector2(5, 6), irm.board.get_island_for_cell(Vector2i(3, 7)).root), 1)
	assert_eq(irm.get_reach_score(Vector2(6, 6), irm.board.get_island_for_cell(Vector2i(3, 7)).root), 1)


func test_get_clue_reachability_lifeline_6() -> void:
	grid = [
		"####     4",
		"## .      ",
		"## .      ",
		"## 8     .",
		"######## .",
		" 2 .  ## .",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_reach_score(Vector2(2, 1), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 5)
	assert_eq(irm.get_reach_score(Vector2(2, 2), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 5)
	assert_eq(irm.get_reach_score(Vector2(2, 3), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 5)
	assert_eq(irm.get_reach_score(Vector2(3, 3), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 1)
	assert_lte(irm.get_reach_score(Vector2(4, 2), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 0)
	assert_eq(irm.get_reach_score(Vector2(4, 3), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 1)
	assert_eq(irm.get_reach_score(Vector2(4, 4), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 1)
	assert_eq(irm.get_reach_score(Vector2(4, 5), irm.board.get_island_for_cell(Vector2i(1, 1)).root), 1)


func test_get_clue_reachability_unclued_cycles() -> void:
	grid = [
		"       6",
		" 2      ",
		"     .  ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_clue_reachability(Vector2(2, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(irm.get_clue_reachability(Vector2(3, 1)), IslandReachabilityMap.ClueReachability.REACHABLE)
	assert_eq(irm.get_clue_reachability(Vector2(3, 2)), IslandReachabilityMap.ClueReachability.REACHABLE)


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


func test_get_reach_score() -> void:
	grid = [
		"       6",
		" 2      ",
		"        ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_reach_score(Vector2i(0, 0), Vector2i(0, 1)), 1)
	assert_lte(irm.get_reach_score(Vector2i(1, 0), Vector2i(0, 1)), 0)


func test_get_reach_score_avoids_neighbors() -> void:
	grid = [
		" 1##    ",
		"##      ",
		"       6",
		"        ",
		"     3  ",
		"## .    ",
		"########",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	assert_eq(irm.get_reach_score(Vector2i(1, 3), Vector2i(3, 2)), 3)
	assert_lte(irm.get_reach_score(Vector2i(1, 4), Vector2i(3, 2)), 0)


func test_get_reach_score_unclued_blob_near() -> void:
	# If the 9 expands up first, its reachability is low. But if it expands right first, its reachability is high.
	# We should return the highest reachability for each cell.
	grid = [
		" .      ",
		" .      ",
		" .      ",
		" .      ",
		" .      ",
		"        ",
		" 9      ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	
	# we cannot absorb this cell without absorbing the large blob
	assert_eq(irm.get_reach_score(Vector2i(1, 4), Vector2i(0, 6)), 2)
	
	# we can absorb this cell without absorbing the large blob
	assert_eq(irm.get_reach_score(Vector2i(2, 4), Vector2i(0, 6)), 5)


func test_get_reach_score_unclued_blob_far() -> void:
	# If the 9 expands up first, its reachability is low. But if it expands right first, its reachability is high.
	# We should return the highest reachability for each cell.
	grid = [
		" . . .  ",
		"   . .  ",
		"        ",
		" 9      ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	
	# we cannot absorb this cell without absorbing the large blob
	assert_eq(irm.get_reach_score(Vector2i(2, 2), Vector2i(0, 3)), 1)
	
	# we can absorb this cell without absorbing the large blob
	assert_eq(irm.get_reach_score(Vector2i(3, 2), Vector2i(0, 3)), 5)


func test_get_reach_score_chained_blobs() -> void:
	# If the 9 expands up first, its reachability is low. But if it expands right first, its reachability is high.
	# We should return the highest reachability for each cell.
	grid = [
		"10   .   .   .",
		"         .    ",
	]
	var irm: IslandReachabilityMap = init_island_reachability_map()
	
	# absorbing the first large blob (size 1)
	assert_eq(irm.get_reach_score(Vector2i(1, 0), Vector2i(0, 0)), 8)
	assert_eq(irm.get_reach_score(Vector2i(2, 0), Vector2i(0, 0)), 8)
	
	# absorbing the second large blob (size 2)
	assert_eq(irm.get_reach_score(Vector2i(3, 0), Vector2i(0, 0)), 5)
	assert_eq(irm.get_reach_score(Vector2i(4, 0), Vector2i(0, 0)), 5)
	
	# absorbing the third large blob (size 1)
	assert_eq(irm.get_reach_score(Vector2i(5, 0), Vector2i(0, 0)), 3)
	assert_eq(irm.get_reach_score(Vector2i(6, 0), Vector2i(0, 0)), 3)


func init_island_reachability_map() -> IslandReachabilityMap:
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	return IslandReachabilityMap.new(board)
