extends PlayerBaseState

func enter() -> void:
	play("idle")


func physics_update(delta: float) -> void:
	move(delta)
	
	if player.on_steppable and player.elevation == 0:
		change_state("jump")
	elif not player.on_steppable and player.elevation > 0:
		change_state("fall")
	elif input.length() != 0:
		change_state("walk")
