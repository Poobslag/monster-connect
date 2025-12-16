class_name Placement extends ChangeRecord

enum Reason {
	UNKNOWN,
	
	# starting techniques
	INITIAL_OPEN_ISLAND, # add a clue cell constrained to expand through a single open liberty
	
	# basic techniques
	OPEN_ISLAND_GUIDE, # add a clue cell to constrain an open island
}

var reason: Reason

func _init(init_pos: Vector2i, init_value: int,
		init_reason: Reason = Reason.UNKNOWN,
		init_reason_cells: Array[Vector2i] = []) -> void:
	super._init(init_pos, init_value, init_reason_cells)
	reason = init_reason


func _to_string() -> String:
	var cells_str: String = "" if sources.is_empty() else " " + " ".join(sources)
	return "%s->%s %s%s" % [pos, NurikabeUtils.to_cell_string(value),
			Utils.enum_to_snake_case(Reason, reason), cells_str]
