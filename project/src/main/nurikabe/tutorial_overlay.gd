extends CanvasLayer

func _ready() -> void:
	if visible:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func show_tutorial() -> void:
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_tutorial() -> void:
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_button_pressed() -> void:
	hide_tutorial()
