class_name PlayerInputHandler
extends Node

enum InputMethod {
	NONE,
	MOUSE,
	KEYBOARD,
}

const CURSOR_RADIUS: float = 256
const CHARACTER_CENTER := Vector2(0, -60)
const MOUSE_STOP_DISTANCE: float = 20.0

var dir := Vector2.ZERO

var _last_input_method: InputMethod = InputMethod.NONE
var _mouse_target: Vector2
var _mouse_dir: Vector2

@onready var player: Player = get_parent()

func update() -> void:
	if _last_input_method == InputMethod.MOUSE:
		var new_dir: Vector2 = (_mouse_target - player.position).normalized()
		if new_dir.dot(_mouse_dir) < 0.9 or _mouse_target.distance_to(player.position) < MOUSE_STOP_DISTANCE:
			reset()
		else:
			dir = new_dir
	else:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")


func reset() -> void:
	dir = Vector2.ZERO
	_mouse_target = Vector2.ZERO
	_mouse_dir = Vector2.ZERO
	_last_input_method = InputMethod.NONE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left") \
			or event.is_action_pressed("move_right") \
			or event.is_action_pressed("move_up") \
			or event.is_action_pressed("move_down"):
		_last_input_method = InputMethod.KEYBOARD
	if event is InputEventMouseButton \
			or event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_last_input_method = InputMethod.MOUSE
		_mouse_target = player.position + (event.global_position - player.global_position)
		_mouse_dir = (_mouse_target - player.position).normalized()
