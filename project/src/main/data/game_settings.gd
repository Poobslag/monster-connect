extends Node
## Stores game settings.

## If 'true', the player has pending settings changes which need to be saved
var has_unsaved_changes := false

## We store the non-fullscreened window size so we can restore it when the player disables fullscreen mode.
var _prev_window_size: Vector2i = Global.window_size
var _prev_window_position: Vector2i = DisplayServer.window_get_position()

var full_screen: bool = false:
	set(value):
		if full_screen == value:
			return
		full_screen = value
		_refresh_full_screen()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if event.is_action_pressed("full_screen"):
		full_screen = !full_screen
		has_unsaved_changes = true
		SettingsSaver.save_settings()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


## Resets all settings to default values.
func reset() -> void:
	from_json_dict({})


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	full_screen = json.get("full_screen", false)


func to_json_dict() -> Dictionary[String, Variant]:
	return {
		"full_screen": full_screen,
	}


## Updates the display server's maximized/borderless flags based on the game settings.
func _refresh_full_screen() -> void:
	var old_maximized: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var new_maximized: bool = full_screen
	
	if not old_maximized and new_maximized:
		# Becoming maximized. Store the old window size and position.
		_prev_window_size = DisplayServer.window_get_size()
		_prev_window_position = DisplayServer.window_get_position()
	
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if new_maximized else DisplayServer.WINDOW_MODE_WINDOWED)
	
	if old_maximized and not new_maximized:
		# Becoming unmaximized. Restore the old window size and position.
		DisplayServer.window_set_size(_prev_window_size)
		DisplayServer.window_set_position(_prev_window_position)
