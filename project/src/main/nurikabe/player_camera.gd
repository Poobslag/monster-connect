class_name PlayerCamera
extends Camera2D

const PAN_DURATION: float = 0.6
const ZOOM_DEFAULT: Vector2 = Vector2(1.2, 1.2)

@export var player: PlayerMonster

func _ready() -> void:
	%StateMachine.change_state("toplayer")
	player.solving_board_changed.connect(func() -> void:
		var new_state: String = "toplayer" if player.solving_board == null else "topuzzle"
		%StateMachine.change_state(new_state))


func _process(delta: float) -> void:
	%StateMachine.update(delta)


func get_puzzle_zoom() -> Vector2:
	var puzzle_size: Vector2 = player.solving_board.get_global_cursorable_rect().size
	var viewport_size: Vector2 = get_viewport_rect().size
	
	var zoom_factor: Vector2 = 0.8 * (viewport_size / puzzle_size)
	zoom_factor = zoom_factor.min(ZOOM_DEFAULT)
	zoom_factor.x = min(zoom_factor.x, zoom_factor.y)
	zoom_factor.y = zoom_factor.x
	
	return zoom_factor
