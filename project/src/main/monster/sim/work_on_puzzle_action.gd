class_name WorkOnPuzzleAction
extends GoapAction

const SOLVER_COOLDOWN: float = 3.0
const IDLE_COOLDOWN: float = 3.0

const ADJACENT_DIRS: Array[Vector2i] = NurikabeUtils.ADJACENT_DIRS

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const RECENT_MODIFICATION_WINDOW: float = 1.0

var _board_size_factor: float
var _curr_deduction: Deduction
var _next_deduction: Deduction
var _next_deduction_remaining_time: float = 0.0
var _next_idle_remaining_time: float
var _solver_cooldown_remaining: float = 0.0
var _needs_fix: bool = false

var _cursor_commands_by_cell: Dictionary[Vector2i, Array] = {}
var _interested_cells: Dictionary[Vector2i, float] = {}

@onready var _solver: NaiveSolver = NaiveSolver.find_instance(self)
@onready var monster: SimMonster = Utils.find_parent_of_type(self, SimMonster)

func enter() -> void:
	monster.solving_board.cell_changed.connect(_on_solving_board_cell_changed)
	monster.solving_board.error_cells_changed.connect(_on_solving_board_error_cells_changed)
	monster.solving_board.board_reset.connect(_on_solving_board_reset)
	_board_size_factor = monster.solving_board.get_global_cursorable_rect().size.length() / 500.0
	_next_idle_remaining_time = randf_range(0, IDLE_COOLDOWN)


func perform(delta: float) -> bool:
	var result: bool = false
	
	if _needs_fix:
		result = _perform_while_fixing(delta)
	else:
		result = _perform_normally(delta)
	return result


func exit() -> void:
	_solver.cancel_request(monster)
	monster.solving_board.cell_changed.disconnect(_on_solving_board_cell_changed)
	monster.solving_board.error_cells_changed.disconnect(_on_solving_board_error_cells_changed)
	monster.solving_board.board_reset.disconnect(_on_solving_board_reset)

	_curr_deduction = null
	_next_deduction = null
	_next_deduction_remaining_time = 0.0
	_next_idle_remaining_time = 0.0
	_solver_cooldown_remaining = 0.0
	_needs_fix = false
	
	monster.pending_deductions.clear()
	_cursor_commands_by_cell.clear()
	_interested_cells.clear()


func _choose_deduction() -> void:
	var search_center: Vector2i = monster.get_final_cursor_position()
	
	var best_score: float = 0.0
	for deduction: Deduction in monster.pending_deductions.values():
		if monster.solving_board.get_cell(deduction.pos) != CELL_EMPTY:
			monster.remove_pending_deduction_at(deduction.pos)
			continue
		if _cursor_commands_by_cell.has(deduction.pos):
			monster.remove_pending_deduction_at(deduction.pos)
			continue
		
		var score: float = _score_deduction(deduction, search_center)
		if score > 0.0:
			score += DeductionScorer.get_priority(deduction.reason)
		if score > best_score:
			_next_deduction = deduction
			best_score = score
	if _next_deduction:
		monster.remove_pending_deduction_at(_next_deduction.pos)


func _execute_curr_deduction() -> void:
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
	_interested_cells[_curr_deduction.pos] = Time.get_ticks_msec()


func _perform_while_fixing(delta: float) -> bool:
	monster.increase_boredom(delta)
	_process_idle_cursor( delta)
	if monster.boredom >= 75:
		monster.bored_with_puzzle = true
	return monster.bored_with_puzzle or monster.solving_board.is_finished()


func _perform_normally(delta: float) -> bool:
	monster.decrease_boredom(delta)
	_update_recently_modified_cells()
	
	if _solver_cooldown_remaining > 0.0:
		_solver_cooldown_remaining -= delta
	
	if _solver_cooldown_remaining <= 0 and not _solver.is_move_requested(monster):
		# queue up the next deduction finder
		_solver.request_move(monster)
		_solver_cooldown_remaining = SOLVER_COOLDOWN
	
	if _next_deduction == null and not monster.pending_deductions.is_empty():
		_choose_deduction()
		if _next_deduction != null:
			_next_deduction_remaining_time = \
					DeductionScorer.get_delay(_next_deduction.reason) * randf_range(1.0, 1.5)
	
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


func _score_deduction(deduction: Deduction, search_center: Vector2) -> float:
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


## Exponential decay: closer cursor = higher score, normalized for board size
func _score_distance(distance: float, decay_factor: float) -> float:
	return exp(-(distance / _board_size_factor) / decay_factor)


func _on_solving_board_cell_changed(cell_pos: Vector2i, _value: int) -> void:
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
