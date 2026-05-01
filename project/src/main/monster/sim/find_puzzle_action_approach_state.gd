extends FindPuzzleActionState
## Move towards the nearest game board.

const LOOKAHEAD_DISTANCE: float = 4.0
const OBSTACLE_DETECTION_DISTANCE: float = 1.0

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
	
	# check for obstacles
	var from: Vector3 = monster.position + Vector3.UP * Monster.OBSTACLE_HEIGHT
	var to: Vector3 = from + Vector3(move_dir.x, 0, move_dir.y) * OBSTACLE_DETECTION_DISTANCE
	var obstacle_hit: Dictionary[String, Variant] = _execute_raycast(from, to)
	if obstacle_hit:
		var side: float = 1.0 if randf() < 0.5 else -1.0
		monster.try_set_direction(move_dir.rotated(side * PI / 2))
		change_state("detour")
	else:
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
			change_state("finished")


func _execute_raycast(from: Vector3, to: Vector3) -> Dictionary[String, Variant]:
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0b00000000_00000000_00000000_00000011
	var query_result: Dictionary[String, Variant] = {}
	query_result.assign(space.intersect_ray(query))
	return query_result


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
