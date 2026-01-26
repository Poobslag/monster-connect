extends Node
class_name GoapAction

func enter(_actor: Variant) -> void:
	pass


func exit(_actor: Variant) -> void:
	pass


## Action implementation called on every loop.[br]
## [br]
## [param _actor] is the NPC using the AI. [param _delta] is the time in seconds since last loop. Returns true when
## the task is complete.[br]
func perform(_actor: Variant, _delta: float) -> bool:
	return false
