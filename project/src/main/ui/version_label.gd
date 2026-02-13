extends Label
## Version label shown in the corner of the screen.

func _ready() -> void:
	text = "v%s" % [ProjectSettings.get_setting("application/config/version", "?.??")]
