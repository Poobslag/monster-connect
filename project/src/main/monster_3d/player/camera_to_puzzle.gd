extends PlayerCameraState3D

var amount: float

var _tween: Tween
var _initial_position: Vector3
var _initial_offset: Vector3
var _final_position: Vector3
var _final_offset: Vector3

func enter() -> void:
	amount = 0.0
	_initial_position = camera.target_position
	_initial_offset = camera.target_offset
	_final_position = camera.get_puzzle_position()
	_final_offset = camera.get_puzzle_offset()
	_tween = create_tween()
	_tween.tween_property(self, "amount", 1.0, PlayerCamera3D.PAN_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func update(_delta: float) -> void:
	camera.target_position = lerp(_initial_position, _final_position, amount)
	camera.target_offset = lerp(_initial_offset, _final_offset, amount)
	if amount == 1.0:
		change_state("followpuzzle")


func exit() -> void:
	_tween = Utils.kill_tween(_tween)
