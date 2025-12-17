extends Node
## [b]Keys:[/b][br]
## 	[kbd][1-8][/kbd]: Set puzzle size.
## 	[kbd]Q[/kbd]: Solve one step.
## 	[kbd]Shift + Q[/kbd]: Solve five steps.
## 	[kbd]W[/kbd]: Completely solve a puzzle.
## 	[kbd]R[/kbd]: Clear the board.
## 	[kbd]P[/kbd]: Print partially solved puzzle to console.
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

func _ready() -> void:
	generator.board = %GameBoard.to_generator_board()


func _input(event: InputEvent) -> void:
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
			generator.board = %GameBoard.to_generator_board()
			generator.step_until_done()
			copy_board_from_generator()
			%GameBoard.validate()
		KEY_R:
			generator.clear()
			%GameBoard.reset()
			generator.board = %GameBoard.to_generator_board()
		KEY_M:
			var values: Array[String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
			Utils.shuffle_weighted(values, PackedFloat32Array([0, 1, 2, 3, 4, 5, 6, 7, 8]))
			_show_message("shuffle: %s" % [values])


func print_grid_string() -> void:
	%GameBoard.to_solver_board().print_cells()


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


func step_generator() -> void:
	if generator.board.is_filled():
		var validation_result: SolverBoard.ValidationResult \
				= generator.board.solver_board.validate(SolverBoard.VALIDATE_STRICT)
		if validation_result.error_count == 0:
			_show_message("--------")
			_show_message("(no changes)")
			return
	
	generator.step()
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	var events: Array[String] = generator.consume_events()
	if events.is_empty():
		_show_message("(no changes)")
	else:
		for event: String in events:
			_show_message(event)
		copy_board_from_generator()


func step_solver() -> void:
	if generator.solver.board.is_filled():
		_show_message("--------")
		_show_message("(no changes)")
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
			_show_message("%s %s" % \
					[shown_index, str(deduction)])
		
		for change: Dictionary[String, Variant] in generator.solver.deductions.get_changes():
			%GameBoard.set_cell(change["pos"], change["value"])
		
		generator.solver.apply_changes()


func copy_board_from_generator() -> void:
	generator.board.solver_board.update_game_board(%GameBoard)


func _show_message(s: String) -> void:
	%MessageLabel.text += s + "\n"
