extends PlayerCameraState

func enter() -> void:
	camera.zoom = camera.get_puzzle_zoom()


func update(_delta: float) -> void:
	camera.global_position = player.solving_board.get_global_cursorable_rect().get_center()
