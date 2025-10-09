class_name State
extends Node
## Base class for states used by [StateMachine].

## The object this state is controlling.
var object: Variant

## Reference to the parent [StateMachine].
var state_machine: StateMachine

## Called when the state is entered.
func enter() -> void:
	pass


## Called every frame to update the active state.
func update(_delta: float) -> void:
	pass


## Called every physics tick to update the active state.
func physics_update(_delta: float) -> void:
	pass


## Called when the state is exited.
func exit() -> void:
	pass


## Transitions the state machine to [param next_state].
func change_state(next_state: String) -> void:
	state_machine.change_state(next_state)
