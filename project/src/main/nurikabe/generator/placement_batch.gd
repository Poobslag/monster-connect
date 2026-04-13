class_name PlacementBatch

var clue_minimum_changes: Array[Dictionary] = []
var placements: Array[Placement] = []

func add_placement(pos: Vector2i, value: int,
		reason: Placement.Reason = Placement.Reason.UNKNOWN,
		sources: Array[Vector2i] = []) -> void:
	placements.append(Placement.new(pos, value, reason, sources))


func add_clue_minimum_change(pos: Vector2i, value: int) -> void:
	clue_minimum_changes.append({"pos": pos, "value": value} as Dictionary[String, Variant])


func has_changes() -> bool:
	return not placements.is_empty() or not clue_minimum_changes.is_empty()


func clear() -> void:
	clue_minimum_changes.clear()
	placements.clear()


func size() -> int:
	return placements.size()


func _to_string() -> String:
	return "; ".join(placements)
