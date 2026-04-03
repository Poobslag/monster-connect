extends Camera3D

@export var lerp_speed: float = 3.0
@export var target: Node3D
@export var offset: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if !target:
		return
	
	position = lerp(position, target.position + offset, lerp_speed * delta)
