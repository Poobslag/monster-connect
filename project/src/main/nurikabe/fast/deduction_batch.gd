class_name DeductionBatch

var deductions: Array[FastDeduction] = []
var cells: Dictionary[Vector2i, bool]

func add_deduction(pos: Vector2i, value: String, reason: String) -> void:
	deductions.append(FastDeduction.new(pos, value, reason))
	cells[pos] = true


func get_changes() -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for deduction: FastDeduction in deductions:
		changes.append(deduction.to_change())
	return changes


func clear() -> void:
	deductions.clear()
	cells.clear()


func size() -> int:
	return deductions.size()
