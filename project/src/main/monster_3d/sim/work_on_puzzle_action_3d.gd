class_name WorkOnPuzzleAction3D
extends GoapAction

const SOLVER_COOLDOWN_MIN: float = 3.5
const SOLVER_COOLDOWN_AVG: float = 7.5
const SOLVER_COOLDOWN_MAX: float = 13.5

const CHOOSE_DEDUCTION_COOLDOWN: float = 0.5

const IDLE_COOLDOWN_MIN: float = 3.0
const IDLE_COOLDOWN_MAX: float = 6.0

const ADJACENT_DIRS: Array[Vector2i] = NurikabeUtils.ADJACENT_DIRS

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const RECENT_MODIFICATION_WINDOW: float = 1.0

const PATIENCE_DURATION_MIN: float = 18.0
const PATIENCE_DURATION_AVG: float = 45.0
const PATIENCE_DURATION_MAX: float = 180.0

const PATIENT_DISTANCE_RATIO_MIN: float = 0.30
const PATIENT_DISTANCE_RATIO_MAX: float = 0.50
const PATIENT_DISTANCE_RATIO_AVG: float = 0.45

var _board_size_factor: float
var _curr_deduction: Deduction
var _next_deduction: Deduction
var _next_deduction_remaining_time: float = 0.0
var _idle_cooldown_remaining: float
var _solver_cooldown_remaining: float = 0.0
var _choose_deduction_cooldown_remaining: float = 0.0
var _needs_fix: bool = false
var _impatience_timer: float = 0.0

var _cursor_commands_by_cell: Dictionary[Vector2i, Array] = {}
var _interested_cells: Dictionary[Vector2i, float] = {}

var _deduction_speed_factor: float = 0.0
var _idle_cooldown: float = IDLE_COOLDOWN_MIN
var _solver_cooldown: float = SOLVER_COOLDOWN_AVG
var _patience_duration: float = PATIENCE_DURATION_AVG

## Values > 0.5 risk deadlock, even the closest sim may refuse to work.
var _patient_distance_ratio: float = PATIENT_DISTANCE_RATIO_AVG

@onready var _solver: NaiveSolver3D = NaiveSolver3D.find_instance(self)
@onready var monster: SimMonster3D = Utils.find_parent_of_type(self, SimMonster3D)

func _ready() -> void:
	# wait for monster.behavior
	await get_tree().process_frame
	
	_solver_cooldown = monster.behavior.lerp_stat(SimBehavior.PUZZLE_THINK_SPEED,
			SOLVER_COOLDOWN_MIN, SOLVER_COOLDOWN_MAX, SOLVER_COOLDOWN_AVG)
	_deduction_speed_factor = monster.behavior.lerp_stat(SimBehavior.PUZZLE_THINK_SPEED,
			0.0, 1.0, 0.6)
	_idle_cooldown = monster.behavior.lerp_stat(SimBehavior.MOTIVATION,
			IDLE_COOLDOWN_MIN, IDLE_COOLDOWN_MAX)
	_patience_duration = monster.behavior.lerp_stat(SimBehavior.PUZZLE_CURSOR_COURTESY,
			PATIENCE_DURATION_MIN, PATIENCE_DURATION_MAX, PATIENCE_DURATION_AVG)
	_patient_distance_ratio = monster.behavior.lerp_stat(SimBehavior.PUZZLE_CURSOR_COURTESY,
			PATIENT_DISTANCE_RATIO_MIN, PATIENT_DISTANCE_RATIO_MAX, PATIENT_DISTANCE_RATIO_AVG)


func enter() -> void:
	monster.solving_board.cell_changed.connect(_on_solving_board_cell_changed)
	monster.solving_board.error_cells_changed.connect(_on_solving_board_error_cells_changed)
	monster.solving_board.board_reset.connect(_on_solving_board_reset)
	_board_size_factor = monster.solving_board.get_aabb().size.length() / 7.8
	_idle_cooldown_remaining = randf_range(0, _idle_cooldown)


func perform(delta: float) -> bool:
	var result: bool = false
	
	if _needs_fix:
		result = _perform_while_fixing(delta)
	else:
		result = _perform_normally(delta)
	return result


func exit() -> void:
	_solver.cancel_request(monster)
	
	if monster.solving_board != null:
		monster.solving_board.cell_changed.disconnect(_on_solving_board_cell_changed)
		monster.solving_board.error_cells_changed.disconnect(_on_solving_board_error_cells_changed)
		monster.solving_board.board_reset.disconnect(_on_solving_board_reset)
	
	_curr_deduction = null
	_next_deduction = null
	_next_deduction_remaining_time = 0.0
	_idle_cooldown_remaining = 0.0
	_solver_cooldown_remaining = 0.0
	_needs_fix = false
	
	monster.pending_deductions.clear()
	_cursor_commands_by_cell.clear()
	_interested_cells.clear()


