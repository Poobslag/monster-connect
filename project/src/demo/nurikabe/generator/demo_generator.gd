extends Node
## [b]Keys:[/b][br]
## 	[kbd][1-8][/kbd]: Set puzzle size.
## 	[kbd]W[/kbd]: Completely solve a puzzle.
## 	[kbd]R[/kbd]: Clear the board.
## 	[kbd]O[/kbd]: Print memory usage statistics.
## 	[kbd]P[/kbd]: Print partially solved puzzle to console.
## 	[kbd]S[/kbd]: Assign fixed seed.
## 	[kbd]Shift + S[/kbd]: Increment fixed seed.
## 	[kbd]D[/kbd]: Increase target difficulty.
## 	[kbd]Shift + D[/kbd]: Decrease target difficulty.
## 	[kbd]G[/kbd]: Generate one step.
## 	[kbd]Shift + G[/kbd]: Generate five steps.
## 	[kbd]H[/kbd]: Completely generate a puzzle.

const PUZZLE_SIZES: Array[Vector2i] = [
	Vector2i(5, 5), # tutorial
	Vector2i(8, 8),
	Vector2i(10, 10), # small puzzles from nikoli's book "nurikabe 1"
	Vector2i(12, 16),
	Vector2i(14, 24), # medium puzzles from nikoli's book "nurikabe 1"
	Vector2i(16, 30),
	Vector2i(20, 36), # large puzzles from nikoli's book "nurikabe 1"
	Vector2i(24, 44),
]

var generator: Generator = Generator.new()
var fixed_seed: int = -1
var generator_running: bool = false

func _ready() -> void:
	generator.board = %GameBoard.to_generator_board()
	%GameBoard.allow_unclued_islands = true


func _input(event: InputEvent) -> void:
	if generator_running:
		# ignore input until the generator is done running
		return
	
	match Utils.key_press(event):
		KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			var size_index: int = wrapi(Utils.key_num(event) - 1, 0, PUZZLE_SIZES.size())
			set_puzzle_size(PUZZLE_SIZES[size_index])
		KEY_Q:
			if Input.is_key_pressed(KEY_SHIFT):
				for i in range(5):
					step_solver()
			else:
				step_solver()
			%GameBoard.validate()
		KEY_W:
			generator.log_enabled = false
			generator.solver.step_until_done()
			copy_board_from_generator()
		KEY_O:
			Utils.print_memory_stats()
		KEY_P:
			print_grid_string()
		KEY_G:
			# empty the log
			generator.log_enabled = true
			generator.consume_events()
			
			if Input.is_key_pressed(KEY_SHIFT):
				for i in range(5):
					step_generator()
			else:
				step_generator()
			%GameBoard.validate()
		KEY_H:
			generator.log_enabled = true
			generator.consume_events()
			if generator.board:
				generator.board.solver_board.cleanup()
			generator.board = %GameBoard.to_generator_board()
			generator_running = true
		KEY_R:
			generator.clear()
			%GameBoard.reset()
			if generator.board:
				generator.board.solver_board.cleanup()
			generator.board = %GameBoard.to_generator_board()
			if fixed_seed != -1:
				generator.rng.seed = fixed_seed
		KEY_S:
			if fixed_seed == -1:
				fixed_seed = 0
			if Input.is_key_pressed(KEY_SHIFT):
				fixed_seed += 1
			generator.rng.seed = fixed_seed
			_show_message("seed: %s" % [fixed_seed])
		KEY_D:
			if Input.is_key_pressed(KEY_SHIFT):
				generator.target_difficulty -= 0.1
			else:
				generator.target_difficulty += 0.1
			generator.target_difficulty = clamp(generator.target_difficulty, 0.0, 1.0)
			_show_message("target_difficulty: %s" % [generator.target_difficulty])
		KEY_M:
			var values: Array[String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
			Utils.shuffle_weighted(values, PackedFloat32Array([0, 1, 2, 3, 4, 5, 6, 7, 8]))
			_show_message("shuffle: %s" % [values])


func _process(_delta: float) -> void:
	if generator_running:
		generator.step()
		copy_board_from_generator()
		show_generator_messages()
		if generator.is_done():
			var validation_result: SolverBoard.ValidationResult \
					= generator.board.solver_board.validate(SolverBoard.VALIDATE_STRICT)
			if validation_result.error_count == 0:
				# filled with no validation errors
				generator_running = false
				%GameBoard.validate()
				_show_message("(finished)")


func print_grid_string() -> void:
	var board: SolverBoard = %GameBoard.to_solver_board()
	board.print_cells()
	board.cleanup()
	var clue_minimum_strings: Array[String] = []
	for clue_minimum_cell: Vector2i in generator.board.clue_minimums:
		var string: String = "%s:%s" % [clue_minimum_cell, generator.board.clue_minimums[clue_minimum_cell]]
		if generator.board.clues[clue_minimum_cell] < generator.board.clue_minimums[clue_minimum_cell]:
			string = "! %s" % [string]
		clue_minimum_strings.append(string)
	print("clue minimums: %s" % [JSON.stringify(clue_minimum_strings)])


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


func step_generator() -> void:
	if generator.is_done():
		var validation_result: SolverBoard.ValidationResult \
				= generator.board.solver_board.validate(SolverBoard.VALIDATE_STRICT)
		if validation_result.error_count == 0:
			_show_message("--------")
			_show_message("(finished)")
			return
	
	generator.step()
	show_generator_messages()


func show_generator_messages() -> void:
	if not %DemoLog.text.is_empty():
		_show_message("--------")
	var events: Array[String] = generator.consume_events()
	if generator.mutate_steps >= 1:
		_show_message("(mutate %s/%s)" % [generator.mutate_steps, Generator.TARGET_MUTATE_STEPS])
	if events.is_empty():
		_show_message("(no changes)")
	else:
		for event: String in events:
			_show_message(event)
		copy_board_from_generator()


func step_solver() -> void:
	if generator.solver.board.is_filled() and not generator.has_validation_errors():
		_show_message("--------")
		_show_message("(finished)")
		return
	
	if not %DemoLog.text.is_empty():
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
	%DemoLog.show_message(s)
