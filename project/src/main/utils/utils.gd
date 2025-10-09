@tool
class_name Utils
## Contains global utilities.


## Invalidates a tween if it is already active.[br]
## [br]
## Killing a tween requires a null check, but this makes it a one-liner.
static func kill_tween(tween: Tween) -> Tween:
	if tween:
		tween.kill()
	return null


## Creates/recreates a tween, invalidating it if it is already active.[br]
## [br]
## Tweens should be created and discarded, but tweening the same property with multiple tweens causes unpredictable
## behavior. This ensures only one tween modifies a given property at a time.[br]
## [br]
## The new tween is bound to [param node] and respects its lifecycle (e.g., pausing when the game is paused.)
static func recreate_tween(node: Node, tween: Tween) -> Tween:
	kill_tween(tween)
	return node.create_tween()
