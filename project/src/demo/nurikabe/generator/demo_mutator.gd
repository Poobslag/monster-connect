@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd][Q][/kbd]: Mutate one step.
## 	[kbd][P][/kbd]: Print the best candidate.
## 	[kbd][-,=][/kbd]: Zoom out / in.

const CANDIDATE_SCALES: Array[float] = [1.0, 0.5, 0.33, 0.25]
const BOARD_SPACING: int = 20
const GAME_BOARD_SCENE: PackedScene = preload("res://src/main/nurikabe/game_board.tscn")
const DEMO_MUTATOR_LABEL_SCENE: PackedScene = preload("res://src/demo/nurikabe/generator/demo_mutator_label.tscn")
const LABEL_HEIGHT: float = 200

@export_file("*.txt") var puzzle_path: String:
	set(value):
		puzzle_path = value
		_refresh_puzzle_path()

@export_multiline var grid_string: String

var mutator: PuzzleMutator
var scale_index: int = 0

func _ready() -> void:
	var board: SolverBoard = SolverBoard.new()
	board.from_grid_string(grid_string)
	mutator = PuzzleMutator.new(board)
	board.cleanup()
	remove_all_children(%GameBoards)
	remove_all_children(%Labels)
	refresh_candidates()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			mutator.step()
			refresh_candidates()
		KEY_O:
			Utils.print_memory_stats()
		KEY_P:
			mutator.candidates[0].board.print_cells()
		KEY_MINUS:
			adjust_scale(1)
		KEY_EQUAL:
			adjust_scale(-1)


func adjust_scale(delta: int) -> void:
	scale_index = clampi(scale_index + delta, 0, CANDIDATE_SCALES.size() - 1)
	%GameBoards.scale = Vector2.ONE * CANDIDATE_SCALES[scale_index]
	%Labels.scale = %GameBoards.scale
	refresh_candidates()


func refresh_candidates() -> void:
	var next_game_board_position: Vector2 = Vector2i.ZERO
	var combined_rect: Rect2 = Rect2()
	for i in mutator.candidates.size():
		if i >= %GameBoards.get_child_count():
			%GameBoards.add_child(GAME_BOARD_SCENE.instantiate())
		if i >= %Labels.get_child_count():
			%Labels.add_child(DEMO_MUTATOR_LABEL_SCENE.instantiate())
		
		var game_board: NurikabeGameBoard = %GameBoards.get_child(i)
		var label: RichTextLabel = %Labels.get_child(i)
		
		mutator.candidates[i].board.update_game_board(game_board)
		game_board.position = next_game_board_position
		label.size.x = game_board.size.x
		label.position = game_board.position + Vector2(0, game_board.size.y)
		label.text = "fitness: %.1f" % [mutator.calculate_fitness(mutator.candidates[i])]
		next_game_board_position.x += game_board.size.x + BOARD_SPACING
		combined_rect = combined_rect.expand( \
				(game_board.position + game_board.size + Vector2(0, LABEL_HEIGHT)) * %GameBoards.scale)
	
	%Canvas.custom_minimum_size = combined_rect.size


func remove_all_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		child.queue_free()
		parent.remove_child(child)


func _refresh_puzzle_path() -> void:
	if not is_inside_tree():
		return
	
	grid_string = NurikabeUtils.load_grid_string_from_file(puzzle_path)
