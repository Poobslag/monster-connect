extends PlayerBaseState

func enter() -> void:
	play("jump")
	player.tween_elevation(Player.ELEVATION_PER_Z_INDEX, Player.JUMP_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func physics_update(delta: float) -> void:
	move(delta)
	
	if not player.on_steppable:
		change_state("fall")
	elif player.elevation == Player.ELEVATION_PER_Z_INDEX:
		change_state("idle" if input.length() == 0 else "walk")
