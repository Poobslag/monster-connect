@tool
class_name SimMonster
extends Monster

const BOREDOM_PER_SECOND: float = 1.66667 # 100 per minute

@onready var input: SimInput = %Input

var solving_board: NurikabeGameBoard

var memory: Dictionary[String, Variant] = {}

var boredom: float = randf_range(0, 6)
var pending_deductions: Dictionary[Vector2i, Deduction] = {}

func update_input(delta: float) -> void:
	input.update(delta)


func _process(delta: float) -> void:
	if solving_board == null:
		increase_boredom(delta)


func increase_boredom(delta: float) -> void:
	boredom = clamp(boredom + delta * BOREDOM_PER_SECOND, 0, 100)


func decrease_boredom(delta: float) -> void:
	boredom = clamp(boredom - delta * BOREDOM_PER_SECOND, 0, 100)


## Returns the global cursor position after any queued cursor commands.
func get_final_cursor_position() -> Vector2:
	var result: Vector2i
	if not input.cursor_commands.is_empty():
		result = input.cursor_commands.back().pos
	else:
		result = cursor.global_position
	return result


func add_pending_deduction(init_pos: Vector2i, init_value: int,
		init_reason: Deduction.Reason = Deduction.Reason.UNKNOWN) -> bool:
	if pending_deductions.has(init_pos):
		return false
	
	pending_deductions[init_pos] = Deduction.new(init_pos, init_value, init_reason)
	return true


func remove_pending_deduction_at(pos: Vector2i) -> void:
	pending_deductions.erase(pos)
