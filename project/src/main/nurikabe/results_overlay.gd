extends CanvasLayer

signal next_level_button_pressed

func show_results() -> void:
	show()


func _on_button_pressed() -> void:
	hide()
	next_level_button_pressed.emit()
