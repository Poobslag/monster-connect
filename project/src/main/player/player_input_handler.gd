class_name PlayerInputHandler
extends Node

var dir := Vector2.ZERO
var cursor_dir: Vector2

var _last_mouse_motion_position: Vector2

func update() -> void:
	dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_last_mouse_motion_position = event.global_position
		cursor_dir = _last_mouse_motion_position - get_parent().global_position


func _process(_delta: float) -> void:
	cursor_dir = _last_mouse_motion_position - get_parent().global_position
