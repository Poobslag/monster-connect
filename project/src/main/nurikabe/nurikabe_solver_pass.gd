class_name NurikabeSolverPass

var deductions: Array[NurikabeDeduction] = []
var deduction_cells: Dictionary[Vector2i, bool]

func add_deduction(pos: Vector2i, value: String, reason: NurikabeUtils.Reason) -> void:
	deductions.append(NurikabeDeduction.new(pos, value, reason))
	deduction_cells[pos] = true


func get_changes() -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for deduction in deductions:
		changes.append(deduction.to_change())
	return changes


func clear() -> void:
	deductions.clear()
	deduction_cells.clear()
