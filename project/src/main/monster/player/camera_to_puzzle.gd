extends PlayerCameraState

var amount: float

var _tween: Tween
var _initial_position: Vector2
var _initial_zoom: Vector2
var _final_zoom: Vector2

func enter() -> void:
	amount = 0.0
	_initial_position = camera.global_position
	_initial_zoom = camera.zoom
	_tween = create_tween()
	_tween.tween_property(self, "amount", 1.0, PlayerCamera.PAN_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_final_zoom = camera.get_puzzle_zoom()


func update(_delta: float) -> void:
	var final_position: Vector2 = player.solving_board.get_global_cursorable_rect().get_center()
	camera.global_position = lerp(_initial_position, final_position, amount)
	camera.zoom = lerp(_initial_zoom, _final_zoom, amount)
	if amount == 1.0:
		change_state("followpuzzle")


func exit() -> void:
	_tween = Utils.kill_tween(_tween)
