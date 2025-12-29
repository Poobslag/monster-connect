extends CanvasLayer

signal command_entered(command: String)

func _ready() -> void:
	hide()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_ENTER:
			command_entered.emit(%LineEdit.text)
			close()
		KEY_ESCAPE:
			close()


func open() -> void:
	show()
	%LineEdit.clear()
	%LineEdit.grab_focus()


func close() -> void:
	hide()


func has_focus() -> bool:
	return %LineEdit.has_focus()
