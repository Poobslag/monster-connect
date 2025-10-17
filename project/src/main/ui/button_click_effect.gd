extends Node
## Plays a click sound when a button is pressed.

func _ready() -> void:
	var parent_button: BaseButton = get_parent()
	parent_button.pressed.connect(func() -> void:
		SoundManager.play_sfx("button_click"))
