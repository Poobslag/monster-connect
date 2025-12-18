class_name Deduction extends ChangeRecord

enum FunAxis {
	FUN_TRIVIAL, # automatic steps, "this 1 is surrounded by walls"
	FUN_FAST, # immediate steps, "this island has only one liberty"
	FUN_NOVELTY, # atypical steps, "there must be a wall diagonal from this 2"
	FUN_THINK, # structural reasoning, "this island can't be cut off here"
	FUN_BIFURCATE, # guess and check, "there's a contradiction if the wall goes this way"
}

enum Reason {
	UNKNOWN,
	
	# starting techniques
	ISLAND_OF_ONE, # surround single-square island with walls
	ADJACENT_CLUES, # wall off a liberty shared between two clues
	
	# basic techniques
	CORNER_BUFFER, # add a wall diagonally to separate an island from another island with only two liberties
	CORNER_ISLAND, # add a wall diagonally from an island with only two liberties
	ISLAND_BUBBLE, # fill in an empty cell surrounded by islands
	ISLAND_BUFFER, # add a wall to preserve space for an island to grow
	ISLAND_CHOKEPOINT, # expand an island through a narrow passage
	ISLAND_CONNECTOR, # connect a clueless island to a clued island
	ISLAND_DIVIDER, # add a wall to keep two islands apart
	ISLAND_EXPANSION, # expand an island to a cell needed to fulfill its clue
	ISLAND_MOAT, # seal a completed island with walls
	ISLAND_SNUG, # fill an island when its reachable space matches its clue
	POOL_CHOKEPOINT, # add an island to avoid isolating or trapping a small wall region
	POOL_TRIPLET, # add an island to avoid a 2x2 wall area
	UNCLUED_LIFELINE, # extend an unclued island towards the only connectable clue
	UNREACHABLE_CELL, # add a wall where no clue can reach
	WALL_BUBBLE, # wall in a cell surrounded by walls
	WALL_CONNECTOR, # connect two walls through a chokepoint
	WALL_EXPANSION, # expand a wall in the only possible direction
	WALL_WEAVER, # finish an island in a way which preserves wall connectivity
	BORDER_HUG,
	
	# advanced techniques
	ASSUMPTION, # unproven assumption made when bifurcating
	ISLAND_BATTLEGROUND, # bifurcate two clues with adjacent liberties
	ISLAND_RELEASE, # bifurcate options for walling in an island
	ISLAND_STRANGLE, # bifurcate options for completing an island, walling off impossible ones
	WALL_STRANGLE, # bifurcate options where extending an island would create a split wall
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
