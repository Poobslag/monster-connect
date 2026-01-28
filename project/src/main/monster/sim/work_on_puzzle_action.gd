class_name WorkOnPuzzleAction
extends GoapAction

const SOLVER_COOLDOWN: float = 3.0

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var _next_deduction: Deduction
var _next_deduction_remaining_time: float = 0.0

var _solver_cooldown_remaining: float = 0.0

@onready var _solver: NaiveSolver = NaiveSolver.find_instance(self)

func perform(actor: Variant, delta: float) -> bool:
	if _solver_cooldown_remaining > 0.0:
		_solver_cooldown_remaining -= delta
	
	var monster: SimMonster = actor
	if monster.pending_deductions.is_empty():
		if _solver_cooldown_remaining <= 0 and not _solver.is_move_requested(monster):
			# queue up the next deduction finder
			_solver.request_move(monster)
			_solver_cooldown_remaining = SOLVER_COOLDOWN
	
	if _next_deduction == null and not monster.pending_deductions.is_empty():
		_choose_deduction(monster)
		if _next_deduction != null:
			_next_deduction_remaining_time = 0.6
	
	if _next_deduction != null:
		_next_deduction_remaining_time -= delta
		if _next_deduction_remaining_time <= 0:
			monster.input.queue_cursor_command(
					SimInput.LMB_PRESS, monster.game_board.map_to_global(_next_deduction.pos))
			monster.input.queue_cursor_command(
					SimInput.LMB_RELEASE, monster.game_board.map_to_global(_next_deduction.pos), 0.1)
			_next_deduction = null
	
	return monster.game_board.is_finished()


func exit(actor: Variant) -> void:
	var monster: SimMonster = actor
	
	_solver.cancel_request(monster)
	_next_deduction = null
	_next_deduction_remaining_time = 0.0
	_solver_cooldown_remaining = 0.0
	
	monster.pending_deductions.clear()


func _choose_deduction(monster: SimMonster) -> void:
	var best_score: float = 0.0
	for deduction: Deduction in monster.pending_deductions.values():
		if monster.game_board.get_cell(deduction.pos) != CELL_EMPTY:
			monster.remove_pending_deduction_at(deduction.pos)
			continue
		
		var score: float = _score_deduction(monster, deduction)
		if score > best_score:
			_next_deduction = deduction
			best_score = score
	if _next_deduction:
		monster.remove_pending_deduction_at(_next_deduction.pos)


func _score_deduction(monster: SimMonster, deduction: Deduction) -> float:
	# some deductions score negative; these represent deductions which are too close to the player cursor
	var score: float = 0.0
	
	var deduction_global_pos: Vector2 = monster.game_board.map_to_global(deduction.pos)
	var cursor_dist: float = monster.cursor.global_position.distance_to(deduction_global_pos)
	score += 10.0 * _score_distance(cursor_dist, 300)
	for other_monster: Monster in get_tree().get_nodes_in_group("monsters"):
		if other_monster == monster:
			continue
		if other_monster.game_board != monster.game_board:
			continue
		var other_cursor_dist: float = other_monster.cursor.global_position.distance_to(deduction_global_pos)
		score -= 20.0 * _score_distance(other_cursor_dist, 150)
	return score


func _score_distance(distance: float, factor: float) -> float:
	return exp(-distance / factor)
