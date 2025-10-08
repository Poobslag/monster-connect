class_name SettingsUpgrader
extends SaveDataUpgrader
## Provides backwards compatibility with old settings files.

func _init() -> void:
	current_version = "0000"
