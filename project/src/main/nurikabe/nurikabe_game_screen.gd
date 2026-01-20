extends Control

const DEBUG_COLORS: Array[Color] = [
	Color("#F7D046"), # yellow
	Color("#2E86FF"), # blue
	Color("#E74C3C"), # red
	Color("#8E44AD"), # purple
	Color("#F39C12"), # orange
	Color("#27AE60"), # green
	Color("#8E5A2A"), # brown
]

const GAME_BOARD_SCENE: PackedScene = preload("res://src/main/nurikabe/game_board.tscn")
const PUZZLE_DIR: String = "res://assets/main/nurikabe/official"
const TARGET_PUZZLE_COUNT: int = 7

@export var draw_debug_paths: bool = false

var _all_puzzles: Array[String] = Utils.find_data_files(PUZZLE_DIR, "txt")
var _puzzle_queue: Array[String] = []

var _debug_paths: Array[Array] = []

func _ready() -> void:
	clear_game_boards()
	refresh_game_boards()


func _draw() -> void:
	if not draw_debug_paths:
		return
	
	for i in _debug_paths.size():
		var color: Color = DEBUG_COLORS[i % DEBUG_COLORS.size()]
		for j in _debug_paths[i].size() - 1:
			var from: Vector2 = _debug_paths[i][j]
			var to: Vector2 = _debug_paths[i][j + 1]
			draw_line(from, to, color, 4.0)


func clear_game_boards() -> void:
	for game_board: NurikabeGameBoard in get_game_boards():
		remove_game_board(game_board)


func remove_game_board(game_board: NurikabeGameBoard) -> void:
	game_board.queue_free()


func get_game_boards() -> Array[NurikabeGameBoard]:
	var result: Array[NurikabeGameBoard] = []
	result.assign(%GameBoards.get_children().filter(
		func(node: Node) -> bool:
			return node is NurikabeGameBoard and not node.is_queued_for_deletion()))
	return result


func refresh_game_boards() -> void:
	_debug_paths.clear()
	
	# remove all empty/solved puzzles
	for game_board: NurikabeGameBoard in get_game_boards():
		if game_board.is_finished() or not game_board.is_started():
			remove_game_board(game_board)
	
	# add puzzles to reach the target puzzle count
	var new_puzzle_count: int = TARGET_PUZZLE_COUNT - get_game_boards().size()
	for _i: int in new_puzzle_count:
		add_random_puzzle()


func _load_puzzle_info(puzzle_path: String) -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	var info_text: String = FileAccess.get_file_as_string(puzzle_path + ".info")
	var test_json_conv: JSON = JSON.new()
	test_json_conv.parse(info_text)
	result.assign(test_json_conv.data)
	return result


func add_random_puzzle() -> void:
	var debug_path: Array[Vector2] = []
	
	var puzzle_path: String = _next_puzzle_path()
	var new_grid_string: String = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	
	if randf() < 0.5:
		new_grid_string = NurikabeUtils.mirror_grid_string(new_grid_string)
	new_grid_string = NurikabeUtils.rotate_grid_string(new_grid_string, randi_range(0, 3))
	
	var game_board: NurikabeGameBoard = GAME_BOARD_SCENE.instantiate()
	game_board.grid_string = new_grid_string
	game_board.import_grid()
	game_board.puzzle_finished.connect(%ResultsOverlay._on_game_board_puzzle_finished)
	game_board.set_meta("puzzle_path", puzzle_path)
	
	var new_info: Dictionary[String, Variant] = _load_puzzle_info(puzzle_path)
	if new_info.has("difficulty"):
		game_board.set_meta("difficulty", new_info.get("difficulty"))
		game_board.label_text = _difficulty_label(new_info.get("difficulty"))
	
	%GameBoards.add_child(game_board)
	
	var angle: float = randf_range(0, 2 * PI)
	var dist: float = randf_range(0, 50)
	for _mercy in 100:
		game_board.position = Vector2.RIGHT.rotated(angle) * dist
		debug_path.append(game_board.position)
		if not _overlaps_world_occupants(game_board):
			break
		angle = fmod(angle + 0.2, 2 * PI)
		dist = dist * 1.10 + 100
	
	_debug_paths.append(debug_path)
	queue_redraw()


func _difficulty_label(score: float) -> String:
	var result: String = ""
	if score < 2:
		result = "Easy"
	elif score < 5:
		result = "Medium"
	elif score < 8:
		result = "Hard"
	else:
		result = "Expert"
	return result


func _existing_game_board_has_path(path: String) -> bool:
	var result: bool = false
	for existing_board: NurikabeGameBoard in get_game_boards():
		if existing_board.get_meta("puzzle_path") == path:
			result = true
			break
	return result


func _next_puzzle_path() ->  String:
	var puzzle_path: String
	
	for _mercy in 50:
		if _puzzle_queue.is_empty():
			_puzzle_queue = _all_puzzles.duplicate()
			_puzzle_queue.shuffle()
		puzzle_path = _puzzle_queue.pop_front()
		if not _existing_game_board_has_path(puzzle_path):
			break
	
	return puzzle_path


func _overlaps_world_occupants(new_board: NurikabeGameBoard) -> bool:
	var result: bool = false
	for occupant: Control in Utils.get_subtree_members(self, "world_occupants"):
		if occupant.is_queued_for_deletion():
			continue
		if occupant == new_board:
			continue
		if occupant.get_rect().grow(50).intersects(new_board.get_rect().grow(50)):
			result = true
			break
	return result


func _on_refresher_refresh_requested() -> void:
	refresh_game_boards()
