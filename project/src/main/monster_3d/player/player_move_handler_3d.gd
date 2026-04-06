class_name PlayerMoveHandler3D
extends Node

const PUZZLE_APPROACH: float = 1.875

@onready var monster: PlayerMonster3D = Utils.find_parent_of_type(self, PlayerMonster3D)

func reset() -> void:
	monster.input.dir = Vector2.ZERO


func update() -> void:
	monster.input.dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if monster.solving_board:
		_detect_puzzle_exit()


func _detect_puzzle_exit() -> void:
	var puzzle_aabb: AABB = monster.solving_board.get_aabb()
	var puzzle_rect: Rect2 = Rect2(puzzle_aabb.position.x, puzzle_aabb.position.z,
			puzzle_aabb.size.x, puzzle_aabb.size.z)
	var monster_pos_2d: Vector2 = Vector2(monster.global_position.x, monster.global_position.z)
	var puzzle_dir: Vector2 = puzzle_rect.get_center() - monster_pos_2d
	if monster.input.dir.dot(puzzle_dir) < 0 \
			and _dist_to_rect(puzzle_rect, monster_pos_2d) > PUZZLE_APPROACH:
		monster.solving_board = null


static func _dist_to_rect(rect: Rect2, point: Vector2) -> float:
	var result: float
	if rect.has_point(point):
		result = 0.0
	else:
		result = point.clamp(rect.position, rect.end).distance_to(point)
	return result
