class_name PlacementBatch

var placements: Array[Placement] = []

func add_placement(pos: Vector2i, value: int,
		reason: Placement.Reason = Placement.Reason.UNKNOWN,
		sources: Array[Vector2i] = []) -> void:
	placements.append(Placement.new(pos, value, reason, sources))


func has_changes() -> bool:
	return not placements.is_empty()


func get_changes() -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for deduction: Placement in placements:
		changes.append(deduction.to_change())
	return changes


func clear() -> void:
	placements.clear()


func size() -> int:
	return placements.size()


func _to_string() -> String:
	return "; ".join(placements)