func _choose_deduction() -> void:
	var search_center: Vector3 = monster.get_final_cursor_position()
	var best_score: float = 0.0
	var teammate: Monster3D = _find_teammate()
	
	var impatience_factor: float = clamp(_impatience_timer / _patience_duration, 0.0, 1.0)
	var min_distance_ratio: float = lerp(_patient_distance_ratio, 0.0, impatience_factor)
	
	for deduction: Deduction in monster.pending_deductions.values():
		if monster.solving_board.get_cell(deduction.pos) != CELL_EMPTY:
			monster.remove_pending_deduction_at(deduction.pos)
			continue
		if _cursor_commands_by_cell.has(deduction.pos):
			monster.remove_pending_deduction_at(deduction.pos)
			continue
		
		var score: float = _score_deduction(deduction, search_center, teammate, min_distance_ratio)
		if score > 0.0:
			score += DeductionScorer.get_priority(deduction.reason)
		if score > best_score:
			_next_deduction = deduction
			best_score = score
	if _next_deduction:
		monster.remove_pending_deduction_at(_next_deduction.pos)


func _find_teammate() -> Monster3D:
	var teammate: Monster3D = null
	var teammate_dist: float = 999999
	for other_monster: Monster3D in get_tree().get_nodes_in_group("monsters"):
		if other_monster == monster:
			continue
		if other_monster.cursor_board != monster.cursor_board:
			continue
		var other_monster_dist: float = other_monster.cursor_3d.global_position.distance_to(
				monster.cursor_3d.global_position)
		if other_monster_dist < teammate_dist:
			teammate = other_monster
			teammate_dist = other_monster_dist
	return teammate


func _execute_curr_deduction() -> void:
	if _solver.verbose:
		print("monster %s deduction: %s" % [monster.id, _curr_deduction])
	var target_pos: Vector3 = monster.solving_board.map_to_global(_curr_deduction.pos)
	var commands: Array[SimInput3D.CursorCommand] = []
	match _curr_deduction.value:
		CELL_WALL:
			commands.append(monster.input.queue_cursor_command(SimInput3D.LMB_PRESS, target_pos))
			commands.append(monster.input.queue_cursor_command(SimInput3D.LMB_RELEASE, target_pos, 0.1))
		CELL_ISLAND:
			commands.append(monster.input.queue_cursor_command(SimInput3D.RMB_PRESS, target_pos))
			commands.append(monster.input.queue_cursor_command(SimInput3D.RMB_RELEASE, target_pos, 0.1))
	_cursor_commands_by_cell[_curr_deduction.pos] = commands
	_interested_cells[_curr_deduction.pos] = Time.get_ticks_msec()


func _perform_while_fixing(delta: float) -> bool:
	monster.increase_boredom(delta)
	_process_idle_cursor(delta)
	if monster.boredom >= 75:
		monster.memory["puzzle.bored_with_puzzle"] = true
	return monster.memory.get("puzzle.bored_with_puzzle", false) or monster.solving_board.is_finished()


func _perform_normally(delta: float) -> bool:
	monster.decrease_boredom(delta)
	_update_recently_modified_cells()
	
	if _solver_cooldown_remaining > 0.0:
		_solver_cooldown_remaining -= delta
	
	if _solver_cooldown_remaining <= 0 and not _solver.is_move_requested(monster):
		# queue up the next deduction finder
		_solver.request_move(monster)
		_solver_cooldown_remaining = _solver_cooldown
	
	if _choose_deduction_cooldown_remaining > 0.0:
		_choose_deduction_cooldown_remaining -= delta
	
	if _next_deduction == null \
			and not monster.pending_deductions.is_empty() \
			and _choose_deduction_cooldown_remaining <= 0:
		_choose_deduction()
		_choose_deduction_cooldown_remaining = CHOOSE_DEDUCTION_COOLDOWN
		
		if _next_deduction != null:
			_next_deduction_remaining_time = \
					DeductionScorer.get_delay(_next_deduction.reason, _deduction_speed_factor) * randf_range(1.0, 1.5)
	
	if not monster.pending_deductions.is_empty() and _next_deduction == null:
		_impatience_timer += delta
	else:
		_impatience_timer = 0.0
	
	if _next_deduction != null:
		_process_next_deduction(delta)
	else:
		_process_idle_cursor(delta)
	
	return monster.solving_board.is_finished()


func _update_recently_modified_cells() -> void:
	var expired_window: int = Time.get_ticks_msec() - int(RECENT_MODIFICATION_WINDOW * 1000)
	for cell: Vector2i in _interested_cells.keys():
		if _interested_cells[cell] < expired_window:
			_interested_cells.erase(cell)


func _process_next_deduction(delta: float) -> void:
	if monster.solving_board.get_cell(_next_deduction.pos) == _next_deduction.value:
		_next_deduction = null
		return
	
	_next_deduction_remaining_time -= delta
	if _next_deduction_remaining_time <= 0:
		if _has_adjacent_error(_next_deduction.pos):
			# the sim's next deduction is near an error, so they wait until it's fixed
			_interested_cells[_next_deduction.pos] = Time.get_ticks_msec()
			_needs_fix = true
			_clear_working_state()
		else:
			# the sim makes their next deduction
			_curr_deduction = _next_deduction
			_next_deduction = null
			_execute_curr_deduction()
	else:
		_process_idle_cursor(delta)


