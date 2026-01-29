extends State

var generator: Generator = Generator.new()
var puzzle_num: int = 1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _stuck_state: Dictionary[String, Variant] = {}

func enter() -> void:
	if generator.board:
		generator.board.solver_board.cleanup()
	generator.board = %GameBoard.to_generator_board()
	create_board()


func update(_delta: float) -> void:
	generator.step()
	
	if generator.check_stuck(_stuck_state):
		object.log_message("error: stuck")
		create_board()
		return
	
	copy_board_from_generator()
	if generator.is_done():
		var validation_result: SolverBoard.ValidationResult \
				= generator.board.solver_board.validate(SolverBoard.VALIDATE_STRICT)
		if validation_result.error_count == 0:
			# filled with no validation errors
			output_board()
		else:
			object.log_message("error: puzzle failed validation")
		create_board()


func copy_board_from_generator() -> void:
	generator.board.solver_board.update_game_board(%GameBoard)


func create_board() -> void:
	while FileAccess.file_exists(user_puzzle_path()):
		puzzle_num += 1
	
	var weights: Array[float] = []
	for puzzle_type: Dictionary in BulkGenerator.PUZZLE_TYPES:
		weights.append(puzzle_type["weight"])
	var puzzle_type: Dictionary = BulkGenerator.PUZZLE_TYPES[rng.rand_weighted(weights)]
	
	var cells: int = roundi(rng.randfn(puzzle_type["cells_mean"], puzzle_type["cells_spread"]))
	cells = clampi(cells, puzzle_type["cells_min"], puzzle_type["cells_max"])
	
	var puzzle_size: Vector2i = pick_puzzle_size(cells)
	set_puzzle_size(puzzle_size)
	
	var difficulty: float = rng.randfn(puzzle_type["difficulty_mean"], puzzle_type["difficulty_spread"])
	difficulty = clamp(difficulty, 0.0, 1.0)
	generator.difficulty = difficulty
	
	object.log_message("puzzle #%s: %s size=%s target_difficulty=%.2f" \
			% [puzzle_num, puzzle_type["id"], puzzle_size, difficulty])
	_stuck_state.clear()


## Pick a random puzzle size close to to the target cell count.[br]
## [br]
## Enforces reasonable aspect ratios (< 2:1) and a minimum side length of 5.
func pick_puzzle_size(cells: float) -> Vector2i:
	var puzzle_size: Vector2i = Vector2i.ONE
	var width_sigma: float = sqrt(cells) * 0.25
	var min_width: int = int(ceil(sqrt(cells) / 1.41421))
	min_width = maxi(min_width, 5)
	var max_width: int = int(floor(sqrt(cells) * 1.41421))
	puzzle_size.x = roundi(rng.randfn(sqrt(cells), width_sigma))
	puzzle_size.x = clampi(puzzle_size.x, min_width, max_width)
	puzzle_size.y = roundi(cells / float(puzzle_size.x))
	puzzle_size.y = clampi(puzzle_size.y, min_width, max_width)
	return puzzle_size


func output_board() -> void:
	var path: String = user_puzzle_path()
	var board: SolverBoard = generator.board.solver_board.duplicate()
	board.erase_solution_cells()
	if not DirAccess.dir_exists_absolute(BulkGenerator.GENERATED_PUZZLE_DIR):
		DirAccess.make_dir_recursive_absolute(BulkGenerator.GENERATED_PUZZLE_DIR)
	FileAccess.open(path, FileAccess.WRITE).store_string(board.to_grid_string())
	
	var info_path: String = puzzle_info_path(path)
	var info_json: Dictionary[String, Variant] = {}
	info_json["difficulty"] = generator.solver.get_measured_difficulty()
	info_json["cells"] = generator.solver.board.cells.size()
	info_json["version"] = 0.02
	FileAccess.open(info_path, FileAccess.WRITE).store_string(JSON.stringify(info_json))
	
	object.log_message("wrote puzzle #%s to %s; measured_difficulty=%.2f" \
			% [puzzle_num, path, info_json["difficulty"]])
	
	puzzle_num += 1
	board.cleanup()


func set_puzzle_size(puzzle_size: Vector2i) -> void:
	var new_grid_string: String = ""
	for y in puzzle_size.y:
		new_grid_string += "  ".repeat(puzzle_size.x)
		new_grid_string += "\n"
	%GameBoard.reset()
	%GameBoard.grid_string = new_grid_string
	%GameBoard.import_grid()
	generator.clear()
	if generator.board:
		generator.board.solver_board.cleanup()
	generator.board = %GameBoard.to_generator_board()


func user_puzzle_path() -> String:
	return BulkGenerator.GENERATED_PUZZLE_DIR.path_join("%s.txt" % [puzzle_num])


func puzzle_info_path(path: String) -> String:
	return path + ".info"
