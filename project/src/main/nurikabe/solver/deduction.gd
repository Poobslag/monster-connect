class_name Deduction

enum Reason {
	UNKNOWN,
	
	# starting techniques
	ISLAND_OF_ONE, # surround single-square island with walls
	ADJACENT_CLUES, # wall off a liberty shared between two clues
	
	# basic techniques
	CORNER_ISLAND, # add a wall diagonally from an island with only two liberties
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
	
	# advanced techniques
	ASSUMPTION, # unproven assumption made when bifurcating
	ISLAND_BATTLEGROUND, # bifurcate two clues with adjacent liberties
	ISLAND_STRANGLE, # bifurcate options for completing an island, walling off impossible ones
	WALL_STRANGLE, # bifurcate options where extending an island would create a split wall
}

var pos: Vector2i
var value: String
var reason: Reason
var reason_cells: Array[Vector2i]

func _init(init_pos: Vector2i, init_value: String,
		init_reason: Reason = Reason.UNKNOWN,
		init_reason_cells: Array[Vector2i] = []) -> void:
	pos = init_pos
	value = init_value
	reason = init_reason
	reason_cells = init_reason_cells


func to_change() -> Dictionary[String, Variant]:
	return {"pos": pos, "value": value}


func _to_string() -> String:
	var cells_str: String = "" if reason_cells.is_empty() else " " + " ".join(reason_cells)
	return "%s->%s %s%s" % [pos, value, Utils.enum_to_snake_case(Reason, reason), cells_str]
