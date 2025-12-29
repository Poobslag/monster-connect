extends Node
## [b]Keys:[/b][br]
## 	[kbd]G[/kbd]: Benchmark global_reachability_map for janko puzzles 1-50.
## 	[kbd]T[/kbd]: Benchmark island_reachability_map for janko puzzles 1-50.

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

var solver_board: SolverBoard

func _input(event: InputEvent) -> void:
	if %CommandPalette.has_focus():
		return
	
	match Utils.key_press(event):
		KEY_G:
			benchmark("get_global_reachability_map")
		KEY_T:
			benchmark("get_island_reachability_map")


func benchmark(method: String, arg_array: Array[Variant] = []) -> void:
	var duration: int = 0
	var start_path: String = %PuzzleArchive.from_source(PuzzleArchive.JANKO, "1")
	var puzzle_index: int = %PuzzleArchive.find(start_path)
	for _i in 50:
		load_puzzle(%PuzzleArchive.puzzle_path_at(puzzle_index))
		var start: int = Time.get_ticks_usec()
		solver_board.callv(method, arg_array)
		duration += Time.get_ticks_usec() - start
		puzzle_index = (puzzle_index + 1) % %PuzzleArchive.size()
	%DemoLog.log_message("%s: %s ms" % [method, duration / 1000.0])


func load_puzzle(new_puzzle_path: String) -> void:
	puzzle_path = new_puzzle_path
	if solver_board:
		solver_board.cleanup()
	solver_board = %GameBoard.to_solver_board()


func _refresh_puzzle_path() -> void:
	if not is_inside_tree():
		return
	
	%GameBoard.grid_string = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	%GameBoard.import_grid()
