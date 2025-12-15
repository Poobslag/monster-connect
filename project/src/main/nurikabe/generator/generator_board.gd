class_name GeneratorBoard

var solver_board: SolverBoard = SolverBoard.new()

func from_game_board(game_board: NurikabeGameBoard) -> void:
	solver_board.from_game_board(game_board)
