class_name Generator

var board: GeneratorBoard

func generate() -> void:
	board.solver_board.set_clue(Vector2i(0, 0), 1)
