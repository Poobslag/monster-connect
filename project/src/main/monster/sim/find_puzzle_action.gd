class_name FindPuzzleAction
extends GoapAction

const PUZZLE_APPROACH: float = 80.0

var target_game_board: NurikabeGameBoard

func exit(_actor: Variant) -> void:
	target_game_board = null


func perform(actor: Variant, _delta: float) -> bool:
	var finished: bool = false
	var monster: SimMonster = actor
	
	# find the nearest game board
	if target_game_board == null:
		var game_boards: Array[Node] = get_tree().get_nodes_in_group("game_boards")
		game_boards = game_boards.filter(func(a: Node) -> bool:
			return not a.is_finished())
		if game_boards:
			game_boards.sort_custom(func(a: Node, b: Node) -> bool:
				return a.get_rect().get_center().distance_to(monster.position) \
						< b.get_rect().get_center().distance_to(monster.position)
				)
			target_game_board = game_boards[0]
	
	# move towards the nearest game board; if we're close enough, assign it
	if target_game_board != null:
		monster.input.move_to(target_game_board.get_rect().get_center())
		if dist_to_rect(target_game_board.get_rect(), monster.position) < PUZZLE_APPROACH:
			monster.current_game_board = target_game_board
			target_game_board = null
			monster.input.dir = Vector2.ZERO
			finished = true
	
	return finished


static func dist_to_rect(rect: Rect2, point: Vector2) -> float:
	var result: float
	if rect.has_point(point):
		result = min(
			abs(point.x - rect.position.x),
			abs(point.y - rect.position.y),
			abs(point.x - rect.end.x),
			abs(point.y - rect.end.y),
		)
	else:
		result = point.clamp(rect.position, rect.end).distance_to(point)
	return result
