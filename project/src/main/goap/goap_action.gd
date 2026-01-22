extends Node
class_name GoapAction
## Action contract.

## This indicates if the action should be considered or not.[br]
## [br]
## This can be used during planning, or during execution to abort the plan in case the world state does not allow
## this action anymore.
func is_valid() -> bool:
	return true


## Action cost. This is a function so it handles situational costs, when the world state is considered when
## calculating the cost.
func get_cost(_blackboard: Dictionary[String, Variant]) -> int:
	return 0


## Action requirements.[br]
## [br]
## Example:
## [codeblock]
## {
##   "wood": Goap.at_least(1)
## }
## [/codeblock]
func get_preconditions() -> Dictionary[String, GoapCondition]:
	return {}


## What conditions this action satisfies, expressed as integer deltas.[br]
## [br]
## Example:
## [codeblock]
## {
##   "wood": 5
## }
## [/codeblock]
func get_effects() -> Dictionary[String, int]:
	return {}


## Action implementation called on every loop.[br]
## [br]
## [param _actor] is the NPC using the AI. [param _delta] is the time in seconds since last loop. Returns true when
## the task is complete.[br]
func perform(_actor: Variant, _delta: float) -> bool:
	return false
