class_name GoapAgent
extends Node
## This script integrates the actor (NPC) with goap.[br]
## [br]
## The actor needs two fields:
## 	[code]var world_state: Dictionary[String, int][/code]
## 	[code]var action_planner: GoapActionPlanner[/code]

var _goals: Array[GoapGoal]
var _current_goal: GoapGoal
var _current_plan: Array[GoapAction]
var _current_plan_step: int = 0

var _actor: Variant

func _init(init_actor: Variant, init_goals: Array[GoapGoal]) -> void:
	_actor = init_actor
	_goals = init_goals


## On every loop this script checks if the current goal is still
## the highest priority. if it's not, it requests the action planner a new plan
## for the new high priority goal.
func _process(delta: float) -> void:
	var goal: GoapGoal = _get_best_goal()
	if _current_goal == null or goal != _current_goal:
		var blackboard: Dictionary[String, int] = _actor.world_state.duplicate()
		
		_current_goal = goal
		_current_plan = _actor.action_planner.get_plan(_current_goal, blackboard)
		_current_plan_step = 0
	else:
		_follow_plan(_current_plan, delta)


## Returns the highest priority goal available.
func _get_best_goal() -> GoapGoal:
	var highest_priority: GoapGoal = null
	
	for goal: GoapGoal in _goals:
		if goal.is_valid() and (highest_priority == null or goal.priority() > highest_priority.priority()):
			highest_priority = goal
	
	return highest_priority


## Executes plan. This function is called on every game loop.
## "plan" is the current list of actions, and delta is the time since last loop.[br]
## [br]
## Every action exposes a function called perform, which will return true when
## the job is complete, so the agent can jump to the next action in the list.
func _follow_plan(plan: Array[GoapAction], delta: float) -> void:
	if plan.is_empty():
		return
	
	var is_step_complete: bool = plan[_current_plan_step].perform(_actor, delta)
	if is_step_complete and _current_plan_step < plan.size() - 1:
		_current_plan_step += 1
