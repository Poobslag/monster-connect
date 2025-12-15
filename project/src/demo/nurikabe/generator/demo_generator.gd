extends Node
## [b]Keys:[/b][br]
## 	[kbd][1-8][/kbd]: Set puzzle size.
## 	[kbd]Q[/kbd]: Solve one step.
## 	[kbd]Shift + Q[/kbd]: Solve five steps.
## 	[kbd]W[/kbd]: Test a full solution.
## 	[kbd]R[/kbd]: Clear the board.
## 	[kbd]G[/kbd]: Generate a puzzle.

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
var solver: Solver = Solver.new()

func _ready() -> void:
	solver.set_generation_strategy()
	generator.board = %GameBoard.to_generator_board()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			var size_index: int = wrapi(Utils.key_num(event) - 1, 0, PUZZLE_SIZES.size())
			set_puzzle_size(PUZZLE_SIZES[size_index])
		KEY_Q:
			solver.board = generator.board.solver_board
			if Input.is_key_pressed(KEY_SHIFT):
				for i in range(5):
					step()
			else:
				step()
			%GameBoard.validate()
		KEY_W:
			solver.board = generator.board.solver_board
			solver.step_until_done()
			copy_board_from_generator()
		KEY_G:
			generator.board = %GameBoard.to_generator_board()
			generator.generate()
			copy_board_from_generator()
		KEY_R:
			generator.clear()
			%GameBoard.reset()
			copy_board_from_generator()


func set_puzzle_size(puzzle_size: Vector2i) -> void:
	var new_grid_string: String = ""
	for y in puzzle_size.y:
		new_grid_string += "  ".repeat(puzzle_size.x)
		new_grid_string += "\n"
	%GameBoard.reset()
	%GameBoard.grid_string = new_grid_string
	%GameBoard.import_grid()


func step() -> void:
	if solver.board.is_filled():
		_show_message("--------")
		_show_message("(no changes)")
		return
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	
	solver.step()
	
	if not solver.deductions.has_changes():
		_show_message("(no changes)")
	else:
		for deduction_index: int in solver.deductions.deductions.size():
			var shown_index: int = solver.board.version + deduction_index
			var deduction: Deduction = solver.deductions.deductions[deduction_index]
			_show_message("%s %s" % \
					[shown_index, str(deduction)])
		
		for change: Dictionary[String, Variant] in solver.deductions.get_changes():
			%GameBoard.set_cell(change["pos"], change["value"])
		
		solver.apply_changes()


func copy_board_from_generator() -> void:
	generator.board.solver_board.update_game_board(%GameBoard)


func _show_message(s: String) -> void:
	%MessageLabel.text += s + "\n"
