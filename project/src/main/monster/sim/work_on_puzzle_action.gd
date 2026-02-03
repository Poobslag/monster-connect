class_name WorkOnPuzzleAction
extends GoapAction

const SOLVER_COOLDOWN: float = 3.0
const IDLE_COOLDOWN: float = 3.0

const UNKNOWN_REASON: Deduction.Reason = Deduction.Reason.UNKNOWN

## starting techniques
const ISLAND_OF_ONE: Deduction.Reason = Deduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Deduction.Reason = Deduction.Reason.ADJACENT_CLUES

## basic techniques
const CORNER_BUFFER: Deduction.Reason = Deduction.Reason.CORNER_BUFFER
const CORNER_ISLAND: Deduction.Reason = Deduction.Reason.CORNER_ISLAND
const ISLAND_BUBBLE: Deduction.Reason = Deduction.Reason.ISLAND_BUBBLE
const ISLAND_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_BUFFER
const ISLAND_CHAIN: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN
const ISLAND_CHAIN_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN_BUFFER
const ISLAND_CHOKEPOINT: Deduction.Reason = Deduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: Deduction.Reason = Deduction.Reason.ISLAND_CONNECTOR
const ISLAND_DIVIDER: Deduction.Reason = Deduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: Deduction.Reason = Deduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Deduction.Reason = Deduction.Reason.ISLAND_MOAT
const ISLAND_SNUG: Deduction.Reason = Deduction.Reason.ISLAND_SNUG
const POOL_CHOKEPOINT: Deduction.Reason = Deduction.Reason.POOL_CHOKEPOINT
const POOL_TRIPLET: Deduction.Reason = Deduction.Reason.POOL_TRIPLET
const UNCLUED_LIFELINE: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE
const UNCLUED_LIFELINE_BUFFER: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE_BUFFER
const UNREACHABLE_CELL: Deduction.Reason = Deduction.Reason.UNREACHABLE_CELL
const WALL_BUBBLE: Deduction.Reason = Deduction.Reason.WALL_BUBBLE
const WALL_CONNECTOR: Deduction.Reason = Deduction.Reason.WALL_CONNECTOR
const WALL_EXPANSION: Deduction.Reason = Deduction.Reason.WALL_EXPANSION
const WALL_WEAVER: Deduction.Reason = Deduction.Reason.WALL_WEAVER

## advanced techniques
const ASSUMPTION: Deduction.Reason = Deduction.Reason.ASSUMPTION
const BORDER_HUG: Deduction.Reason = Deduction.Reason.BORDER_HUG
const ISLAND_BATTLEGROUND: Deduction.Reason = Deduction.Reason.ISLAND_BATTLEGROUND
const ISLAND_RELEASE: Deduction.Reason = Deduction.Reason.ISLAND_RELEASE
const ISLAND_STRANGLE: Deduction.Reason = Deduction.Reason.ISLAND_STRANGLE
const WALL_STRANGLE: Deduction.Reason = Deduction.Reason.WALL_STRANGLE

const FUN_TRIVIAL: Deduction.FunAxis = Deduction.FunAxis.FUN_TRIVIAL
const FUN_FAST: Deduction.FunAxis = Deduction.FunAxis.FUN_FAST
const FUN_NOVELTY: Deduction.FunAxis = Deduction.FunAxis.FUN_NOVELTY
const FUN_THINK: Deduction.FunAxis = Deduction.FunAxis.FUN_THINK
const FUN_BIFURCATE: Deduction.FunAxis = Deduction.FunAxis.FUN_BIFURCATE

