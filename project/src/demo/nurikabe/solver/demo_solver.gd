@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd]Q[/kbd]: Solve one step.
## 	[kbd]Shift + Q[/kbd]: Solve five steps.
## 	[kbd]W[/kbd]: Performance test a full solution.
## 	[kbd]Shift + W[/kbd]: Performance test next 10 puzzles in sequence.
## 	[kbd]E[/kbd]: Solve until bifurcation is necessary.
## 	[kbd]R[/kbd]: Reset the board.
## 	[kbd]O[/kbd]: Print memory usage statistics.
## 	[kbd]P[/kbd]: Print partially solved puzzle to console.
## 	[kbd]Shift + P[/kbd]: Print available probes and bifurcation scenarios to console.
## 	[kbd]D[/kbd]: Print the puzzle's measured difficulty.
## 	[kbd]F[/kbd]: Print the puzzle's fun.
## 	[kbd]H[/kbd]: Clear the solver history. Forces deductions to be rerun.
## 	[kbd]B[/kbd]: Print benchmark results for AggregateTimer/SplitTimer.
##
## [b]Commands:[/b][br]
## 	[kbd]/j<n>[/kbd]: Load Janko puzzle <n>.
## 	[kbd]/n<n>[/kbd]: Load Nikoli puzzle <n>.
## 	[kbd]/p<n>[/kbd]: Load Poobslag puzzle <n>.

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

@export var verbose: bool = false:
	set(value):
		verbose = value
		solver.verbose = verbose

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const FUN_TRIVIAL: Deduction.FunAxis = Deduction.FunAxis.FUN_TRIVIAL
const FUN_FAST: Deduction.FunAxis = Deduction.FunAxis.FUN_FAST
const FUN_NOVELTY: Deduction.FunAxis = Deduction.FunAxis.FUN_NOVELTY
const FUN_THINK: Deduction.FunAxis = Deduction.FunAxis.FUN_THINK
const FUN_BIFURCATE: Deduction.FunAxis = Deduction.FunAxis.FUN_BIFURCATE

var performance_data: Dictionary[String, Variant] = {}
var solver: Solver = Solver.new()
var performance_suite_queue: Array[String] = []

var _puzzle_paths: Array[String] = []
var _performance_test_start_index: int = -1

func _ready() -> void:
	_load_puzzle_paths()
	solver.board = %GameBoard.to_solver_board()
	_performance_test_start_index = _puzzle_paths.find(puzzle_path)


func _load_puzzle_paths() -> void:
	for dir_path: String in [
			"res://assets/demo/nurikabe/puzzles/janko",
			"res://assets/demo/nurikabe/puzzles/nikoli",
			"res://assets/demo/nurikabe/puzzles/poobslag",
			]:
		for file: String in DirAccess.get_files_at(dir_path):
			_puzzle_paths.append(dir_path.path_join(file))
	_puzzle_paths.sort_custom(func(a: String, b: String) -> bool:
		if a.get_base_dir() != b.get_base_dir():
			return a.get_base_dir() < b.get_base_dir()
		return int(a.get_basename()) < int(b.get_basename())
	)

func _input(event: InputEvent) -> void:
	if %CommandPalette.has_focus():
		return
	
	match Utils.key_press(event):
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
				if _performance_test_start_index == -1:
					push_error("Puzzle not found: %s" % [puzzle_path])
					return
				performance_suite_queue.clear()
				for i in 10:
					var performance_text_index: int = (_performance_test_start_index + i) % _puzzle_paths.size()
					performance_suite_queue.append(_puzzle_paths[performance_text_index])
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
		KEY_O:
			Utils.print_memory_stats()
		KEY_P:
			if Input.is_key_pressed(KEY_SHIFT):
				solver.probe_library.print_available_probes()
				solver.bifurcation_engine.print_scenarios()
			else:
				print_grid_string()
		KEY_R:
			%GameBoard.reset()
			if solver.board:
				solver.board.cleanup()
			solver.board = %GameBoard.to_solver_board()
			solver.clear()
		KEY_D:
			var difficulty: float = solver.get_measured_difficulty()
			_show_message("difficulty: %0.2f" % [difficulty])
		KEY_F:
			_show_normalized_fun_string()
		KEY_B:
			AggregateTimer.print_results()
			SplitTimer.print_results()
		KEY_SLASH:
			%CommandPalette.open()
			get_viewport().set_input_as_handled()


func _show_normalized_fun_string() -> String:
	var fun: Dictionary[Deduction.FunAxis, float] = solver.metrics.get("fun", \
			{} as Dictionary[Deduction.FunAxis, float])
	
	var normalized_fun: Dictionary[Deduction.FunAxis, int] = {}
	for key: Deduction.FunAxis in Deduction.FunAxis.values():
		var normalized_value: int = round(100 * fun.get(key, 0.0) / solver.board.cells.size())
		normalized_fun[key] = normalized_value
	
	_show_message("easy=%s (%s/%s) thinky=%s (%s/%s/%s)" % [
		normalized_fun[FUN_TRIVIAL] + normalized_fun[FUN_FAST],
		normalized_fun[FUN_TRIVIAL],
		normalized_fun[FUN_FAST],
		normalized_fun[FUN_NOVELTY] + normalized_fun[FUN_THINK] + normalized_fun[FUN_BIFURCATE],
		normalized_fun[FUN_NOVELTY],
		normalized_fun[FUN_THINK],
		normalized_fun[FUN_BIFURCATE],
	])
	
	return JSON.stringify(normalized_fun)


func print_grid_string() -> void:
	var board: SolverBoard = %GameBoard.to_solver_board()
	board.print_cells()
	board.cleanup()


