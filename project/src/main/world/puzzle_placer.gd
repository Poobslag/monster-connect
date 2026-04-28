class_name PuzzlePlacer
extends Node

## Force all puzzles to use the same fixed path. Useful for debugging.
@export_file("*.txt") var test_puzzle_path: String

var _all_puzzles: Array[String] = Utils.find_data_files(NurikabeUtils.PUZZLE_DIR, "info")
var _puzzle_queue: Array[String] = []

## Pairs puzzle spawns with random puzzles, matching largest puzzles to largest spawns.
func calculate_puzzle_placements() -> Array[PuzzlePlacement]:
	var result: Array[PuzzlePlacement] = []
	
	# find all puzzle spawns
	var puzzle_spawns: Array[PuzzleSpawn] = []
	puzzle_spawns.append_array(get_tree().get_nodes_in_group("puzzle_spawns"))
	
	# generate a list of puzzle infos for each spawn
	var puzzle_infos: Array[PuzzleInfo] = []
	for _i in puzzle_spawns.size():
		puzzle_infos.append(_next_puzzle_info())
	
	# sort both lists on size (largest first)
	puzzle_spawns.shuffle()
	puzzle_spawns.sort_custom(func(a: PuzzleSpawn, b: PuzzleSpawn) -> bool:
		return a.max_puzzle_size.x * a.max_puzzle_size.y > b.max_puzzle_size.x * b.max_puzzle_size.y)
	_sort_puzzle_infos_largest_first(puzzle_infos)
	
	for _mercy in 50:
		if  puzzle_infos.is_empty():
			# all puzzles added
			break
		
		# pop the largest remaining puzzle
		var next_info: PuzzleInfo = puzzle_infos.pop_front()
		var next_spawn: PuzzleSpawn = puzzle_spawns.front()
		
		# does the puzzle fit in the largest remaining spawn?
		var valid_rotations: Array[int] = []
		if next_info.size.x <= next_spawn.max_puzzle_size.x and next_info.size.y <= next_spawn.max_puzzle_size.y:
			valid_rotations.append(0)
			valid_rotations.append(2)
		if next_info.size.x <= next_spawn.max_puzzle_size.y and next_info.size.y <= next_spawn.max_puzzle_size.x:
			valid_rotations.append(1)
			valid_rotations.append(3)
		if valid_rotations.is_empty():
			# the puzzle doesn't fit. discard it, add the next random puzzle, sort the list again
			puzzle_infos.append(_next_puzzle_info())
			_sort_puzzle_infos_largest_first(puzzle_infos)
			continue
		
		# assign 'mirrored', 'rotation_turns' and add the puzzle placement
		puzzle_spawns.pop_front()
		var puzzle_placement: PuzzlePlacement = PuzzlePlacement.new()
		puzzle_placement.info = next_info
		puzzle_placement.spawn = next_spawn
		puzzle_placement.mirrored = randf() < 0.5
		puzzle_placement.rotation_turns = valid_rotations.pick_random()
		result.append(puzzle_placement)
	
	return result


func _sort_puzzle_infos_largest_first(puzzle_infos: Array[PuzzleInfo]) -> void:
	puzzle_infos.shuffle()
	puzzle_infos.sort_custom(func(a: PuzzleInfo, b: PuzzleInfo) -> bool:
		return a.size.x * a.size.y > b.size.x * b.size.y)


func _existing_game_board_has_path(path: String) -> bool:
	var result: bool = false
	for existing_board: NurikabeGameBoard3D in _get_game_boards():
		if existing_board.info.path == path:
			result = true
			break
	return result


func _get_game_boards() -> Array[NurikabeGameBoard3D]:
	var result: Array[NurikabeGameBoard3D] = []
	result.assign(%GameBoards.get_children().filter(
		func(node: Node) -> bool:
			return node is NurikabeGameBoard3D and not node.is_queued_for_deletion()))
	return result


func _next_puzzle_info() -> PuzzleInfo:
	var info: PuzzleInfo

	if test_puzzle_path:
		var info_path: String = NurikabeUtils.get_info_path(test_puzzle_path)
		var saver: PuzzleInfoSaver = PuzzleInfoSaver.new()
		info = saver.load_puzzle_info(info_path)
	
	for _mercy in 50:
		if _puzzle_queue.is_empty():
			_puzzle_queue = _all_puzzles.duplicate()
			_puzzle_queue.shuffle()
		var info_path: String = _puzzle_queue.pop_front()
		var puzzle_path: String = NurikabeUtils.get_puzzle_path(info_path)
		if not _existing_game_board_has_path(puzzle_path):
			var saver: PuzzleInfoSaver = PuzzleInfoSaver.new()
			info = saver.load_puzzle_info(info_path)
			break
	
	return info
