class_name FastPass

var deductions: Array[FastDeduction] = []
var deduction_cells: Dictionary[Vector2i, bool]

func add_deduction(pos: Vector2i, value: String, reason: String) -> void:
	deductions.append(FastDeduction.new(pos, value, reason))
	deduction_cells[pos] = true


func get_changes() -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for deduction: FastDeduction in deductions:
		changes.append(deduction.to_change())
	return changes


func clear() -> void:
	deductions.clear()
	deduction_cells.clear()
