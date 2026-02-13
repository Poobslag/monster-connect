extends CanvasLayer

signal next_level_button_pressed

func show_results() -> void:
	SoundManager.play_sfx("win")
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_results() -> void:
	hide()
	next_level_button_pressed.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_button_pressed() -> void:
	hide_results()
