extends MonsterBaseState3D

var _end_time: float

func enter() -> void:
	play("jump")
	_end_time = Time.get_ticks_usec() + Monster3D.JUMP_DURATION * 1000000


func physics_update(delta: float) -> void:
	move(delta)
	
	if not monster.is_on_floor():
		change_state("fall")
	elif Time.get_ticks_usec() > _end_time:
		change_state("idle" if input.length() == 0 else "walk")
