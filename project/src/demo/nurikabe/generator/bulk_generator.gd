extends Node

const PUZZLE_DIR: String = "user://puzzles"
const MAX_LINES: int = 500
const PUZZLE_TYPES: Array[Dictionary] = [
	{
		"id": "micro",
		"weight": 5.0,
		"cells_mean": 40,
		"cells_spread": 15,
		"cells_min": 25,
		"cells_max": 60,
		
		"difficulty_mean": 0.1,
		"difficulty_spread": 0.3,
	},
	{
		"id": "small",
		"weight": 25.0,
		"cells_mean": 80,
		"cells_spread": 20,
		"cells_min": 50,
		"cells_max": 100,
		
		"difficulty_mean": 0.2,
		"difficulty_spread": 0.3,
	},
	{
		"id": "medium",
		"weight": 25.0,
		"cells_mean": 120,
		"cells_spread": 40,
		"cells_min": 90,
		"cells_max": 180,
		
		"difficulty_mean": 0.3,
		"difficulty_spread": 0.3,
	},
	{
		"id": "large",
		"weight": 12.0,
		"cells_mean": 200,
		"cells_spread": 60,
		"cells_min": 150,
		"cells_max": 300,
		
		"difficulty_mean": 0.4,
		"difficulty_spread": 0.3,
	},
	{
		"id": "xl",
		"weight": 8.0,
		"cells_mean": 330,
		"cells_spread": 120,
		"cells_min": 240,
		"cells_max": 480,
		
		"difficulty_mean": 0.5,
		"difficulty_spread": 0.3,
	},
	{
		"id": "xxl",
		"weight": 4.0,
		"cells_mean": 550,
		"cells_spread": 200,
		"cells_min": 400,
		"cells_max": 800,
		
		"difficulty_mean": 0.6,
		"difficulty_spread": 0.3,
	},
]

var generator: Generator = Generator.new()
var fixed_seed: int = -1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var puzzle_num: int = 1

var _stuck_state: Dictionary[String, Variant] = {}

func _ready() -> void:
	while FileAccess.file_exists(user_puzzle_path()):
		puzzle_num += 1
	
	generator.board = %GameBoard.to_generator_board()
	%GameBoard.allow_unclued_islands = true
	create_board()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_P:
			set_process(not is_processing())
			_show_message("processing -> %s" % [is_processing()])


func _process(_delta: float) -> void:
	generator.step()
	
	if generator.check_stuck(_stuck_state):
		_show_message("error: stuck")
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
			_show_message("error: puzzle failed validation")
		create_board()


func create_board() -> void:
	var weights: Array[float] = []
	for puzzle_type: Dictionary in PUZZLE_TYPES:
		weights.append(puzzle_type["weight"])
	var puzzle_type: Dictionary = PUZZLE_TYPES[rng.rand_weighted(weights)]
	
	var cells: int = roundi(rng.randfn(puzzle_type["cells_mean"], puzzle_type["cells_spread"]))
	cells = clampi(cells, puzzle_type["cells_min"], puzzle_type["cells_max"])
	
	var difficulty: float = rng.randfn(puzzle_type["difficulty_mean"], puzzle_type["difficulty_spread"])
	difficulty = clamp(difficulty, 0.0, 1.0)
	generator.difficulty = difficulty
	
	var puzzle_size: Vector2i = pick_puzzle_size(cells)
	set_puzzle_size(puzzle_size)
	
	_show_message("puzzle #%s: %s size=%s target_difficulty=%.2f" \
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


func user_puzzle_path() -> String:
	return PUZZLE_DIR.path_join("%s.txt" % [puzzle_num])


func puzzle_info_path(path: String) -> String:
	return path + ".info"


func output_board() -> void:
	var path: String = user_puzzle_path()
	var board: SolverBoard = generator.board.solver_board.duplicate()
	board.erase_solution_cells()
	if not DirAccess.dir_exists_absolute(PUZZLE_DIR):
		DirAccess.make_dir_recursive_absolute(PUZZLE_DIR)
	FileAccess.open(path, FileAccess.WRITE).store_string(board.to_grid_string())
	
	var info_path: String = puzzle_info_path(path)
	var info_json: Dictionary[String, Variant] = {}
	info_json["difficulty"] = generator.solver.get_measured_difficulty()
	info_json["cells"] = generator.solver.board.cells.size()
	info_json["version"] = 0.01
	FileAccess.open(info_path, FileAccess.WRITE).store_string(JSON.stringify(info_json))
	
	_show_message("wrote puzzle #%s to %s; measured_difficulty=%.2f" \
			% [puzzle_num, path, info_json["difficulty"]])
	
	puzzle_num += 1


func set_puzzle_size(puzzle_size: Vector2i) -> void:
	var new_grid_string: String = ""
	for y in puzzle_size.y:
		new_grid_string += "  ".repeat(puzzle_size.x)
		new_grid_string += "\n"
	%GameBoard.reset()
	%GameBoard.grid_string = new_grid_string
	%GameBoard.import_grid()
	generator.clear()
	generator.board = %GameBoard.to_generator_board()


func step_solver() -> void:
	if generator.solver.board.is_filled() and not generator.has_validation_errors():
		_show_message("--------")
		_show_message("(finished)")
		return
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	
	generator.solver.step()
	
	if not generator.solver.deductions.has_changes():
		_show_message("(no changes)")
	else:
		for deduction_index: int in generator.solver.deductions.size():
			var shown_index: int = generator.solver.board.version + deduction_index
			var deduction: Deduction = generator.solver.deductions.deductions[deduction_index]
			_show_message("%s-%s %s" % \
					[generator.step_count, shown_index, str(deduction)])
		
		for change: Dictionary[String, Variant] in generator.solver.deductions.get_changes():
			%GameBoard.set_cell(change["pos"], change["value"])
		
		generator.solver.apply_changes()


func copy_board_from_generator() -> void:
	generator.board.solver_board.update_game_board(%GameBoard)


func _show_message(s: String) -> void:
	if %MessageLabel.text:
		%MessageLabel.text += "\n"
	%MessageLabel.text += s
	while %MessageLabel.get_line_count() > MAX_LINES:
		%MessageLabel.text = StringUtils.substring_after(%MessageLabel.text, "\n")
