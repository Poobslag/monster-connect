extends MonsterBaseState3D

func enter() -> void:
	play("jump")


func physics_update(delta: float) -> void:
	move(delta)
	
	change_state("idle" if input.length() == 0 else "walk")
