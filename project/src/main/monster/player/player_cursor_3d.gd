extends Cursor3D

func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * 200.0
	var mouse_hit: Dictionary[String, Variant] = raycast(ray_origin, ray_end)
	if mouse_hit:
		global_position = mouse_hit["position"]
