class_name DeductionBatch

var deductions: Array[Deduction] = []
var cells: Dictionary[Vector2i, bool]

## Adds a deduction to the batch.[br]
## [br]
## Note: It is possible to add multiple redundant deductions to the batch. Allowing for redundant deductions helps us
## with metrics. For cells which can be deduced many ways, it's good to know which ways work most often.
func add_deduction(pos: Vector2i, value: int,
		reason: Deduction.Reason = Deduction.Reason.UNKNOWN,
		sources: Array[Vector2i] = []) -> void:
	deductions.append(Deduction.new(pos, value, reason, sources))
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


func _to_string() -> String:
	return "; ".join(deductions)
