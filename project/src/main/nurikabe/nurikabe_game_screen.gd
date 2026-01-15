extends Control

const PUZZLE_DIR: String = "res://assets/main/nurikabe/official"

var _all_puzzles: Array[String] = Utils.find_data_files(PUZZLE_DIR, "txt")

func _ready() -> void:
	var puzzle_path: String = _all_puzzles.pick_random()
	var new_grid_string: String = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	%GameBoard.grid_string = new_grid_string
	%GameBoard.import_grid()
	%GameBoard.visible = true


func _import_random_puzzle() -> void:
	var puzzle_path: String = _all_puzzles.pick_random()
	var new_grid_string: String = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	
	if randf() < 0.5:
		new_grid_string = NurikabeUtils.mirror_grid_string(new_grid_string)
	new_grid_string = NurikabeUtils.rotate_grid_string(new_grid_string, randi_range(0, 3))
	
	%GameBoard.grid_string = new_grid_string
	%GameBoard.import_grid()


func _on_results_overlay_next_level_button_pressed() -> void:
	_import_random_puzzle()
