class_name SimInput
extends MonsterInput

enum CursorAction {
	LMB_PRESS,
	RMB_PRESS,
	LMB_RELEASE,
	RMB_RELEASE,
	MOVE,
}

const CURSOR_POS_EPSILON: float = 1.0
const MOVEMENT_POS_EPSILON: float = 10.0

const LMB_PRESS: CursorAction = CursorAction.LMB_PRESS
const RMB_PRESS: CursorAction = CursorAction.RMB_PRESS
const LMB_RELEASE: CursorAction = CursorAction.LMB_RELEASE
const RMB_RELEASE: CursorAction = CursorAction.RMB_RELEASE
const MOVE: CursorAction = CursorAction.MOVE

var target_puzzle: NurikabeGameBoard

var cursor_commands: Array[CursorCommand] = []

@onready var monster: Monster = Utils.find_parent_of_type(self, Monster)

func update(delta: float) -> void:
	_process_cursor_command(delta)


func move_to(target: Vector2) -> void:
	var pos_diff: Vector2 = target - monster.position
	if pos_diff.length() > MOVEMENT_POS_EPSILON:
		dir = pos_diff.normalized()
	else:
		dir = Vector2.ZERO


func queue_cursor_command(action: CursorAction, pos: Vector2, delay: float = 0.0, speed: float = 1.0) -> CursorCommand:
	var command: CursorCommand = CursorCommand.new(action, pos, delay, speed)
	cursor_commands.append(command)
	return command


func has_cursor_command(command: CursorCommand) -> bool:
	return command in cursor_commands


func dequeue_cursor_command(command: CursorCommand) -> void:
	var command_index: int = cursor_commands.find(command)
	if command_index == -1:
		return
	
	cursor_commands.remove_at(command_index)
	if command_index == 0:
		if %PuzzleHandler.lmb_pressed:
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = false
			%PuzzleHandler.handle(event)
		if %PuzzleHandler.rmb_pressed:
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_RIGHT
			event.pressed = false
			%PuzzleHandler.handle(event)


func _process_cursor_command(delta: float) -> void:
	if cursor_commands.is_empty():
		return
	var cursor_command: CursorCommand = cursor_commands.front()
	cursor_command.delay -= delta
	if cursor_command.delay > 0:
		return
	
	%PuzzleHandler.game_board = monster.cursor_board
	var event: InputEvent
	if %Cursor.global_position.distance_to(cursor_command.pos) > CURSOR_POS_EPSILON:
		var lerp_pos: Vector2 = lerp(%Cursor.global_position, cursor_command.pos,
					1.0 - exp(-10.0 * cursor_command.speed * delta))
		var move_toward_pos: Vector2 = %Cursor.global_position.move_toward(cursor_command.pos,
					300 * cursor_command.speed * delta)
		if lerp_pos.distance_to(cursor_command.pos) < move_toward_pos.distance_to(cursor_command.pos):
			%Cursor.global_position = lerp_pos
		else:
			%Cursor.global_position = move_toward_pos
		
		event = InputEventMouseMotion.new()
		event.position = %Cursor.global_position
	else:
		match cursor_command.action:
			CursorAction.LMB_PRESS:
				event = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = true
			CursorAction.RMB_PRESS:
				event = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_RIGHT
				event.pressed = true
			CursorAction.LMB_RELEASE:
				event = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = false
			CursorAction.RMB_RELEASE:
				event = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_RIGHT
				event.pressed = false
		cursor_commands.pop_front()
	
	if event:
		%PuzzleHandler.handle(event)


class CursorCommand:
	var action: CursorAction
	var pos: Vector2
	var delay: float
	var speed: float = 1.0
	
	func _init(init_action: CursorAction, init_pos: Vector2, init_delay: float = 0.0, init_speed: float = 1.0) -> void:
		action = init_action
		pos = init_pos
		delay = init_delay
		speed = init_speed
