extends MonsterBaseState

func enter() -> void:
	play("idle")


func physics_update(delta: float) -> void:
	move(delta)
	
	if monster.on_steppable and monster.elevation == 0:
		change_state("jump")
	elif not monster.on_steppable and monster.elevation > 0:
		change_state("fall")
	elif input.length() != 0:
		change_state("walk")
