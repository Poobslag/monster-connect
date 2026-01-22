class_name LeavePuzzleAction
extends GoapAction

func perform(actor: Variant, _delta: float) -> bool:
	actor.game_board = null
	return false
