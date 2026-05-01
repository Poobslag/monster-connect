extends FindPuzzleActionState
## The sim has arrived at a game board.

func enter() -> void:
	monster.input.dir = Vector2.ZERO
	monster.solving_board = action.target_game_board
	action.target_game_board = null
