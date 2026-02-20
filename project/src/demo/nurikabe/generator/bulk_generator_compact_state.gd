extends State

var _puzzle_data: Array[Dictionary] = []
var _puzzle_num: int = 1
var _delete_count: int = 0
var _move_count: int = 0
var queue_1: Array[String] = []
var queue_2: Array[String] = []
var queue_3: Array[String] = []

func enter() -> void:
	_puzzle_data.clear()
	_puzzle_num = 1
	_delete_count = 0
	_move_count = 0
	queue_1 = Utils.find_data_files(BulkGenerator.PUZZLE_DIR, "txt")
	queue_2.clear()
	queue_3.clear()


func update(_delta: float) -> void:
	if not queue_1.is_empty():
		# Phase 1: load puzzle data and select oldest 25% for deletion
		var puzzle_path: String = queue_1.pop_front()
		var info_path: String = NurikabeUtils.get_puzzle_info_path(puzzle_path)
		var puzzle_info: PuzzleInfo = PuzzleInfoSaver.new().load_puzzle_info(info_path)
		_puzzle_data.append({
			"path": puzzle_path,
			"author": puzzle_info.author,
		} as Dictionary[String, Variant])
		if queue_1.is_empty():
			_puzzle_data.shuffle()
			_puzzle_data.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
				return a["author"] < b["author"])
			@warning_ignore("integer_division")
			var delete_count: int = ceili(_puzzle_data.size() / 4.0)
			for i in delete_count:
				queue_2.append(_puzzle_data[i]["path"])
			object.log_message("Analyzed %s puzzles." % [_puzzle_data.size()])
	elif not queue_2.is_empty():
		# Phase 2: Delete selected puzzles
		var puzzle_path: String = queue_2.pop_front()
		DirAccess.remove_absolute(puzzle_path)
		DirAccess.remove_absolute(NurikabeUtils.get_puzzle_info_path(puzzle_path))
		_delete_count += 1
		if queue_2.is_empty():
			object.log_message("Deleted %s puzzles." % [_delete_count])
			queue_3 = Utils.find_data_files(BulkGenerator.PUZZLE_DIR, "txt")
			queue_3.sort()
			_puzzle_num = 1
	elif not queue_3.is_empty():
		# Phase 3: Renumber remaining puzzles sequentially
		var old_puzzle_path: String = queue_3.pop_front()
		var old_info_path: String = NurikabeUtils.get_puzzle_info_path(old_puzzle_path)
		var new_puzzle_path: String = NurikabeUtils.get_user_puzzle_path(_puzzle_num)
		var new_info_path: String = NurikabeUtils.get_puzzle_info_path(new_puzzle_path)
		if old_puzzle_path != new_puzzle_path:
			var error: Error = Error.OK
			if error == Error.OK:
				error = DirAccess.copy_absolute(old_puzzle_path, new_puzzle_path)
			if error == Error.OK:
				error = DirAccess.copy_absolute(old_info_path, new_info_path)
			if error == Error.OK:
				error = DirAccess.remove_absolute(old_puzzle_path)
			if error == Error.OK:
				error = DirAccess.remove_absolute(old_info_path)
			if error == Error.OK:
				_puzzle_num += 1
				_move_count += 1
			else:
				object.log_message("Error moving %s to %s." \
						% [old_puzzle_path.get_basename(), new_puzzle_path.get_basename()])
				change_state("idle")
				return
	else:
		# Clean up and exit.
		object.log_message("Moved %s puzzles." % [_move_count])
		object.log_message("Compact complete.")
		change_state("idle")
