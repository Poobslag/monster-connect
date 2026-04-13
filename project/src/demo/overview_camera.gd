extends Camera3D

const ZOOM_FACTOR: float = 1.25

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1 / ZOOM_FACTOR)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(ZOOM_FACTOR)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			_pan(event.position - event.relative, event.position)


func _zoom(zoom_amount: float) -> void:
	var t: float = global_position.y / basis.z.y
	var xz_intersection: Vector3 = global_position - basis.z * t
	var old_distance: float = global_position.distance_to(xz_intersection)
	global_position = xz_intersection + basis.z * old_distance * zoom_amount


func _xz_plane_intersection(screen_pos: Vector2) -> Vector3:
	var origin: Vector3 = project_ray_origin(screen_pos)
	var normal: Vector3 = project_ray_normal(screen_pos)
	var t: float = origin.y / -normal.y
	return origin + normal * t


func _pan(old_screen_pos: Vector2, new_screen_pos: Vector2) -> void:
	var old_world: Vector3 = _xz_plane_intersection(old_screen_pos)
	var new_world: Vector3 = _xz_plane_intersection(new_screen_pos)
	global_position += old_world - new_world
