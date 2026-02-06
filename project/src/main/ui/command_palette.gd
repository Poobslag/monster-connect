class_name CommandPalette
extends CanvasLayer

signal command_entered(command: String)

func _ready() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if not has_focus():
		return
	
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


static func find_instance(node: Node) -> CommandPalette:
	return node.get_tree().get_first_node_in_group("command_palettes")
