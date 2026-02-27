extends PlayerCameraState

func enter() -> void:
	camera.zoom = PlayerCamera.ZOOM_DEFAULT


func update(_delta: float) -> void:
	camera.global_position = player.global_position
