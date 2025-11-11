extends CanvasLayer

signal next_level_button_pressed

func _show_results() -> void:
	show()


func _on_button_pressed() -> void:
	hide()
	next_level_button_pressed.emit()


func _on_game_board_puzzle_finished() -> void:
	SoundManager.play_sfx("win")
	_show_results()
