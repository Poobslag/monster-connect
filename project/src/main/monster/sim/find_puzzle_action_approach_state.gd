extends FindPuzzleActionState
## Move towards the nearest game board; if we're close enough, assign it

const LOOKAHEAD_DISTANCE: float = 4.0

var _approach_zone: Rect2

func enter() -> void:
	var puzzle_aabb: AABB = action.target_game_board.get_global_aabb()
	_approach_zone = Rect2(puzzle_aabb.position.x, puzzle_aabb.position.z,
			puzzle_aabb.size.x, puzzle_aabb.size.z)
	_approach_zone = _approach_zone.grow_individual(
			FindPuzzleAction.PUZZLE_APPROACH,
			FindPuzzleAction.PUZZLE_APPROACH,
			FindPuzzleAction.PUZZLE_APPROACH,
			FindPuzzleAction.PUZZLE_APPROACH_BOTTOM)


func update(_delta: float) -> void:
	if action.target_game_board == null:
		change_state("seek")
	
	var monster_pos_2d: Vector2 = Vector2(monster.global_position.x, monster.global_position.z)
	
	# calculate the input direction
	var lookahead_target: Vector2 = _get_lookahead_target()
	var move_dir: Vector2 = _snap_to_8_directions(monster_pos_2d.direction_to(lookahead_target))
	monster.try_set_direction(move_dir)
	
	# truncate the target path
	var next_point: Vector2 = action.target_path.front()
	var to_next: Vector2 = next_point - monster_pos_2d
	if monster.input.dir.length() >= 0.1:
		while not action.target_path.is_empty() and to_next.dot(monster.input.dir) <= 0:
			action.target_path.pop_front()
			if not action.target_path.is_empty():
				next_point = action.target_path.front()
				to_next = next_point - monster_pos_2d
	
	# check if we reached the target
	if action.target_path.is_empty() or _approach_zone.has_point(monster_pos_2d):
		monster.solving_board = action.target_game_board
		action.target_game_board = null
		monster.try_set_direction(Vector2.ZERO)
		change_state("finished")


## Returns a point along the monster's path. This prevents their movement from being too robotic.
func _get_lookahead_target() -> Vector2:
	var remaining: float = LOOKAHEAD_DISTANCE
	var monster_pos_2d: Vector2 = Vector2(monster.global_position.x, monster.global_position.z)
	var prev: Vector2 = monster_pos_2d
	var result: Vector2 = prev
	for point: Vector2 in action.target_path:
		var segment_length: float = prev.distance_to(point)
		if remaining <= segment_length:
			result = prev.lerp(point, remaining / segment_length)
			break
		remaining -= segment_length
		prev = point
	return result


func _snap_to_8_directions(dir: Vector2) -> Vector2:
	return Vector2.from_angle(snappedf(dir.angle(), PI/4))
