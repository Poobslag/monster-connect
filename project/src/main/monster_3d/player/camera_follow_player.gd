extends PlayerCameraState3D

func enter() -> void:
	camera.target_offset = camera.player_offset


func update(_delta: float) -> void:
	camera.target_position = player.global_position
