class_name GoapGoalAction
extends GoapAction

var _goal: GoapGoal

func _init(init_goal: GoapGoal) -> void:
	_goal = init_goal

func is_valid() -> bool:
	return _goal.is_valid()
