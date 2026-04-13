class_name PuzzleInfoSaver

const PUZZLE_INFO_VERSION: String = "0.02"

func save_puzzle_info(filename: String, info: PuzzleInfo) -> void:
	var file: FileAccess = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": PUZZLE_INFO_VERSION}) + "\n")
	file.store_string("\n")
	file.store_string("[metadata]\n")
	file.store_string("difficulty %0.2f\n" % [info.difficulty])
	file.store_string("width %s\n" % [info.size.x])
	file.store_string("height %s\n" % [info.size.y])
	file.store_string("author %s\n" % [info.author])
	file.store_string("\n")
	file.store_string("[solution]\n")
	file.store_string(info.solution_string + "\n")
	file.store_string("\n")
	file.store_string("[order]\n")
	file.store_string(info.order_string + "\n")
	file.store_string("\n")
	file.store_string("[reason]\n")
	file.store_string(info.reason_string + "\n")


func load_puzzle_info(filename: String) -> PuzzleInfo:
	var info: PuzzleInfo = PuzzleInfo.new()
	var current_section: String = ""
	
	var file: FileAccess = FileAccess.open(filename, FileAccess.READ)
	var header_line: String = file.get_line()
	var header: Dictionary = JSON.parse_string(header_line)
	info.version = header.get("version", PUZZLE_INFO_VERSION)
	
	while not file.eof_reached():
		var line: String = file.get_line()
		
		if line.is_empty():
			continue
		
		if line.begins_with("[") and line.ends_with("]"):
			current_section = StringUtils.substring_between(line, "[", "]")
			continue
		
		match current_section:
			"metadata":
				_parse_metadata_line(line, info)
			"solution":
				if not info.solution_string.is_empty():
					info.solution_string += "\n"
				info.solution_string += line
			"order":
				if not info.order_string.is_empty():
					info.order_string += "\n"
				info.order_string += line
			"reason":
				if not info.reason_string.is_empty():
					info.reason_string += "\n"
				info.reason_string += line
			"":
				pass
			_:
				push_warning("Unknown section: %s" % [current_section])
	
	return info


func _parse_metadata_line(line: String, info: PuzzleInfo) -> void:
	var key: String = StringUtils.substring_before(line, " ")
	var value: String = StringUtils.substring_after(line, " ")
	match key:
		"difficulty":
			info.difficulty = float(value)
		"width":
			info.size.x = int(value)
		"height":
			info.size.y = int(value)
		"author":
			info.author = value
		_:
			push_warning("Unknown metadata key: %s" % [key])
