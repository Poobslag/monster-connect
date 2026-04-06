extends Camera3D

@export var lerp_speed: float = 3.0
@export var target: Node3D
@export var offset: Vector3 = Vector3.ZERO

@export var drift_amount: float = 0.0
@export var drift_duration: float = 15.0

func _physics_process(delta: float) -> void:
	if !target:
		return
	
	position = lerp(position, target.position + offset, lerp_speed * delta)
	
	# Sway the camera to prevent horizontal banding (issue #371)
	var sway_cycle: float = Time.get_ticks_usec() / 1000000.0 / drift_duration
	rotation = Vector3(
			deg_to_rad(-60 + drift_amount * cos(sway_cycle)),
			deg_to_rad(0 + drift_amount * sin(sway_cycle)),
			0)
