extends Node
class_name GoapAction

func enter() -> void:
	pass


func exit() -> void:
	pass


## Action implementation called on every loop.[br]
## [br]
## [param _actor] is the NPC using the AI. [param _delta] is the time in seconds since last loop. Returns true when
## the task is complete.[br]
func perform(_delta: float) -> bool:
	return false
