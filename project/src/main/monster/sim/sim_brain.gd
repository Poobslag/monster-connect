extends Node

@export var verbose: bool = false

var _current_action: GoapAction

@onready var _monster: SimMonster = Utils.find_parent_of_type(self, SimMonster)

@onready var _find_puzzle_action: GoapAction = %FindPuzzleAction
@onready var _idle_action: GoapAction = %IdleAction
@onready var _leave_puzzle_action: GoapAction = %LeavePuzzleAction
@onready var _work_on_puzzle_action: GoapAction = %WorkOnPuzzleAction

func _process(delta: float) -> void:
	# select action based on current state
	var new_action: GoapAction = _current_action
	if _monster.solving_board == null:
		new_action = _find_puzzle_action if _monster.boredom >= 25 else _idle_action
	else:
		new_action = _leave_puzzle_action if _monster.solving_board.is_finished() else _work_on_puzzle_action
	
	# handle action transitions
	if new_action != _current_action:
		_log_action_change(new_action)
		if _current_action != null:
			_current_action.exit(_monster)
		_current_action = new_action
		if _current_action != null:
			_current_action.enter(_monster)
	
	# execute current action
	var finished: bool = _current_action.perform(_monster, delta)
	if finished:
		_current_action.exit(_monster)
		_current_action = null


func _log_action_change(new_action: GoapAction) -> void:
	if not verbose:
		return
	print("action: %s->%s" % [
			str(_current_action.name) if _current_action else "null",
			str(new_action.name) if new_action else "null",
		])
