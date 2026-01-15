extends State

var solver: Solver = Solver.new()
var queue: Array[String] = []

func enter() -> void:
	queue = Utils.find_data_files(BulkGenerator.PUZZLE_DIR, "txt")
	object.show_message("Searching %s; found %s files." % [BulkGenerator.PUZZLE_DIR, queue.size()])


func update(_delta: float) -> void:
	if queue.is_empty():
		object.show_message("Analysis complete.")
		change_state("idle")
		return
	
	var puzzle_path: String = queue.pop_front()
	%GameBoard.grid_string = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	%GameBoard.import_grid()
	solver.clear()
	solver.board = %GameBoard.to_solver_board()
	solver.step_until_done()
	copy_board_from_solver()
	var validation_result: SolverBoard.ValidationResult \
			= solver.board.validate(SolverBoard.VALIDATE_STRICT)
	if validation_result.error_count > 0:
		object.show_message("Error: Invalid solution")
		return
	
	var info_path: String = puzzle_info_path(puzzle_path)
	var info_json: Dictionary[String, Variant] = {}
	info_json["difficulty"] = solver.get_measured_difficulty()
	info_json["cells"] = solver.board.cells.size()
	info_json["version"] = 0.01
	FileAccess.open(info_path, FileAccess.WRITE).store_string(JSON.stringify(info_json))
	object.show_message("Wrote %s." % [info_path])


func copy_board_from_solver() -> void:
	solver.board.update_game_board(%GameBoard)


func puzzle_info_path(path: String) -> String:
	return path + ".info"
