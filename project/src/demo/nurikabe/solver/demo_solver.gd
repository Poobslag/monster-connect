@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd]Q[/kbd]: Solve one step.
## 	[kbd]W[/kbd]: Performance test a full solution.
## 	[kbd]E[/kbd]: Solve until bifurcation is necessary.
## 	[kbd]R[/kbd]: Reset the board.
## 	[kbd]P[/kbd]: Print partially solved puzzle to console.
## 	[kbd]Shift + P[/kbd]: Print task queue to console.

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

const CELL_EMPTY := ""
const CELL_INVALID := "!"
const CELL_ISLAND := "."
const CELL_WALL := "##"

var performance_data: Dictionary[String, Variant] = {}
var solver: Solver = Solver.new()

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			step()
			%GameBoard.validate()
		KEY_W:
			performance_test()
			%GameBoard.validate()
		KEY_E:
			solve_until_bifurcation()
			%GameBoard.validate()
		KEY_P:
			if Input.is_key_pressed(KEY_SHIFT):
				solver.print_queue()
			else:
				print_grid_string()
		KEY_R:
			%GameBoard.reset()
			solver.board = %GameBoard.to_solver_board()
			solver.clear()


func _ready() -> void:
	_refresh_puzzle_path()
	solver.board = %GameBoard.to_solver_board()


func print_grid_string() -> void:
	%GameBoard.to_solver_board().print_cells()


func step() -> void:
	if solver.board.is_filled():
		_show_message("--------")
		_show_message("(no changes)")
		return
	
	var changes: Array[Dictionary] = []
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	
	var idle_steps: int = 0
	while idle_steps < 100 and not solver.board.is_filled() and changes.size() < 1:
		var old_filled_cell_count: int = solver.board.get_filled_cell_count()
		
		if not solver.has_scheduled_tasks():
			solver.schedule_tasks()
		if not solver.has_scheduled_tasks():
			break
		solver.step()
		changes = solver.get_changes()
		
		if old_filled_cell_count == solver.board.get_filled_cell_count():
			idle_steps += 1
		else:
			idle_steps = 0
	
	if changes.is_empty():
		_show_message("(no changes)")
	
	if not changes.is_empty():
		for change: Dictionary[String, Variant] in changes:
			var cell_pos: Vector2i = change.get("pos")
			if solver.board.get_cell_string(cell_pos) != CELL_EMPTY:
				push_error("Illegal change: %s == %s" % [cell_pos, solver.board.get_cell_string(cell_pos)])
		
		for deduction: Deduction in solver.deductions.deductions:
			_show_message(str(deduction))
		
		solver.apply_changes()
		%GameBoard.set_cell_strings(changes)


func solve_until_bifurcation() -> void:
	var idle_steps: int = 0
	while idle_steps < 500 and not solver.board.is_filled():
		var old_filled_cell_count: int = solver.board.get_filled_cell_count()
		
		if not solver.has_scheduled_tasks():
			solver.schedule_tasks(false)
		if not solver.has_scheduled_tasks():
			break
		solver.step()
		solver.apply_changes()
		
		if old_filled_cell_count == solver.board.get_filled_cell_count():
			idle_steps += 1
		else:
			idle_steps = 0
	
	for cell: Vector2i in solver.board.cells:
		%GameBoard.set_cell_string(cell, solver.board.get_cell_string(cell))
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	if solver.board.is_filled():
		_show_message("bifurcation: stops=%s, scenarios=%s" % [
			solver.metrics.get("bifurcation_stops"),
			solver.metrics.get("bifurcation_scenarios"),
			])
	else:
		_show_message("bifurcation required: (%s)" % [
			solver.board.get_filled_cell_count()
			])


func performance_test() -> void:
	performance_data.clear()
	
	var start_time: float = Time.get_ticks_usec()
	
	var idle_steps: int = 0
	while idle_steps < 500 and not solver.board.is_filled():
		var old_filled_cell_count: int = solver.board.get_filled_cell_count()
		
		if not solver.has_scheduled_tasks():
			solver.schedule_tasks()
		if not solver.has_scheduled_tasks():
			break
		solver.step()
		solver.apply_changes()
		
		if old_filled_cell_count == solver.board.get_filled_cell_count():
			idle_steps += 1
		else:
			idle_steps = 0
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	_show_message("%.3f msec" % [(Time.get_ticks_usec() - start_time) / 1000.0])
	_show_message("bifurcation: stops=%s, scenarios=%s, duration=%.3f" % [
		solver.metrics.get("bifurcation_stops", 0),
		solver.metrics.get("bifurcation_scenarios", 0),
		solver.metrics.get("bifurcation_duration", 0),
		])
	
	for cell: Vector2i in solver.board.cells:
		%GameBoard.set_cell_string(cell, solver.board.get_cell_string(cell))


func _show_message(s: String) -> void:
	%MessageLabel.text += s + "\n"


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
