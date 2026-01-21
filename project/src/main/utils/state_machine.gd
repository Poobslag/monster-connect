@tool
class_name StateMachine
extends Node
## Implementation of the finite state machine pattern.
##
## State nodes can be added to this node as children. This class provides logic for switching between its child states,
## invoking their methods, and emitting signals.

## Mapping from lowercase state names to [State] nodes.
var states: Dictionary[String, State] = {}

## Name of the currently active state.
var current_state: String

## The currently active [State] node.
var current_state_node: State

## Name of the previously active state.
var previous_state: String

func _ready() -> void:
	_refresh_states()


func _refresh_states() -> void:
	var object: Node = get_parent()
	states.clear()
	for child: Node in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			if "state_machine" in child:
				child.state_machine = self
			if "object" in child:
				child.object = object


## Called every frame to update the active state.
func update(delta: float) -> void:
	if not current_state:
		return
	
	current_state_node.update(delta)


## Called every physics tick to update the active state.
func physics_update(delta: float) -> void:
	if not current_state:
		return
	
	current_state_node.physics_update(delta)


## Transitions to [param next_state].
func change_state(next_state: String) -> void:
	if current_state:
		current_state_node.exit()
	
	previous_state = current_state
	current_state = next_state
	if Engine.is_editor_hint() and not states.has(next_state):
		_refresh_states()
	current_state_node = states[next_state]
	current_state_node.enter()


func has_state(state: String) -> bool:
	return states.has(state)
