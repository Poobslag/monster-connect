class_name TestGeneratorUtils
extends GutTest

func test_best_clue_cells_for_unclued_island() -> void:
	var grid: Array[String] = [
		" 2## 2## .",
		" .## .## .",
		"######## .",
		" . . . . .",
		" . . . . .",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	var island: CellGroup = board.get_island_for_cell(Vector2i(4, 0))
	var clue_cells: Array[Vector2i] = \
			GeneratorUtils.best_clue_cells_for_unclued_island(board, island)
	assert_eq(clue_cells, [Vector2i(4, 0)])


func test_best_clue_cells_for_unclued_island_single() -> void:
	var grid: Array[String] = [
		" . . .",
		" . . .",
	]
	var board: SolverBoard = SolverTestUtils.init_board(grid)
	var island: CellGroup = board.get_island_for_cell(Vector2i(2, 0))
	var clue_cells: Array[Vector2i] = \
			GeneratorUtils.best_clue_cells_for_unclued_island(board, island)
	assert_eq(clue_cells, [
			Vector2i(0, 0), Vector2i(0, 1),
			Vector2i(1, 0), Vector2i(1, 1),
			Vector2i(2, 0), Vector2i(2, 1),
		])
