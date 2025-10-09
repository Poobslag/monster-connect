extends PlayerBaseState

func enter() -> void:
	play("idle")


func physics_update(delta: float) -> void:
	move(delta)
	
	if input.length() != 0:
		change_state("walk")
