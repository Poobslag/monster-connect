extends MonsterBaseState3D

func enter() -> void:
	play("walk")


func physics_update(delta: float) -> void:
	move(delta)
	
	if position_delta.y > JUMP_THRESHOLD:
		change_state("jump")
	elif not monster.is_on_floor():
		change_state("fall")
	elif input.length() == 0:
		change_state("idle")
