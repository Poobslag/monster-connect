extends CanvasLayer

signal next_level_button_pressed

@export var show_mouse_while_visible: bool = true

func show_results() -> void:
	SoundManager.play_sfx("win")
	show()
	if show_mouse_while_visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_results() -> void:
	hide()
	next_level_button_pressed.emit()
	if show_mouse_while_visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_button_pressed() -> void:
	hide_results()