## Interrupts any deductions and cursor commands.
func _clear_working_state() -> void:
	_curr_deduction = null
	_next_deduction = null
	monster.pending_deductions.clear()
	_cursor_commands_by_cell.clear()
	monster.input.cursor_commands.clear()
	monster.input.release_buttons()


func _has_adjacent_error(cell: Vector2i) -> bool:
	if monster.solving_board.error_cells.is_empty():
		return false
	
	var result: bool = false
	for dir: Vector2i in ADJACENT_DIRS:
		var adjacent_cell: Vector2i = cell + dir
		if monster.solving_board.error_cells.has(adjacent_cell):
			result = true
			break
	return result


func _process_idle_cursor(delta: float) -> void:
	if not monster.input.cursor_commands.is_empty():
		return
	if _idle_cooldown_remaining > 0:
		_idle_cooldown_remaining -= delta
		return
	
	var board_aabb: AABB = monster.solving_board.get_aabb()
	var pos: Vector3 = monster.cursor_3d.global_position
	
	# move the cursor randomly, "bouncing off" the edge of the board
	var pos_delta: Vector3 = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	if not board_aabb.has_point(Vector3(pos.x, board_aabb.position.y, pos.z + pos_delta.z)):
		pos_delta.z *= -1
	if not board_aabb.has_point(Vector3(pos.x + pos_delta.x, board_aabb.position.y, pos.z)):
		pos_delta.x *= -1
	
	pos = (pos + pos_delta).clamp(board_aabb.position, board_aabb.end)
	monster.input.queue_cursor_command(SimInput3D.MOVE, pos, 0.0, 0.33)
	_idle_cooldown_remaining = _idle_cooldown


func _score_deduction(
		deduction: Deduction,
		search_center: Vector3,
		teammate: Monster3D,
		min_distance_ratio: float) -> float:
	# some deductions score negative; these represent deductions which are too close to the player cursor
	var score: float = 0.0
	var distance_ratio: float = _get_distance_ratio(deduction, search_center, teammate)
	if distance_ratio >= min_distance_ratio:
		var deduction_global_pos: Vector3 = monster.solving_board.map_to_global(deduction.pos)
		var cursor_dist: float = search_center.distance_to(deduction_global_pos)
		# prefer closer deductions; add a little randomness so sims don't overlap each other so much
		score += 10.0 * _score_distance(cursor_dist, 4.7) + randf_range(0.0, 1.0)
	return score


func _get_distance_ratio(deduction: Deduction, search_center: Vector3, teammate: Monster3D) -> float:
	var deduction_global_pos: Vector3 = monster.solving_board.map_to_global(deduction.pos)
	var cursor_dist: float = search_center.distance_to(deduction_global_pos)
	var distance_ratio: float = 999999.0
	if teammate:
		var teammate_cursor_dist: float = teammate.cursor_3d.global_position.distance_to(deduction_global_pos)
		distance_ratio = max(teammate_cursor_dist, 0.1) / max(cursor_dist, 0.1)
	return distance_ratio


## Exponential decay: closer cursor = higher score, normalized for board size
func _score_distance(distance: float, decay_factor: float) -> float:
	return exp(-(distance / _board_size_factor) / decay_factor)


func _on_solving_board_cell_changed(cell_pos: Vector2i, _value: int) -> void:
	if _cursor_commands_by_cell.has(cell_pos):
		var cursor_press_command: SimInput3D.CursorCommand = null
		for cursor_command: SimInput3D.CursorCommand in _cursor_commands_by_cell[cell_pos]:
			if cursor_command.action in [SimInput3D.LMB_PRESS, SimInput3D.RMB_PRESS] \
					and monster.input.has_cursor_command(cursor_command):
				cursor_press_command = cursor_command
				break
		if cursor_press_command != null:
			for cursor_command: SimInput3D.CursorCommand in _cursor_commands_by_cell[cell_pos]:
				monster.input.dequeue_cursor_command(cursor_command)
		
		_cursor_commands_by_cell.erase(cell_pos)


func _on_solving_board_error_cells_changed() -> void:
	# calculate the new value for 'needs_fix'
	var new_needs_fix: bool = false
	for cell: Vector2i in _interested_cells:
		if _has_adjacent_error(cell):
			new_needs_fix = true
			break
	
	# react to any state changes in 'needs_fix'
	if new_needs_fix != _needs_fix:
		if new_needs_fix:
			_needs_fix = true
			_clear_working_state()
		else:
			_needs_fix = false


func _on_solving_board_reset() -> void:
	_needs_fix = false
	_interested_cells.clear()
	_clear_working_state()
