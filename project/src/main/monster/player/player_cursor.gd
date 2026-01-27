@tool
class_name PlayerCursor
extends MonsterCursor

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	update_position()


func update_position() -> void:
	global_position = get_viewport().get_camera_2d().get_global_mouse_position()
