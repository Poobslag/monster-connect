class_name DeductionBatch

var deductions: Array[Deduction] = []
var cells: Dictionary[Vector2i, bool]

func add_deduction(pos: Vector2i, value: int,
		reason: Deduction.Reason = Deduction.Reason.UNKNOWN,
		reason_cells: Array[Vector2i] = []) -> void:
	deductions.append(Deduction.new(pos, value, reason, reason_cells))
	cells[pos] = true


func has_changes() -> bool:
	return not deductions.is_empty()


func get_changes() -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for deduction: Deduction in deductions:
		changes.append(deduction.to_change())
	return changes


func clear() -> void:
	deductions.clear()
	cells.clear()


func size() -> int:
	return deductions.size()
