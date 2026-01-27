class_name WorkOnPuzzleAction
extends GoapAction

const SOLVER_COOLDOWN: float = 10.0

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
		var deduction: Deduction = monster.pending_deductions.values().pick_random()
		if monster.current_game_board.get_cell(deduction.pos) == CELL_EMPTY:
			_next_deduction = deduction
			_next_deduction_remaining_time = 0.6
		monster.pending_deductions.erase(deduction.pos)
	
	if _next_deduction != null:
		_next_deduction_remaining_time -= delta
		if _next_deduction_remaining_time <= 0:
			if monster.current_game_board.get_cell(_next_deduction.pos) == CELL_EMPTY:
				monster.current_game_board.set_cell(_next_deduction.pos, _next_deduction.value, monster.id)
			_next_deduction = null
	
	return monster.current_game_board.is_finished()


func exit(actor: Variant) -> void:
	var monster: SimMonster = actor
	
	_solver.cancel_request(monster)
	_next_deduction = null
	_next_deduction_remaining_time = 0.0
	_solver_cooldown_remaining = 0.0
	
	monster.pending_deductions.clear()
