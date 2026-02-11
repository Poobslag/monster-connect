class_name FindPuzzleAction
extends GoapAction

const FIND_TARGET_COOLDOWN: float = 3.0
const PUZZLE_APPROACH: float = 80.0

var target_game_board: NurikabeGameBoard
var find_target_cooldown_remaining: float = 0.0

@onready var monster: SimMonster = Utils.find_parent_of_type(self, SimMonster)

func enter() -> void:
	find_target_cooldown_remaining = randf_range(0, FIND_TARGET_COOLDOWN)


func exit() -> void:
	target_game_board = null


func perform(delta: float) -> bool:
	var finished: bool = false
	
	if find_target_cooldown_remaining > 0:
		find_target_cooldown_remaining -= delta
	
	# find the nearest game board
	if target_game_board == null and find_target_cooldown_remaining <= 0:
		find_target_cooldown_remaining = FIND_TARGET_COOLDOWN
		_find_target()
	
	# move towards the nearest game board; if we're close enough, assign it
	if target_game_board != null:
		monster.input.move_to(target_game_board.get_rect().get_center())
		if _dist_to_rect(target_game_board.get_rect(), monster.position) < PUZZLE_APPROACH:
			monster.solving_board = target_game_board
			target_game_board = null
			monster.input.dir = Vector2.ZERO
			finished = true
	
	return finished


## Sims choose the puzzle which best fits their preferences.[br]
## [br]
## If sims are picky, they'll travel far to find a puzzle they like. If they're not picky, they'll pick the closest
## puzzle.
func _find_target() -> void:
	# find all the game boards
	var game_boards: Array[Node] = get_tree().get_nodes_in_group("game_boards")
	game_boards = game_boards.filter(func(a: Node) -> bool:
		return not a.is_finished() and a.error_cells.is_empty())
	
	# calculate a match score for each candidate
	var wrapped_candidates: Array[Dictionary] = []
	var distance_weight: float = 5.0
	
	var desired_difficulty: float = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_DIFFICULTY_PREFERENCE, 0, 12.0, 4.0)
	var difficulty_weight: float = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_PICKINESS, 0, 20, 5)
	
	var desired_size: float = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_SIZE_PREFERENCE, 40.0, 600.0, 150.0)
	var size_weight: float = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_PICKINESS, 0, 20, 5)
	
	for game_board: NurikabeGameBoard in game_boards:
		var candidate: Dictionary[String, Variant] = {}
		candidate["board"] = game_board
		candidate["score"] = 0.0
		
		var distance: float = game_board.get_rect().get_center().distance_to(monster.position)
		distance += randf_range(0, 500)
		var distance_match: float = _calculate_match_factor(distance, 1000.0)
		candidate["score"] += distance_match * distance_weight
		
		var difficulty: float = clamp(game_board.info.difficulty, 0, 12.0)
		var difficulty_match: float = _calculate_match_factor(desired_difficulty - difficulty, 3.0)
		candidate["score"] += difficulty_match * difficulty_weight
		
		var size: float = clamp(game_board.info.size.x * game_board.info.size.y, 40.0, 600.0)
		var size_match: float = _calculate_match_factor(desired_size - size, desired_size * 0.5)
		candidate["score"] += size_match * size_weight
		
		wrapped_candidates.append(candidate)
	
	# assign the game board with the highest match score
	if wrapped_candidates:
		wrapped_candidates.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
			return a["score"] > b["score"])
		target_game_board = wrapped_candidates[0]["board"]


static func _calculate_match_factor(distance: float, tolerance: float) -> float:
	return exp((-distance * distance) / (2.0 * tolerance * tolerance))


static func _dist_to_rect(rect: Rect2, point: Vector2) -> float:
	var result: float
	if rect.has_point(point):
		result = 0.0
	else:
		result = point.clamp(rect.position, rect.end).distance_to(point)
	return result
