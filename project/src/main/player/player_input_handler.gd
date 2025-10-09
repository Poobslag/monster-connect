class_name PlayerInputHandler
extends Node

const CURSOR_RADIUS: float = 256
const CHARACTER_CENTER := Vector2(0, -60)

var dir := Vector2.ZERO
var cursor_dir: Vector2 = CHARACTER_CENTER

var _last_mouse_motion_position: Vector2

func update() -> void:
	dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_last_mouse_motion_position = event.relative
		cursor_dir += event.relative
		
		if %Cursor.ghost:
			if (cursor_dir - CHARACTER_CENTER).length() > CURSOR_RADIUS:
				var old_cursor_dir: Vector2 = cursor_dir
				cursor_dir = (cursor_dir - CHARACTER_CENTER).limit_length(CURSOR_RADIUS) + CHARACTER_CENTER
				dir = (old_cursor_dir - cursor_dir).normalized()
				get_parent().position += (old_cursor_dir - cursor_dir)
		else:
			cursor_dir = (cursor_dir - CHARACTER_CENTER).limit_length(CURSOR_RADIUS) + CHARACTER_CENTER
