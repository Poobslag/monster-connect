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
