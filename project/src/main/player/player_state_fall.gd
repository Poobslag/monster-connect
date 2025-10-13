extends PlayerBaseState

func enter() -> void:
	play("fall")
	player.tween_elevation(0.0, Player.FALL_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func physics_update(delta: float) -> void:
	move(delta)
	
	if player.on_steppable:
		change_state("jump")
	elif player.elevation == 0.0:
		change_state("idle" if input.length() == 0 else "walk")
