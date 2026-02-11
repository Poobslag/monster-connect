class_name MonsterSaver

const SIM_BEHAVIOR_VERSION = "0.01"

func load_sim_profile(filename: String) -> SimProfile:
	var profile: SimProfile = SimProfile.new()
	
	var current_section: String = ""
	
	var file: FileAccess = FileAccess.open(filename, FileAccess.READ)
	var header_line: String = file.get_line()
	var header: Dictionary = JSON.parse_string(header_line)
	profile.version = header.get("version", SIM_BEHAVIOR_VERSION)
	
	while not file.eof_reached():
		var line: String = file.get_line()
		
		if line.is_empty():
			continue
		
		if line.begins_with("[") and line.ends_with("]"):
			current_section = StringUtils.substring_between(line, "[", "]")
			continue
		
		match current_section:
			"metadata":
				_parse_metadata_line(line, profile)
			"archetypes":
				_parse_archetypes_line(line, profile)
			"stats":
				_parse_stats_line(line, profile)
	
	profile.apply_archetypes()
	return profile


func _parse_metadata_line(line: String, profile: SimProfile) -> void:
	var key: String = StringUtils.substring_before(line, " ")
	var value: String = StringUtils.substring_after(line, " ")
	match key:
		"author", "description", "name":
			profile.set(key, value)
		"skin":
			if SimMonster.MonsterSkin.has(value.to_upper()):
				profile.skin = SimMonster.MonsterSkin[value.to_upper()]
			else:
				push_warning("Unknown skin: %s" % [value])
		_:
			push_warning("Unknown metadata key: %s" % [key])


func _parse_archetypes_line(line: String, profile: SimProfile) -> void:
	var key: String = StringUtils.substring_before(line, " ")
	var value: String = StringUtils.substring_after(line, " ")
	match key:
		"rat", "pig":
			profile.archetypes[key] = float(value)
		_:
			push_warning("Unknown archetypes key: %s" % [key])


func _parse_stats_line(line: String, profile: SimProfile) -> void:
	var key: String = StringUtils.substring_before(line, " ")
	var value: String = StringUtils.substring_after(line, " ")
	profile.behavior.stats[key] = float(value)