const DEDUCTION_DELAY_FOR_REASON: Dictionary[Deduction.Reason, float] = {
	UNKNOWN_REASON: 10.0,
	
	# starting techniques
	ISLAND_OF_ONE: 0.4,
	ADJACENT_CLUES: 0.4,
	
	# basic techniques
	CORNER_BUFFER: 1.2,
	CORNER_ISLAND: 1.2,
	ISLAND_BUBBLE: 1.2,
	ISLAND_BUFFER: 1.2,
	ISLAND_CHAIN: 1.2,
	ISLAND_CHAIN_BUFFER: 1.2,
	ISLAND_CHOKEPOINT: 1.2,
	ISLAND_CONNECTOR: 1.2,
	ISLAND_DIVIDER: 1.2,
	ISLAND_EXPANSION: 0.8,
	ISLAND_MOAT: 1.2,
	ISLAND_SNUG: 1.2,
	POOL_CHOKEPOINT: 1.2,
	POOL_TRIPLET: 0.8,
	UNCLUED_LIFELINE: 1.2,
	UNCLUED_LIFELINE_BUFFER: 1.2,
	UNREACHABLE_CELL: 1.2,
	WALL_BUBBLE: 1.2,
	WALL_CONNECTOR: 1.2,
	WALL_EXPANSION: 0.8,
	WALL_WEAVER: 1.2,
	
	# advanced techniques
	ASSUMPTION: 3.6,
	BORDER_HUG: 3.6,
	ISLAND_BATTLEGROUND: 3.6,
	ISLAND_RELEASE: 3.6,
	ISLAND_STRANGLE: 3.6,
	WALL_STRANGLE: 3.6,
}

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var _next_deduction: Deduction
var _next_deduction_remaining_time: float = 0.0
var _next_idle_remaining_time: float = randf_range(0, IDLE_COOLDOWN)

var _curr_deduction: Deduction

var _solver_cooldown_remaining: float = 0.0

var _cursor_commands_by_cell: Dictionary[Vector2i, Array] = {}

@onready var _solver: NaiveSolver = NaiveSolver.find_instance(self)

func enter(actor: Variant) -> void:
	var monster: SimMonster = actor
	monster.solving_board.cell_changed.connect(_on_solving_board_cell_changed.bind(monster))


func perform(actor: Variant, delta: float) -> bool:
	if _solver_cooldown_remaining > 0.0:
		_solver_cooldown_remaining -= delta
	
	var monster: SimMonster = actor
	if _solver_cooldown_remaining <= 0 and not _solver.is_move_requested(monster):
		# queue up the next deduction finder
		_solver.request_move(monster)
		_solver_cooldown_remaining = SOLVER_COOLDOWN
	
	if _next_deduction == null and not monster.pending_deductions.is_empty():
		_choose_deduction(monster)
		if _next_deduction != null:
			_next_deduction_remaining_time = DEDUCTION_DELAY_FOR_REASON.get(_next_deduction.reason, 0.6) \
					* randf_range(1.0, 1.5)
	
	if _next_deduction != null:
		_process_next_deduction(monster, delta)
	else:
		_process_idle_cursor(monster, delta)
	
	return monster.solving_board.is_finished()


func exit(actor: Variant) -> void:
	var monster: SimMonster = actor
	
	_solver.cancel_request(monster)
	_next_deduction = null
	_next_deduction_remaining_time = 0.0
	_solver_cooldown_remaining = 0.0
	
	monster.pending_deductions.clear()
	_cursor_commands_by_cell.clear()


func _choose_deduction(monster: SimMonster) -> void:
	# search near where cursor will end up after all queued cursor commands
	var search_center: Vector2i
	if not monster.input.cursor_commands.is_empty():
		search_center = monster.input.cursor_commands.back().pos
	else:
		search_center = monster.cursor.global_position
	
	var best_score: float = 0.0
	for deduction: Deduction in monster.pending_deductions.values():
		if monster.solving_board.get_cell(deduction.pos) != CELL_EMPTY:
			monster.remove_pending_deduction_at(deduction.pos)
			continue
		if _cursor_commands_by_cell.has(deduction.pos):
			monster.remove_pending_deduction_at(deduction.pos)
			continue
		
		var score: float = _score_deduction(monster, deduction, search_center)
		if score > best_score:
			_next_deduction = deduction
			best_score = score
	if _next_deduction:
		monster.remove_pending_deduction_at(_next_deduction.pos)


