extends MonsterBaseState3D

var _end_time: float

func enter() -> void:
	play("fall")
	_end_time = Time.get_ticks_usec() + Monster.FALL_DURATION * 1000000


func physics_update(delta: float) -> void:
	move(delta)
	
	if position_delta.y > JUMP_THRESHOLD:
		change_state("jump")
	elif monster.is_on_floor() and Time.get_ticks_usec() > _end_time:
		change_state("idle" if input.length() == 0 else "walk")
