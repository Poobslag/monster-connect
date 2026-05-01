extends FindPuzzleActionState
## Find the nearest game board.

var _find_target_cooldown_remaining: float = 0.0

## Called when the state is entered.
func enter() -> void:
	_find_target_cooldown_remaining = randf_range(0, FindPuzzleAction.FIND_TARGET_COOLDOWN)
	action.target_game_board = null
	action.target_path = []


## Called every frame to update the active state.
func update(delta: float) -> void:
	_find_target_cooldown_remaining -= delta
	if _find_target_cooldown_remaining <= 0:
		_find_target_cooldown_remaining = FindPuzzleAction.FIND_TARGET_COOLDOWN
		action.find_target()
		if action.target_game_board == null:
			change_state("finished")
		else:
			change_state("approach")


## Called when the state is exited.
func exit() -> void:
	pass
