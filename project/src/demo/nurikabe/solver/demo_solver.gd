@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd][1-0][/kbd]: Load puzzle #61-70.
## 	[kbd]Q[/kbd]: Solve one step.
## 	[kbd]Shift + Q[/kbd]: Solve five steps.
## 	[kbd]W[/kbd]: Performance test a full solution.
## 	[kbd]Shift + W[/kbd]: Performance test puzzles #61-70.
## 	[kbd]E[/kbd]: Solve until bifurcation is necessary.
## 	[kbd]R[/kbd]: Reset the board.
## 	[kbd]P[/kbd]: Print partially solved puzzle to console.
## 	[kbd]Shift + P[/kbd]: Print task queue to console.

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

@export var log_enabled: bool = false:
	set(value):
		log_enabled = value
		solver.log_enabled = log_enabled


const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const PUZZLE_PATHS: Array[String] = [
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_062.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_063.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_064.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_065.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_066.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_067.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_068.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_069.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_070.txt",
	"res://assets/demo/nurikabe/puzzles/puzzle_nikoli_1_071.txt",
]

var performance_data: Dictionary[String, Variant] = {}
var solver: Solver = Solver.new()

var performance_suite_queue: Array[String] = []

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			var puzzle_index: int = wrapi(Utils.key_num(event) - 1, 0, PUZZLE_PATHS.size())
			load_puzzle(PUZZLE_PATHS[puzzle_index])
		KEY_Q:
			if Input.is_key_pressed(KEY_SHIFT):
				for i in range(5):
					step()
			else:
				step()
			%GameBoard.validate()
		KEY_W:
			performance_data.clear()
			if Input.is_key_pressed(KEY_SHIFT):
				performance_suite_queue = PUZZLE_PATHS.duplicate()
				if not %MessageLabel.text.is_empty():
					_show_message("--------")
				_show_message("performance suite start (%s)" % [performance_suite_queue.size()])
				_show_message("")
				_show_message("| Puzzle | Result | Time (ms) | Bifurcations |")
				_show_message("|:--|:--:|--:|--:|")
				%PerformanceSuiteTimer.start()
			else:
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
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	
	keep_stepping(100, 1, false)
	
	var changes: Array[Dictionary] = solver.get_changes()
	if changes.is_empty():
		_show_message("(no changes)")
	
	if not changes.is_empty():
		for change: Dictionary[String, Variant] in changes:
			var cell_pos: Vector2i = change.get("pos")
			if solver.board.get_cell(cell_pos) != CELL_EMPTY:
				push_error("Illegal change: %s == %s" % [cell_pos, solver.board.get_cell(cell_pos)])
		
		for deduction_index: int in solver.deductions.deductions.size():
			var shown_index: int = solver.board.get_filled_cell_count() \
					- solver.deductions.deductions.size() + deduction_index
			var deduction: Deduction = solver.deductions.deductions[deduction_index]
			_show_message("%s %s" % [shown_index, str(deduction)])
		
		solver.apply_changes()
		for change: Dictionary[String, Variant] in changes:
			%GameBoard.set_cell(change["pos"], change["value"])


func copy_board_from_solver() -> void:
	for cell: Vector2i in solver.board.cells:
		%GameBoard.set_cell(cell, solver.board.get_cell(cell))


func solve_until_bifurcation() -> void:
	keep_stepping(500, 999999, true, false)
	copy_board_from_solver()
	
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


func keep_stepping(idle_step_threshold: int, deduction_threshold: int = 999999, \
		apply_changes: bool = true, allow_bifurcation: bool = true) -> void:
	var idle_steps: int = 0
	while idle_steps < idle_step_threshold and solver.deductions.size() < deduction_threshold:
		var old_filled_cell_count: int = solver.board.get_filled_cell_count()
		if solver.board.is_filled():
			break
		if not solver.has_scheduled_tasks():
			solver.schedule_tasks(allow_bifurcation)
		if not solver.has_scheduled_tasks():
			break
		solver.step()
		if apply_changes:
			solver.apply_changes()
		if old_filled_cell_count == solver.board.get_filled_cell_count():
			idle_steps += 1
		else:
			idle_steps = 0


func load_puzzle(new_puzzle_path: String) -> void:
	puzzle_path = new_puzzle_path
	solver.board = %GameBoard.to_solver_board()
	solver.clear()


func performance_test() -> void:
	var start_time: float = Time.get_ticks_usec()
	
	keep_stepping(500)
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	_show_message("%.3f msec" % [(Time.get_ticks_usec() - start_time) / 1000.0])
	_show_message("bifurcation: stops=%s, scenarios=%s, duration=%.3f" % [
		solver.metrics.get("bifurcation_stops", 0),
		solver.metrics.get("bifurcation_scenarios", 0),
		solver.metrics.get("bifurcation_duration", 0),
		])
	
	for cell: Vector2i in solver.board.cells:
		%GameBoard.set_cell(cell, solver.board.get_cell(cell))


func _show_message(s: String) -> void:
	%MessageLabel.text += s + "\n"


func _show_suite_results() -> void:
	_show_message("")
	_show_message("**Summary:** ")
	_show_message("✔️ %s / %s completed ⏱ %s ms total 🔀 %s bifurcations" % [
		performance_data.get("total_ok", 0), performance_data.get("total_run", 0),
		_msec_str(performance_data.get("total_duration") / 1000.0),
		performance_data.get("total_bifurcation_stops"),
	])
	_show_message("--------")
	_show_message("finished")


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


func _on_performance_suite_timer_timeout() -> void:
	if performance_suite_queue.is_empty():
		%PerformanceSuiteTimer.stop()
		_show_suite_results()
		return
	
	var next_path: String = performance_suite_queue.pop_front()
	load_puzzle(next_path)
	
	var start_time: int = Time.get_ticks_usec()
	keep_stepping(500)
	copy_board_from_solver()
	var duration: int = Time.get_ticks_usec() - start_time
	var filled: bool = solver.board.is_filled()
	var validation_errors: SolverBoard.ValidationResult = solver.board.validate()
	var puzzle_name: String = StringUtils.substring_after_last(next_path, "/").trim_suffix(".txt")
	var result: String = "err" if validation_errors.error_count > 0 else "dnf" if not filled else "ok"
	_show_message("| %s | %s %s | %s | %s |" % [
			puzzle_name,
			"✅" if result == "ok" else "⚠️", result,
			_msec_str(duration / 1000.0),
			solver.metrics.get("bifurcation_stops", 0)
		])
	
	if not performance_data.has("total_duration"):
		performance_data["total_duration"] = 0
	performance_data["total_duration"] += duration
	
	if not performance_data.has("total_run"):
		performance_data["total_run"] = 0
	performance_data["total_run"] += 1
	
	if not performance_data.has("total_ok"):
		performance_data["total_ok"] = 0
	performance_data["total_ok"] += 1 if result == "ok" else 0
	
	if not performance_data.has("total_bifurcation_stops"):
		performance_data["total_bifurcation_stops"] = 0
	performance_data["total_bifurcation_stops"] += solver.metrics.get("bifurcation_stops", 0)


func _msec_str(msec: float) -> String:
	var sig_figs: int = 1 if msec < 1000 else 2
	var digits: int = floori(log(abs(msec)) / log(10)) if msec != 0 else 0
	var scale: int = int(pow(10, digits - (sig_figs - 1)))
	var result: int = roundi(msec / float(scale)) * scale
	return str(result)
