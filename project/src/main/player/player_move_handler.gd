class_name PlayerMoveHandler
extends Node

enum InputMethod {
	NONE,
	MOUSE,
	KEYBOARD,
}

const MOUSE_STOP_DISTANCE: float = 20.0

const PUZZLE_APPROACH_TOP := 40.0
const PUZZLE_APPROACH_RIGHT := 80.0
const PUZZLE_APPROACH_BOTTOM := 160.0
const PUZZLE_APPROACH_LEFT := 80.0

var dir := Vector2.ZERO

var _last_input_method: InputMethod = InputMethod.NONE
var _mouse_target: Vector2
var _mouse_dir: Vector2

@onready var player: Player = Utils.find_parent_of_type(self, Player)

func handle(event: InputEvent) -> void:
	# wasd
	if event.is_action_pressed("move_left") \
			or event.is_action_pressed("move_right") \
			or event.is_action_pressed("move_up") \
			or event.is_action_pressed("move_down"):
		_last_input_method = InputMethod.KEYBOARD
	
	# pressing/dragging the left mouse button, not on a puzzle
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed \
			or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		_last_input_method = InputMethod.MOUSE
		var target_player_position: Vector2
		if player.current_game_board == null:
			target_player_position = player.to_local(
						get_viewport().get_camera_2d().get_global_mouse_position())
		
		_mouse_target = player.position + target_player_position
		_mouse_dir = (_mouse_target - player.position).normalized()


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


static func dist_to_rect(rect: Rect2, point: Vector2) -> float:
	var result: float
	if rect.has_point(point):
		result = min(
			abs(point.x - rect.position.x),
			abs(point.y - rect.position.y),
			abs(point.x - rect.end.x),
			abs(point.y - rect.end.y),
		)
	else:
		result = point.clamp(rect.position, rect.end).distance_to(point)
	return result


static func nearest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var result: Vector2
	if rect.has_point(point):
		var smallest_distance: float = INF
		for candidate_point: Vector2 in [
				Vector2(rect.position.x, point.y),
				Vector2(point.x, rect.position.y),
				Vector2(rect.end.x, point.y),
				Vector2(point.x, rect.end.y)]:
			var distance: float = point.distance_to(candidate_point)
			if distance < smallest_distance:
				smallest_distance = distance
				result = candidate_point
	else:
		result = point.clamp(rect.position, rect.end)
	return result
