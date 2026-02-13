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

const DEFAULT_SKIN_VALUES: Array[Monster.MonsterSkin] = [
	Monster.MonsterSkin.BEIGE,
	Monster.MonsterSkin.GREEN,
	Monster.MonsterSkin.PINK,
	Monster.MonsterSkin.PURPLE,
	Monster.MonsterSkin.YELLOW,
]

const GAME_BOARD_SCENE: PackedScene = preload("res://src/main/nurikabe/game_board.tscn")
const SIM_SCENE: PackedScene = preload("res://src/main/monster/sim/sim_monster.tscn")
const PUZZLE_DIR: String = "res://assets/main/nurikabe/official"

@export var target_sim_count: int = 1
@export var target_puzzle_count: int = 7
@export var draw_debug_paths: bool = false
@export var show_puzzle_ids: bool = false

## Force all puzzles to use the same fixed path. Useful for debugging.
@export_file("*.txt") var test_puzzle_path: String

## Force a specific sim to show up. Useful for debugging.
@export_file("*.txt") var test_sim_path: String

var _all_puzzles: Array[String] = Utils.find_data_files(PUZZLE_DIR, "txt")
var _puzzle_queue: Array[String] = []

var _debug_paths: Array[Array] = []

func _ready() -> void:
	clear_sims()
	refresh_sims()
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


func _input(event: InputEvent) -> void:
	if Utils.key_press(event) == KEY_SLASH:
		%CommandPalette.open()


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
	var new_puzzle_count: int = target_puzzle_count - get_game_boards().size()
	for _i: int in new_puzzle_count:
		add_random_puzzle()


func add_random_puzzle() -> void:
	var puzzle_path: String = test_puzzle_path if test_puzzle_path else _next_puzzle_path()
	var game_board: NurikabeGameBoard = GAME_BOARD_SCENE.instantiate()
	
	_attach_puzzle_info(game_board, puzzle_path)
	_generate_board_label_text(game_board)
	_generate_board_string_id(game_board)
	_position_board_in_world(game_board)


func clear_sims() -> void:
	for sim: SimMonster in get_sims():
		remove_sim(sim)


func get_sims() -> Array[SimMonster]:
	var sims: Array[SimMonster] = []
	for monster: Monster in get_tree().get_nodes_in_group("monsters"):
		if monster is SimMonster and not monster.is_queued_for_deletion():
			sims.append(monster)
	return sims


func remove_sim(sim: SimMonster) -> void:
	sim.queue_free()


func refresh_sims() -> void:
	var sims: Array[SimMonster] = get_sims()
	var new_sim_count: int = target_sim_count - sims.size()
	
	for _i in new_sim_count:
		var sim: SimMonster = add_sim(sims.size())
		sims.append(sim)


func add_sim(sim_index: int) -> SimMonster:
	var sim: SimMonster = SIM_SCENE.instantiate()
	var profile: SimProfile
	if test_sim_path:
		profile = SimLibrary.get_profile(test_sim_path)
	else:
		profile = SimLibrary.get_next_profile()
	if profile.skin == SimMonster.MonsterSkin.NONE:
		sim.skin = DEFAULT_SKIN_VALUES[sim_index % DEFAULT_SKIN_VALUES.size()]
	else:
		sim.skin = profile.skin
	sim.behavior = profile.behavior
	sim.display_name = profile.name
	sim.position = Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000))
	add_child(sim)
	return sim


func _attach_puzzle_info(game_board: NurikabeGameBoard, puzzle_path: String) -> void:
	var new_grid_string: String = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	
	if not test_puzzle_path:
		var mirrored: bool = randf() < 0.5
		if mirrored:
			new_grid_string = NurikabeUtils.mirror_grid_string(new_grid_string)
		game_board.set_meta("mirrored", mirrored)
		var rotated_turns: int = randi_range(0, 3)
		game_board.set_meta("rotation_turns", rotated_turns)
		new_grid_string = NurikabeUtils.rotate_grid_string(new_grid_string, rotated_turns)
	
	game_board.grid_string = new_grid_string
	game_board.import_grid()
	game_board.puzzle_finished.connect(_on_game_board_puzzle_finished.bind(game_board))
	game_board.set_meta("puzzle_path", puzzle_path)
	
	var info_path: String = puzzle_path + ".info"
	if FileAccess.file_exists(info_path):
		var saver: PuzzleInfoSaver = PuzzleInfoSaver.new()
		game_board.info = saver.load_puzzle_info(puzzle_path + ".info")
	
	if game_board.info != null:
		game_board.hint_model = PuzzleHintModel.new(
				game_board.info,
				game_board.get_meta("mirrored", false),
				game_board.get_meta("rotation_turns", 0))


func _generate_board_label_text(game_board: NurikabeGameBoard) -> void:
	if game_board.info == null:
		return
	if show_puzzle_ids:
		var puzzle_path: String = game_board.get_meta("puzzle_path")
		game_board.label_text = "#%s - %s" % [
				puzzle_path.get_file().get_basename(),
				_difficulty_label(game_board.info.get("difficulty")),
			]
	else:
		game_board.label_text = _difficulty_label(game_board.info.get("difficulty"))


func _generate_board_string_id(game_board: NurikabeGameBoard) -> void:
	var clue_cell_values: Array[int] = []
	var clue_cells: Array[Vector2i] = game_board.get_clue_cells()
	var clue_cells_str: String
	for clue_cell: Vector2i in clue_cells:
		clue_cell_values.append(game_board.get_cell(clue_cell))
		if clue_cell_values.size() >= 3:
			break
	clue_cells_str = "-".join(clue_cell_values) if clue_cells else "0"
	
	var puzzle_path: String = game_board.get_meta("puzzle_path")
	game_board.string_id = "%s-%sx%s-%s-%s" % [
		puzzle_path.get_file().get_basename(),
		game_board.puzzle_dimensions.x, game_board.puzzle_dimensions.y,
		game_board.label_text.to_lower().left(3),
		clue_cells_str,
	]


func _position_board_in_world(game_board: NurikabeGameBoard) -> void:
	var debug_path: Array[Vector2] = []
	
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


func _on_game_board_puzzle_finished(game_board: NurikabeGameBoard) -> void:
	if game_board == %Player.solving_board:
		%ResultsOverlay.show_results()
	else:
		SoundManager.play_sfx_at("win", game_board.get_global_rect().get_center())


func _on_command_palette_command_entered(command: String) -> void:
	match command:
		"/ids":
			SoundManager.play_sfx("cheat_enabled")
			show_puzzle_ids = true
			for game_board: NurikabeGameBoard in get_game_boards():
				_generate_board_label_text(game_board)
		"/noids":
			SoundManager.play_sfx("cheat_disabled")
			show_puzzle_ids = false
			for game_board: NurikabeGameBoard in get_game_boards():
				_generate_board_label_text(game_board)
