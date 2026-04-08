extends Cursor3D

func _process(_delta: float) -> void:
	var ray_origin: Vector3 = Vector3(global_position.x, 100, global_position.z)
	var ray_end: Vector3 = Vector3(global_position.x, -1, global_position.z)
	raycast(ray_origin, ray_end)
