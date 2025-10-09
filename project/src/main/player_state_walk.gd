extends PlayerBaseState

func enter() -> void:
	play("walk")


func physics_update(delta: float) -> void:
	move(delta)
	
	if input.length() == 0:
		change_state("idle")
