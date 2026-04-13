@tool
extends Node
## [b]Keys:[/b][br]
## 	[kbd][Q][/kbd]: Mutate one step.[br]
## 	[kbd][P][/kbd]: Print the best candidate.[br]
## 	[kbd]Mouse[/kbd]: Middle-drag to pan, scroll to zoom.[br]

const CANDIDATE_SCALES: Array[float] = [1.0, 0.5, 0.33, 0.25]
const BOARD_SPACING: float = 0.5
const GAME_BOARD_SCENE: PackedScene = preload("res://src/main/nurikabe_3d/nurikabe_game_board_3d.tscn")
const DEMO_MUTATOR_LABEL_SCENE: PackedScene \
		= preload("res://src/demo/nurikabe_3d/generator/demo_mutator_label_3d.tscn")
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
	var next_game_board_position: Vector3 = Vector3.ZERO
	var combined_aabb: AABB = AABB()
	for i in mutator.candidates.size():
		if i >= %GameBoards.get_child_count():
			%GameBoards.add_child(GAME_BOARD_SCENE.instantiate())
		if i >= %Labels.get_child_count():
			%Labels.add_child(DEMO_MUTATOR_LABEL_SCENE.instantiate())
		
		var game_board: NurikabeGameBoard3D = %GameBoards.get_child(i)
		var label: Label3D = %Labels.get_child(i)
		
		mutator.candidates[i].board.update_game_board_3d(game_board)
		game_board.position = next_game_board_position
		var game_board_aabb: AABB = game_board.get_global_aabb()
		label.position = game_board_aabb.position + Vector3(0, 0, game_board_aabb.size.z)
		label.text = "fitness: %.1f" % [mutator.calculate_fitness(mutator.candidates[i])]
		next_game_board_position.x += game_board_aabb.size.x + BOARD_SPACING
		combined_aabb = combined_aabb.expand( \
				(game_board_aabb.end + Vector3(0, LABEL_HEIGHT, 0)) * %GameBoards.scale)


func remove_all_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		child.queue_free()
		parent.remove_child(child)


func _refresh_puzzle_path() -> void:
	if not is_inside_tree():
		return
	
	grid_string = NurikabeUtils.load_grid_string_from_file(puzzle_path)
