@tool
class_name SimMonster
extends Monster

const BOREDOM_PER_SECOND: float = 16.66667 # should be lowered to 1.66667 (100 per minute) after testing

@onready var input: SimInput = %Input

var solving_board: NurikabeGameBoard

var boredom: float = 0.0
var pending_deductions: Dictionary[Vector2i, Deduction] = {}

func update_input(delta: float) -> void:
	input.update(delta)


func _process(delta: float) -> void:
	if solving_board == null:
		boredom = clamp(boredom + delta * BOREDOM_PER_SECOND, 0, 100)
	else:
		boredom = clamp(boredom - delta * BOREDOM_PER_SECOND, 0, 100)


func add_pending_deduction(init_pos: Vector2i, init_value: int,
		init_reason: Deduction.Reason = Deduction.Reason.UNKNOWN) -> bool:
	if pending_deductions.has(init_pos):
		return false
	
	pending_deductions[init_pos] = Deduction.new(init_pos, init_value, init_reason)
	return true


func remove_pending_deduction_at(pos: Vector2i) -> void:
	pending_deductions.erase(pos)