func step() -> void:
	if solver.board.is_filled():
		_show_message("--------")
		_show_message("(finished)")
		return
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	
	solver.step()
	
	if not solver.deductions.has_changes():
		_show_message("(no changes)")
	else:
		for deduction_index: int in solver.deductions.size():
			var shown_index: int = solver.board.version + deduction_index
			var deduction: Deduction = solver.deductions.deductions[deduction_index]
			_show_message("%s %s" % \
					[shown_index, str(deduction)])
		
		for change: Dictionary[String, Variant] in solver.deductions.get_changes():
			%GameBoard.set_cell(change["pos"], change["value"])
		
		solver.apply_changes()


func copy_board_from_solver() -> void:
	solver.board.update_game_board(%GameBoard)


func solve_until_bifurcation() -> void:
	solver.step_until_done(Solver.SolverPass.GLOBAL)
	
	copy_board_from_solver()
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	if solver.board.is_filled():
		_show_message("bifurcation: stops=%s scenarios=%s" % [
			solver.metrics.get("bifurcation_stops"),
			solver.metrics.get("bifurcation_scenarios"),
			])
	else:
		_show_message("bifurcation required: (%s)" % [
			solver.board.version
			])


func load_puzzle(new_puzzle_path: String) -> void:
	puzzle_path = new_puzzle_path
	if solver.board:
		solver.board.cleanup()
	solver.board = %GameBoard.to_solver_board()
	solver.clear()


func performance_test() -> void:
	var start_time: float = Time.get_ticks_usec()
	
	solver.step_until_done()
	
	if not %MessageLabel.text.is_empty():
		_show_message("--------")
	_show_message("%.3f msec" % [(Time.get_ticks_usec() - start_time) / 1000.0])
	_show_message("bifurcation: stops=%s scenarios=%s, duration=%.3f" % [
			solver.metrics.get("bifurcation_stops", 0),
			solver.metrics.get("bifurcation_scenarios", 0),
			solver.metrics.get("bifurcation_duration", 0),
		])
	
	copy_board_from_solver()


func _show_message(s: String) -> void:
	%MessageLabel.text += s + "\n"


func _show_suite_results() -> void:
	_show_message("")
	_show_message("**Summary:** ")
	_show_message("✔️ %s / %s completed ⏱ %s ms total 🔀 %s bifurcations" % [
		performance_data.get("total_ok", 0), performance_data.get("total_run", 0),
		_msec_str(performance_data.get("total_duration") / 1000.0),
		performance_data.get("total_bifurcation_scenarios"),
	])
	_show_message("--------")
	_show_message("finished")


func _refresh_puzzle_path() -> void:
	if not is_inside_tree():
		return
	
	%GameBoard.grid_string = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	%GameBoard.import_grid()


func _on_performance_suite_timer_timeout() -> void:
	if performance_suite_queue.is_empty():
		%PerformanceSuiteTimer.stop()
		_show_suite_results()
		return
	
	var next_path: String = performance_suite_queue.pop_front()
	load_puzzle(next_path)
	
	var start_time: int = Time.get_ticks_usec()
	
	solver.step_until_done()
	
	copy_board_from_solver()
	var duration: int = Time.get_ticks_usec() - start_time
	var filled: bool = solver.board.is_filled()
	var validation_errors: SolverBoard.ValidationResult = solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	if validation_errors.error_count > 0:
		push_error("Validation errors for %s: %s" % [next_path, validation_errors])
	var puzzle_name: String = StringUtils.substring_between(next_path, "nurikabe/puzzles", ".")
	var result: String = "err" if validation_errors.error_count > 0 else "dnf" if not filled else "ok"
	_show_message("| %s | %s %s | %s | %s |" % [
			puzzle_name,
			"✅" if result == "ok" else "⚠️", result,
			_msec_str(duration / 1000.0),
			solver.metrics.get("bifurcation_scenarios", 0)
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
	
	if not performance_data.has("total_bifurcation_scenarios"):
		performance_data["total_bifurcation_scenarios"] = 0
	performance_data["total_bifurcation_scenarios"] += solver.metrics.get("bifurcation_scenarios", 0)


func _msec_str(msec: float) -> String:
	var sig_figs: int = 1 if msec < 1000 else 2
	var digits: int = floori(log(abs(msec)) / log(10)) if msec != 0 else 0
	var scale: int = int(pow(10, digits - (sig_figs - 1)))
	var result: int = roundi(msec / float(scale)) * scale
	return str(result)


func _on_command_palette_command_entered(command: String) -> void:
	match command.substr(0, 1):
		"j", "n", "p":
			if not command.substr(1).is_valid_int():
				_show_message("Invalid parameter: " % [command.substr(1)])
				return
			var puzzle_path_pattern: String
			match command.substr(0, 1):
				"j": puzzle_path_pattern = "res://assets/demo/nurikabe/puzzles/janko/%s.janko"
				"n": puzzle_path_pattern = "res://assets/demo/nurikabe/puzzles/nikoli/%s.txt"
				"p": puzzle_path_pattern = "res://assets/demo/nurikabe/puzzles/poobslag/%s.txt"
				_: puzzle_path_pattern = "res://assets/demo/nurikabe/puzzles/%s.txt"
			var new_puzzle_path: String = puzzle_path_pattern % [command.substr(1)]
			if not FileAccess.file_exists(new_puzzle_path):
				_show_message("File not found: %s" % [new_puzzle_path])
				return
			load_puzzle(new_puzzle_path)
			_performance_test_start_index = _puzzle_paths.find(puzzle_path)
		_:
			_show_message("Invalid command: %s" % [command.substr(1)])