func _execute_curr_deduction(monster: SimMonster) -> void:
	if _solver.verbose:
		print("monster %s deduction: %s" % [monster.id, _curr_deduction])
	var target_pos: Vector2 = monster.solving_board.map_to_global(_curr_deduction.pos)
	var commands: Array[SimInput.CursorCommand] = []
	match _curr_deduction.value:
		CELL_WALL:
			commands.append(monster.input.queue_cursor_command(SimInput.LMB_PRESS, target_pos))
			commands.append(monster.input.queue_cursor_command(SimInput.LMB_RELEASE, target_pos, 0.1))
		CELL_ISLAND:
			commands.append(monster.input.queue_cursor_command(SimInput.RMB_PRESS, target_pos))
			commands.append(monster.input.queue_cursor_command(SimInput.RMB_RELEASE, target_pos, 0.1))
	_cursor_commands_by_cell[_curr_deduction.pos] = commands


func _process_next_deduction(monster: SimMonster, delta: float) -> void:
	if monster.solving_board.get_cell(_next_deduction.pos) == _next_deduction.value:
		_next_deduction = null
		return

	_next_deduction_remaining_time -= delta
	if _next_deduction_remaining_time <= 0:
		_curr_deduction = _next_deduction
		_next_deduction = null
		_execute_curr_deduction(monster)


func _process_idle_cursor(monster: SimMonster, delta: float) -> void:
	if not monster.input.cursor_commands.is_empty():
		return
	if _next_idle_remaining_time > 0:
		_next_idle_remaining_time -= delta
		return
	
	var board_rect: Rect2 = monster.solving_board.get_global_cursorable_rect()
	var pos: Vector2 = monster.cursor.global_position
	
	# move the cursor randomly, "bouncing off" the edge of the board
	var pos_delta: Vector2 = Vector2(randf_range(-60, 60), randf_range(-60, 60))
	if not board_rect.has_point(Vector2(pos.x, pos.y + pos_delta.y)):
		pos_delta.y *= -1
	if not board_rect.has_point(Vector2(pos.x + pos_delta.x, pos.y)):
		pos_delta.x *= -1
	
	pos = (pos + pos_delta).clamp(board_rect.position, board_rect.end)
	monster.input.queue_cursor_command(SimInput.MOVE, pos, 0.0, 0.33)
	_next_idle_remaining_time = IDLE_COOLDOWN


func _score_deduction(monster: SimMonster, deduction: Deduction, search_center: Vector2) -> float:
	# some deductions score negative; these represent deductions which are too close to the player cursor
	var score: float = 0.0
	
	var deduction_global_pos: Vector2 = monster.solving_board.map_to_global(deduction.pos)
	var cursor_dist: float = search_center.distance_to(deduction_global_pos)
	score += 10.0 * _score_distance(cursor_dist, 300)
	for other_monster: Monster in get_tree().get_nodes_in_group("monsters"):
		if other_monster == monster:
			continue
		if other_monster.cursor_board != monster.cursor_board:
			continue
		var other_cursor_dist: float = other_monster.cursor.global_position.distance_to(deduction_global_pos)
		score -= 20.0 * _score_distance(other_cursor_dist, 150)
	return score


func _score_distance(distance: float, factor: float) -> float:
	return exp(-distance / factor)


func _on_solving_board_cell_changed(cell_pos: Vector2i, _value: int, monster: SimMonster) -> void:
	if _cursor_commands_by_cell.has(cell_pos):
		var cursor_press_command: SimInput.CursorCommand = null
		for cursor_command: SimInput.CursorCommand in _cursor_commands_by_cell[cell_pos]:
			if cursor_command.action in [SimInput.LMB_PRESS, SimInput.RMB_PRESS] \
					and monster.input.has_cursor_command(cursor_command):
				cursor_press_command = cursor_command
				break
		if cursor_press_command != null:
			for cursor_command: SimInput.CursorCommand in _cursor_commands_by_cell[cell_pos]:
				monster.input.dequeue_cursor_command(cursor_command)
		
		_cursor_commands_by_cell.erase(cell_pos)
