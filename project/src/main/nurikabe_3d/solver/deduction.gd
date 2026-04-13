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
	
	# Break-in techniques - Applied at puzzle start by examining clue numbers
	ISLAND_OF_ONE, # surround single-square island with walls
	ADJACENT_CLUES, # wall off a liberty shared between two clues
	
	# Easy techniques - Obvious moves novices can find by examining a few nearby cells
	ISLAND_BUBBLE, # fill in an empty cell surrounded by islands
	ISLAND_DIVIDER, # add a wall to keep two islands apart
	ISLAND_EXPANSION, # expand an island to a cell needed to fulfill its clue
	ISLAND_MOAT, # seal a completed island with walls
	POOL_TRIPLET, # add an island to avoid a 2x2 wall area
	WALL_BUBBLE, # wall in a cell surrounded by walls
	WALL_EXPANSION, # expand a wall in the only possible direction
	
	# Standard techniques - Require spatial reasoning or specialized puzzle knowledge
	CORNER_BUFFER, # add a wall diagonally to separate an island from another island with only two liberties
	CORNER_ISLAND, # add a wall diagonally from an island with only two liberties
	ISLAND_BUFFER, # add a wall to preserve space for an island to grow
	ISLAND_CHAIN, # add a wall to avoid connecting an island chain
	ISLAND_CHAIN_BUFFER, # add a wall to prevent a chain cycle from all reachable clues
	ISLAND_CHOKEPOINT, # expand an island through a narrow passage
	ISLAND_CONNECTOR, # connect a clueless island to a clued island
	ISLAND_SNUG, # fill an island when its reachable space matches its clue
	POOL_CHOKEPOINT, # add an island to avoid isolating or trapping a small wall region
	UNCLUED_LIFELINE, # extend an unclued island towards the only connectable clue
	UNCLUED_LIFELINE_BUFFER, # add a wall to prevent an unclued island from becoming unreachable
	UNREACHABLE_CELL, # add a wall where no clue can reach
	WALL_CONNECTOR, # connect two walls through a chokepoint
	
	# Advanced techniques - Require planning several moves ahead
	ASSUMPTION, # unproven assumption made when bifurcating
	BORDER_HUG, # bifurcate options where extending an island along the border would create a split wall
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
