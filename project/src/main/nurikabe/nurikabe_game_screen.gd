extends Control

const DEFAULT_SKIN_VALUES: Array[Monster.MonsterSkin] = [
	Monster.MonsterSkin.BEIGE,
	Monster.MonsterSkin.GREEN,
	Monster.MonsterSkin.PINK,
	Monster.MonsterSkin.PURPLE,
	Monster.MonsterSkin.YELLOW,
]

const GAME_BOARD_SCENE: PackedScene = preload("res://src/main/nurikabe/nurikabe_game_board.tscn")
const SIM_SCENE: PackedScene = preload("res://src/main/monster/sim/sim_monster.tscn")

@export var target_sim_count: int = 1
@export var show_puzzle_ids: bool = false

## Force a specific sim to show up. Useful for debugging.
@export_file("*.txt") var test_sim_path: String

func _ready() -> void:
	_clear_sims()
	_refresh_sims()
	%GameBoards.clear_game_boards()
	_refresh_game_boards()
	
	%TutorialOverlay.show_tutorial()


func _input(event: InputEvent) -> void:
	if Utils.key_press(event) == KEY_SLASH:
		%CommandPalette.open()
	elif event.is_action_pressed("tutorial"):
		if %ResultsOverlay.visible:
			%ResultsOverlay.hide_results()
		if %TutorialOverlay.visible:
			%TutorialOverlay.hide_tutorial()
		else:
			%TutorialOverlay.show_tutorial()


func _enter_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _add_sim(sim_index: int) -> SimMonster:
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
	sim.position = %Player.position \
			+ 3.0 * Vector3.RIGHT.rotated(Vector3.UP, 2 * PI * (float(sim_index) / target_sim_count))
	%Monsters.add_child(sim)
	return sim


func _add_puzzle(placement: PuzzlePlacement) -> void:
	var game_board: NurikabeGameBoard3D = GAME_BOARD_SCENE.instantiate()
	
	_attach_puzzle_info(game_board, placement)
	_generate_board_label_text(game_board)
	_generate_board_string_id(game_board)
	_position_board_in_world(game_board, placement)


func _attach_puzzle_info(game_board: NurikabeGameBoard3D, placement: PuzzlePlacement) -> void:
	var new_grid_string: String = NurikabeUtils.load_grid_string_from_file(placement.info.path)
	
	game_board.info = placement.info
	game_board.set_meta("mirrored", placement.mirrored)
	if placement.mirrored:
		new_grid_string = NurikabeUtils.mirror_grid_string(new_grid_string)
	game_board.set_meta("rotation_turns", placement.rotation_turns)
	if placement.rotation_turns != 0:
		new_grid_string = NurikabeUtils.rotate_grid_string(new_grid_string, placement.rotation_turns)
	game_board.grid_string = new_grid_string
	game_board.import_grid()
	game_board.puzzle_finished.connect(_on_game_board_puzzle_finished.bind(game_board))
	
	game_board.hint_model = PuzzleHintModel.new(
			game_board.info,
			game_board.get_meta("mirrored", false),
			game_board.get_meta("rotation_turns", 0))


func _clear_sims() -> void:
	for sim: SimMonster in _get_sims():
		_remove_sim(sim)


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


func _generate_board_label_text(game_board: NurikabeGameBoard3D) -> void:
	if game_board.info == null:
		return
	if show_puzzle_ids:
		var puzzle_path: String = game_board.info.path
		game_board.label_text = "#%s - %s" % [
				puzzle_path.get_file().get_basename(),
				_difficulty_label(game_board.info.get("difficulty")),
			]
	else:
		game_board.label_text = _difficulty_label(game_board.info.get("difficulty"))


func _generate_board_string_id(game_board: NurikabeGameBoard3D) -> void:
	var clue_cell_values: Array[int] = []
	var clue_cells: Array[Vector2i] = game_board.get_clue_cells()
	var clue_cells_str: String
	for clue_cell: Vector2i in clue_cells:
		clue_cell_values.append(game_board.get_cell(clue_cell))
		if clue_cell_values.size() >= 3:
			break
	clue_cells_str = "-".join(clue_cell_values) if clue_cells else "0"
	
	var puzzle_path: String = game_board.info.path
	game_board.string_id = "%s-%sx%s-%s-%s" % [
		puzzle_path.get_file().get_basename(),
		game_board.puzzle_dimensions.x, game_board.puzzle_dimensions.y,
		game_board.label_text.to_lower().left(3),
		clue_cells_str,
	]


func _get_sims() -> Array[SimMonster]:
	var sims: Array[SimMonster] = []
	for monster: Monster in get_tree().get_nodes_in_group("monsters"):
		if monster is SimMonster and not monster.is_queued_for_deletion():
			sims.append(monster)
	return sims


func _position_board_in_world(game_board: NurikabeGameBoard3D, placement: PuzzlePlacement) -> void:
	%GameBoards.add_child(game_board)
	var game_board_aabb: AABB = game_board.get_global_aabb()
	game_board.global_position = placement.spawn.global_position.round() \
			- 0.5 * Vector3(game_board_aabb.size.x, 0, game_board_aabb.size.z)


func _refresh_game_boards() -> void:
	# remove all empty/solved puzzles
	for game_board: NurikabeGameBoard3D in %GameBoards.get_game_boards():
		if game_board.is_finished() or not game_board.is_started():
			%GameBoards.remove_game_board(game_board)
	
	var puzzle_placements: Array[PuzzlePlacement] = %PuzzlePlacer.calculate_puzzle_placements()
	for placement: PuzzlePlacement in puzzle_placements:
		_add_puzzle(placement)


func _refresh_sims() -> void:
	var sims: Array[SimMonster] = _get_sims()
	var new_sim_count: int = target_sim_count - sims.size()
	
	for _i in new_sim_count:
		var sim: SimMonster = _add_sim(sims.size())
		sims.append(sim)


func _remove_sim(sim: SimMonster) -> void:
	sim.queue_free()


func _on_refresher_refresh_requested() -> void:
	_refresh_game_boards()


func _on_game_board_puzzle_finished(game_board: NurikabeGameBoard3D) -> void:
	if game_board == %Player.solving_board and not %TutorialOverlay.visible:
		%ResultsOverlay.show_results()
	else:
		SoundManager.play_sfx_at_3d("win", game_board.get_global_aabb().get_center())


func _on_command_palette_command_entered(command: String) -> void:
	match command:
		"/ids":
			SoundManager.play_sfx("cheat_enabled")
			show_puzzle_ids = true
			for game_board: NurikabeGameBoard3D in %GameBoards.get_game_boards():
				_generate_board_label_text(game_board)
		"/noids":
			SoundManager.play_sfx("cheat_disabled")
			show_puzzle_ids = false
			for game_board: NurikabeGameBoard3D in %GameBoards.get_game_boards():
				_generate_board_label_text(game_board)
