extends PlayerCameraState3D

func enter() -> void:
	camera.target_offset = camera.get_puzzle_offset()


func update(_delta: float) -> void:
	camera.target_position = camera.get_puzzle_position()
