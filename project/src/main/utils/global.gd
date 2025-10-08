@tool
extends Node
## Globally accessible utilities.

## Game's main viewport size, as specified in the project settings.
var window_size: Vector2i = Vector2i(
	ProjectSettings.get_setting("display/window/size/viewport_width") as int,
	ProjectSettings.get_setting("display/window/size/viewport_height") as int)
