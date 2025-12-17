class_name Placement extends ChangeRecord

enum Reason {
	UNKNOWN,
	
	# starting techniques
	INITIAL_OPEN_ISLAND, # add a clue cell constrained to expand through a single open liberty
	
	# basic techniques
	ISLAND_GUIDE, # add a clue cell to constrain an open island
	ISLAND_EXPANSION, # add an island cell to expand an open island
	ISLAND_MOAT, # seal an open island with walls
	SEALED_ISLAND_CLUE, # assign a clue number to a sealed island
	WALL_GUIDE, # add a clue cell to constrain an open wall
	
	# recovery techniques
	FIX_POOL, # adjust surrounding islands to avoid a 2x2 wall area
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
