class_name PuzzleInfoGenerator
extends Node

var solver: Solver = Solver.new()

var _order_by_cell: Dictionary[Vector2i, int] = {}
var _reason_by_cell: Dictionary[Vector2i, Deduction.Reason] = {}

@onready var _generator: BulkGenerator = get_parent()

func read_puzzle_info(path: String) -> PuzzleInfo:
	var info_path: String = NurikabeUtils.get_puzzle_info_path(path)
	var puzzle_info: PuzzleInfo
	if FileAccess.file_exists(info_path):
		puzzle_info = PuzzleInfoSaver.new().load_puzzle_info(info_path)
	return puzzle_info


func write_puzzle_info(puzzle_path: String) -> void:
	%GameBoard.grid_string = NurikabeUtils.load_grid_string_from_file(puzzle_path)
	%GameBoard.import_grid()
	solver.clear()
	_order_by_cell.clear()
	_reason_by_cell.clear()
	solver.board = %GameBoard.to_solver_board()
	_step_until_done()
	copy_board_from_solver()
	var validation_result: SolverBoard.ValidationResult \
			= solver.board.validate(SolverBoard.VALIDATE_STRICT)
	if validation_result.error_count > 0:
		_generator.log_message("Error: Invalid solution for %s" % [puzzle_path])
		print("== %s" % [puzzle_path])
		solver.board.print_cells()
		print(validation_result)
		return
	
	var info_path: String = NurikabeUtils.get_puzzle_info_path(puzzle_path)
	
	var old_info: PuzzleInfo = read_puzzle_info(puzzle_path)
	
	var info: PuzzleInfo = PuzzleInfo.new()
	info.version = PuzzleInfoSaver.PUZZLE_INFO_VERSION if old_info == null else old_info.version
	info.author = "poobslag v03" if old_info == null else old_info.author
	info.difficulty = solver.get_measured_difficulty()
	for cell: Vector2i in solver.board.cells:
		info.size.x = maxi(info.size.x, cell.x)
		info.size.y = maxi(info.size.y, cell.y)
	info.solution_string = _get_solution_string()
	info.order_string = _get_order_string()
	info.reason_string = _get_reason_string()
	
	PuzzleInfoSaver.new().save_puzzle_info(info_path, info)
	
	_generator.log_message("Wrote %s." % [info_path])
	solver.board.cleanup()


func copy_board_from_solver() -> void:
	solver.board.update_game_board(%GameBoard)


func _get_solution_string() -> String:
	return solver.board.to_grid_string()


func _get_order_string() -> String:
	var rect: Rect2i = Rect2i(_order_by_cell.keys()[0].x, _order_by_cell.keys()[0].y, 0, 0)
	for cell: Vector2i in _order_by_cell:
		rect = rect.expand(cell)
	
	var lines: Array[String] = []
	for y: int in range(rect.position.y, rect.end.y + 1):
		var line: Array[String] = []
		for x: int in range(rect.position.x, rect.end.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			var cell_string: String = "-"
			if _order_by_cell.has(cell):
				var cell_value: int = _order_by_cell.get(cell, -1)
				cell_string = str(cell_value)
			line.append(cell_string)
		lines.append(" ".join(line))
	return "\n".join(lines)


func _get_reason_string() -> String:
	var rect: Rect2i = Rect2i(_reason_by_cell.keys()[0].x, _reason_by_cell.keys()[0].y, 0, 0)
	for cell: Vector2i in _reason_by_cell:
		rect = rect.expand(cell)
	
	var lines: Array[String] = []
	for y: int in range(rect.position.y, rect.end.y + 1):
		var line: Array[String] = []
		for x: int in range(rect.position.x, rect.end.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			var cell_string: String = "-"
			if _reason_by_cell.has(cell):
				var reason: Deduction.Reason = _reason_by_cell.get(cell, Deduction.Reason.UNKNOWN)
				cell_string = ReasonCode.encode(reason)
			line.append(cell_string)
		lines.append(" ".join(line))
	return "\n".join(lines)


func _step_until_done() -> void:
	var order_num: int = 0
	while true:
		solver.step()
		if not solver.deductions.has_changes():
			break
		
		for deduction: Deduction in solver.deductions.deductions:
			_order_by_cell[deduction.pos] = order_num
			_reason_by_cell[deduction.pos] = deduction.reason
		
		solver.apply_changes()
		order_num += 1
