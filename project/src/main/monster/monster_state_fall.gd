extends MonsterBaseState

func enter() -> void:
	play("fall")
	monster.tween_elevation(0.0, Monster.FALL_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func physics_update(delta: float) -> void:
	move(delta)
	
	if monster.on_steppable:
		change_state("jump")
	elif monster.elevation == 0.0:
		change_state("idle" if input.length() == 0 else "walk")
