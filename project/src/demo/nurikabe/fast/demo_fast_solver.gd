@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd]Q[/kbd]: Solve one step.
## 	[kbd]W[/kbd]: Performance test a full solution.
## 	[kbd]R[/kbd]: Reset the board.
## 	[kbd]P[/kbd]: Print partially solved puzzle to console.

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

const CELL_EMPTY := ""
const CELL_INVALID := "!"
const CELL_ISLAND := "."
const CELL_WALL := "##"

var ran_starting_techniques: bool = false
var performance_data: Dictionary[String, Variant] = {}
var solver: FastSolver = FastSolver.new()

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			solve()
		KEY_P:
			print_grid_string()
		KEY_R:
			%GameBoard.reset()
			solver.board = %GameBoard.to_fast_board()
			solver.clear()


func _ready() -> void:
	_refresh_puzzle_path()
	solver.board = %GameBoard.to_fast_board()


func print_grid_string() -> void:
	%GameBoard.to_model().print_cells()

func solve() -> void:
	var changes: Array[Dictionary] = []
	
	if not %MessageLabel.text.is_empty():
		%MessageLabel.text += "--------\n"
	
	while changes.size() < 5:
		solver.do_something()
		changes = solver.get_changes()
		if solver.is_queue_empty():
			break
	
	if changes.is_empty():
		%MessageLabel.text += "(no changes)\n"
	
	if not changes.is_empty():
		for change: Dictionary[String, Variant] in changes:
			var cell_pos: Vector2i = change.get("pos")
			if solver.board.get_cell_string(cell_pos) != CELL_EMPTY:
				push_error("Illegal change: %s == %s" % [cell_pos, solver.board.get_cell_string(cell_pos)])
		
		for deduction: FastDeduction in solver.fast_pass.deductions:
			%MessageLabel.text += "%s: %s\n" % [deduction.pos, deduction.reason]
		
		solver.apply_changes()
		%GameBoard.set_cell_strings(changes)


func _record_deduction_result(callable: Callable, start_ticks_usec: int, deduction_count: int) -> void:
	var call_count_property: String = "%s_call_count" % [callable.get_method()]
	var old_call_count: int = performance_data.get(call_count_property, 0)
	performance_data[call_count_property] = old_call_count + 1
	
	var deduction_count_property: String = "%s_deduction_count" % [callable.get_method()]
	var old_deduction_count: int = performance_data.get(deduction_count_property, 0)
	performance_data[deduction_count_property] = old_deduction_count + deduction_count
	
	var duration_property: String = "%s_duration" % [callable.get_method()]
	var old_duration: float = performance_data.get(duration_property, 0.0)
	var duration: float = (Time.get_ticks_usec() - start_ticks_usec) / 1000.0
	performance_data[duration_property] = old_duration + duration


func _refresh_puzzle_path() -> void:
	if not is_inside_tree():
		return
	
	var s: String = FileAccess.get_file_as_string(puzzle_path)
	var file_lines: PackedStringArray = s.split("\n")
	var puzzle_lines: Array[String] = []
	for file_line: String in file_lines:
		if file_line.begins_with("//"):
			continue
		puzzle_lines.append(file_line)
	%GameBoard.grid_string = "\n".join(PackedStringArray(puzzle_lines))
	%GameBoard.import_grid()
