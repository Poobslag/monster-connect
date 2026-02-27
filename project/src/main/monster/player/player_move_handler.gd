class_name PlayerMoveHandler
extends Node

const PUZZLE_APPROACH: float = 120.0

@onready var monster: PlayerMonster = Utils.find_parent_of_type(self, PlayerMonster)

func reset() -> void:
	monster.input.dir = Vector2.ZERO


func update() -> void:
	monster.input.dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if monster.solving_board:
		_detect_puzzle_exit()


func _detect_puzzle_exit() -> void:
	var puzzle_rect: Rect2 = monster.solving_board.get_global_cursorable_rect()
	var puzzle_dir: Vector2 = puzzle_rect.get_center() - monster.global_position
	if monster.input.dir.dot(puzzle_dir) < 0 \
			and _dist_to_rect(puzzle_rect, monster.global_position) > PUZZLE_APPROACH:
		monster.solving_board = null


static func _dist_to_rect(rect: Rect2, point: Vector2) -> float:
	var result: float
	if rect.has_point(point):
		result = 0.0
	else:
		result = point.clamp(rect.position, rect.end).distance_to(point)
	return result
