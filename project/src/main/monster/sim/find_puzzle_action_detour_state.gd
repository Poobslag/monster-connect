extends FindPuzzleActionState
## Navigate around an obstacle.

const DETOUR_DURATION: float = 0.4

var _detour_duration_remaining: float = 0.0

func enter() -> void:
	_detour_duration_remaining = DETOUR_DURATION


func update(delta: float) -> void:
	_detour_duration_remaining -= delta
	if _detour_duration_remaining <= 0:
		action.find_path_to_target()
		change_state("approach")
