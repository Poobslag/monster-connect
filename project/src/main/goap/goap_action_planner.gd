class_name GoapActionPlanner
extends Node
## Planner. Goap's heart.

var _actions: Array[GoapAction]

## Set actions available for planning.[br]
## [br]
## This can be changed at runtime for more dynamic options.
func set_actions(new_actions: Array[GoapAction]) -> void:
	_actions = new_actions


## Receives a Goal and an optional blackboard.[br]
## [br]
## Returns a list of actions to be executed.
func get_plan(goal: GoapGoal, blackboard: Dictionary[String, int] = {}) -> Array[GoapAction]:
	var desired_state: Dictionary[String, Variant] = goal.get_desired_state().duplicate()
	if desired_state.is_empty():
		return []

	# goal is set as root action.
	var root_node: Dictionary[String, Variant] = {
		"action": GoapGoalAction.new(goal),
		"state": desired_state,
		"children": [] as Array[Dictionary]
	}
	
	# build plans populates root with children, returning false it doesn't find a valid path
	if not _build_plans(root_node, blackboard.duplicate()):
		return []
	
	var plan_nodes: Array[Dictionary] = _transform_tree_into_array(root_node, blackboard)
	return _get_cheapest_plan(plan_nodes)


## Compares plan's cost and returns actions included in the cheapest one.
func _get_cheapest_plan(plan_nodes: Array[Dictionary]) -> Array[GoapAction]:
	var best_plan: Dictionary[String, Variant]
	for plan_node: Dictionary[String, Variant] in plan_nodes:
		if best_plan == null or plan_node.cost < best_plan.cost:
			best_plan = plan_node
	return best_plan.actions


## Builds graph with actions. Only includes valid plans (plans that achieve the goal).[br]
## [br]
## Returns true if the path has a solution.[br]
## [br]
## This function uses recursion to build the graph. This is necessary because any new action included in the graph
## may add pre-conditions to the desired state that can be satisfied by previously considered actions, meaning, on
## every step we need to iterate from the beginning to find all solutions.[br]
## [br]
## The current implementation is not protected from circular dependencies.
func _build_plans(step: Dictionary[String, Variant], blackboard: Dictionary[String, int]) -> bool:
	var has_followup: bool = false
	
	# each node in the graph has it's own desired state.
	var state: Dictionary[String, Variant] = step.state.duplicate()
	
	# checks if the blackboard contains data that can satisfy the current state.
	for s: String in step.state:
		var goap_effect: GoapEffect = step.state[s]
		var blackboard_value: Variant = blackboard[s]
		var effect_meets_condition: bool = false
		#if blackboard_value is GoapCondition:
			#var goap_condition: GoapCondition = blackboard_value
			#if goap_effect.effect_delta > 0:
				#effect_meets_condition = goap_condition.comparison in [GoapCondition.GreaterThan, GoapCondition.GreaterThanOrEqual]
			#elif goap_effect.effect_delta < 0:
				#effect_meets_condition = goap_condition.comparison in [GoapCondition.LessThan, GoapCondition.LessThanOrEqual]
		#elif blackboard_value is int:
			#var blackboard_int: int = blackboard_value
			#effect_meets_condition = goap_condition.comparison in [GoapCondition.GreaterThan, GoapCondition.GreaterThanOrEqual]
		if effect_meets_condition:
			state.erase(s)
	
	# if the state is empty, it means this branch already found the solution, so it doesn't need to
	# look for more actions
	if state.is_empty():
		return true
	
	for action: GoapAction in _actions:
		if not action.is_valid():
			continue
		
		var should_use_action: bool = false
		var effects: Dictionary[String, Variant] = action.get_effects()
		var desired_state: Dictionary[String, Variant] = state.duplicate()
		
		# check if action should be used, i.e. it satisfies at least one condition from the desired
		# state
		for s: String in desired_state:
			if desired_state[s] == effects.get(s):
				desired_state.erase(s)
				should_use_action = true
		
		if should_use_action:
			# adds actions pre-conditions to the desired state
			var preconditions: Dictionary[String, GoapCondition] = action.get_preconditions()
			for p: String in preconditions:
				desired_state[p] = preconditions[p]
		
			var s: Dictionary[String, Variant] = {
					"action": action,
					"state": desired_state,
					"children": [] as Array[Dictionary]
				}
			
			# if desired state is empty, it means this action can be included in the graph.
			# if it's not empty, _build_plans is called again (recursively) so it can try to find
			# actions to satisfy this current state. In case it can't find anything, this action
			# won't be included in the graph.
			if desired_state.is_empty() or _build_plans(s, blackboard.duplicate()):
				step.children.push_back(s)
				has_followup = true
	
	return has_followup


## Transforms graph with actions into list of actions and calculates
## the cost by summing actions' cost.[br]
## [br]
## Returns list of plans.
func _transform_tree_into_array(
		p: Dictionary[String, Variant],
		blackboard: Dictionary[String, Variant]) -> Array[Dictionary]:
	var plans: Array[Dictionary] = []
	
	if p.children.is_empty():
		plans.push_back({
				"actions": [p.action],
				"cost": p.action.get_cost(blackboard)
			} as Dictionary[String, Variant])
		return plans
	
	for c: Dictionary[String, Variant] in p.children:
		for child_plan: Dictionary in _transform_tree_into_array(c, blackboard):
			if p.action.has_method("get_cost"):
				child_plan.actions.push_back(p.action)
				child_plan.cost += p.action.get_cost(blackboard)
			plans.push_back(child_plan)
	return plans
