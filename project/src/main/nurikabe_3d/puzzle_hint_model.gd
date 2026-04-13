class_name PuzzleHintModel

var solution_grid: Dictionary[Vector2i, int]
var order_grid: Dictionary[Vector2i, int]
var reason_grid: Dictionary[Vector2i, Deduction.Reason]

func _init(puzzle_info: PuzzleInfo, mirrored: bool = false, rotation_turns: int = 0) -> void:
	_parse_solution_string(puzzle_info.solution_string)
	_parse_order_string(puzzle_info.order_string)
	_parse_reason_string(puzzle_info.reason_string)
	
	if mirrored:
		_mirror_grids()
	if rotation_turns != 0:
		_rotate_grids(rotation_turns)


func _parse_solution_string(solution_string: String) -> void:
	solution_grid = NurikabeUtils.cells_from_grid_string(solution_string)


func _parse_order_string(order_string: String) -> void:
	var order_string_rows: PackedStringArray = order_string.split("\n")
	for y in order_string_rows.size():
		var row_string: String = order_string_rows[y]
		var row_array: PackedStringArray = row_string.split(" ")
		for x in row_array.size():
			if row_array[x] == "-":
				continue
			else:
				order_grid[Vector2i(x, y)] = int(row_array[x])


func _parse_reason_string(reason_string: String) -> void:
	var reason_string_rows: PackedStringArray = reason_string.split("\n")
	for y in reason_string_rows.size():
		var row_string: String = reason_string_rows[y]
		var row_array: PackedStringArray = row_string.split(" ")
		for x in row_array.size():
			if row_array[x] == "-":
				continue
			else:
				reason_grid[Vector2i(x, y)] = ReasonCode.decode(row_array[x])


func _mirror_grids() -> void:
	var new_solution_grid: Dictionary[Vector2i, int] = {}
	new_solution_grid.assign(GridTransform.mirror_cells(solution_grid))
	solution_grid = new_solution_grid
	
	var new_order_grid: Dictionary[Vector2i, int] = {}
	new_order_grid.assign(GridTransform.mirror_cells(order_grid))
	order_grid = new_order_grid
	
	var new_reason_grid: Dictionary[Vector2i, Deduction.Reason] = {}
	new_reason_grid.assign(GridTransform.mirror_cells(reason_grid))
	reason_grid = new_reason_grid


func _rotate_grids(rotation_turns: int) -> void:
	var new_solution_grid: Dictionary[Vector2i, int] = {}
	new_solution_grid.assign(GridTransform.rotate_cells(solution_grid, rotation_turns))
	solution_grid = new_solution_grid
	
	var new_order_grid: Dictionary[Vector2i, int] = {}
	new_order_grid.assign(GridTransform.rotate_cells(order_grid, rotation_turns))
	order_grid = new_order_grid
	
	var new_reason_grid: Dictionary[Vector2i, Deduction.Reason] = {}
	new_reason_grid.assign(GridTransform.rotate_cells(reason_grid, rotation_turns))
	reason_grid = new_reason_grid
