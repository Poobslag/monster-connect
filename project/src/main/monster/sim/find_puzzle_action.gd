class_name FindPuzzleAction
extends GoapAction

const FIND_TARGET_COOLDOWN: float = 3.0
const PUZZLE_APPROACH: float = 1.25
const PUZZLE_APPROACH_BOTTOM: float = 2.25

const DESIRED_SIZE_MIN: float = 40.0
const DESIRED_SIZE_MAX: float = 600.0
const DESIRED_SIZE_AVG: float = 150.0

const DESIRED_DIFFICULTY_MIN: float = 0.0
const DESIRED_DIFFICULTY_MAX: float = 12.0
const DESIRED_DIFFICULTY_AVG: float = 4.0

const DIFFICULTY_WEIGHT_MIN: float = 0.0
const DIFFICULTY_WEIGHT_MAX: float = 20.0
const DIFFICULTY_WEIGHT_AVG: float = 5.0

const SIZE_WEIGHT_MIN: float = 0.0
const SIZE_WEIGHT_MAX: float = 20.0
const SIZE_WEIGHT_AVG: float = 5.0

@export var verbose: bool = false

var target_game_board: NurikabeGameBoard3D
var target_path: Array[Vector2] = []

var _distance_weight: float = 5.0
var _desired_difficulty: float = 0.0
var _difficulty_weight: float = 5.0
var _desired_size: float = 0.0
var _size_weight: float = 5.0

@onready var monster: SimMonster = Utils.find_parent_of_type(self, SimMonster)
@onready var ground_map: GroundMap = get_tree().get_first_node_in_group("ground_maps")

func _ready() -> void:
	# wait for monster.behavior
	await get_tree().process_frame
	
	_desired_difficulty = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_DIFFICULTY_PREFERENCE,
			DESIRED_DIFFICULTY_MIN, DESIRED_DIFFICULTY_MAX, DESIRED_DIFFICULTY_AVG)
	_difficulty_weight = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_PICKINESS,
			DIFFICULTY_WEIGHT_MIN, DIFFICULTY_WEIGHT_MAX, DIFFICULTY_WEIGHT_AVG)
	
	_desired_size = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_SIZE_PREFERENCE, DESIRED_SIZE_MIN, DESIRED_SIZE_MAX, DESIRED_SIZE_AVG)
	_size_weight = monster.behavior.lerp_stat(
			SimBehavior.PUZZLE_PICKINESS,
			SIZE_WEIGHT_MIN, SIZE_WEIGHT_MAX, SIZE_WEIGHT_AVG)


func enter() -> void:
	%FSM.change_state("seek")


func perform(delta: float) -> bool:
	%FSM.update(delta)
	return %FSM.current_state == "finished"


## Assigns [member target_game_board] and [member target_path] based on the Sim's preferences.[br]
## [br]
## If sims are picky, they'll travel far to find a puzzle they like. If they're not picky, they'll pick the closest
## puzzle.
func find_target() -> void:
	# find all the game boards
	var game_boards: Array[Node] = get_tree().get_nodes_in_group("game_boards")
	game_boards = game_boards.filter(func(a: Node) -> bool:
		return not a.is_finished() and a.error_cells.is_empty())
	
	# calculate a match score for each candidate
	var wrapped_candidates: Array[Dictionary] = []
	
	if verbose:
		print("Find puzzle: %s wants a puzzle of size=%0.2f, difficulty=%0.2f" \
				% [monster.display_name, _desired_size, _desired_difficulty])
	
	for game_board: NurikabeGameBoard3D in game_boards:
		var candidate: Dictionary[String, Variant] = {}
		candidate["board"] = game_board
		candidate["score"] = 0.0
		
		var distance: float = game_board.get_global_aabb().get_center().distance_to(monster.position)
		distance += randf_range(0, 7.8)
		var distance_match: float = _calculate_match_factor(distance, 15.6)
		candidate["score"] += distance_match * _distance_weight
		
		var difficulty: float = clamp(game_board.info.difficulty, 0, 12.0)
		var difficulty_match: float = _calculate_match_factor(_desired_difficulty - difficulty, 3.0)
		candidate["score"] += difficulty_match * _difficulty_weight
		
		var size: float = clamp(game_board.info.size.x * game_board.info.size.y, DESIRED_SIZE_MIN, DESIRED_SIZE_MAX)
		var size_match: float = _calculate_match_factor(_desired_size - size, _desired_size * 0.5)
		candidate["score"] += size_match * _size_weight
		
		if verbose:
			print("  %s=%s: (%.2f * %.2f) + (%2.2f * %.2f) + (%.2f * %.2f)" % [ \
					game_board.string_id, candidate["score"],
					distance_match, _distance_weight,
					difficulty_match, _difficulty_weight,
					size_match, _size_weight,
				])
		wrapped_candidates.append(candidate)
	
	# assign the game board with the highest match score
	if wrapped_candidates:
		wrapped_candidates.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
			return a["score"] > b["score"])
		var candidate: Dictionary[String, Variant] = wrapped_candidates[0]
		if verbose:
			print("Monster %s chose: %s; score=%.2f" \
					% [monster.display_name, candidate["board"].string_id,
				candidate["score"]])
		target_game_board = candidate["board"]
		
		# generate point path with a-star
		var puzzle_aabb: AABB = target_game_board.get_global_aabb()
		var puzzle_center: Vector3 = puzzle_aabb.get_center()
		var monster_pos_2d: Vector2 = Vector2(monster.global_position.x, monster.global_position.z)
		target_path.assign(ground_map.get_point_path(monster_pos_2d, Vector2(puzzle_center.x, puzzle_center.z)))


static func _calculate_match_factor(distance: float, tolerance: float) -> float:
	return exp((-distance * distance) / (2.0 * tolerance * tolerance))
