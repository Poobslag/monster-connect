extends MonsterBaseState

func enter() -> void:
	play("jump")
	monster.tween_elevation(Monster.ELEVATION_PER_Z_INDEX, Monster.JUMP_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func physics_update(delta: float) -> void:
	move(delta)
	
	if not monster.on_steppable:
		change_state("fall")
	elif monster.elevation == Monster.ELEVATION_PER_Z_INDEX:
		change_state("idle" if input.length() == 0 else "walk")
