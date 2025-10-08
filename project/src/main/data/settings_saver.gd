extends Node
## Reads and writes player settings to disk.

const SETTINGS_VERSION := "0000"

var settings_path := "user://settings.json"

## Provides backwards compatibility with old settings files.
var _upgrader := SettingsUpgrader.new()

func _ready() -> void:
	load_settings()


## Writes the current settings to disk.
func save_settings() -> void:
	var save_json: Dictionary[String, Variant] = GameSettings.to_json_dict()
	save_json["version"] = SETTINGS_VERSION
	_write_json(settings_path, save_json)
	GameSettings.has_unsaved_changes = false


## Loads settings from disk.
func load_settings() -> void:
	if not FileAccess.file_exists(settings_path):
		return
	var save_json: Dictionary[String, Variant] = _read_json(settings_path)
	if _upgrader.needs_upgrade(save_json):
		_upgrader.upgrade(save_json)
	GameSettings.from_json_dict(save_json)


## Writes json text to disk.
func _write_json(path: String, json: Dictionary[String, Variant]) -> void:
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(json, "  "))


## Reads json text from disk.
func _read_json(path: String) -> Dictionary[String, Variant]:
	var save_text: String = FileAccess.get_file_as_string(path)
	var test_json_conv := JSON.new()
	test_json_conv.parse(save_text)
	var save_json: Dictionary[String, Variant] = {}
	save_json.assign(test_json_conv.get_data())
	return save_json
