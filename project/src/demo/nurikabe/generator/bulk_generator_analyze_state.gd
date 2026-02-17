extends State

var solver: Solver = Solver.new()
var queue: Array[String] = []

func enter() -> void:
	queue = Utils.find_data_files(BulkGenerator.PUZZLE_DIR, "txt")
	object.log_message("Searching %s; found %s files." % [BulkGenerator.PUZZLE_DIR, queue.size()])


func update(_delta: float) -> void:
	if queue.is_empty():
		object.log_message("Analysis complete.")
		change_state("idle")
		return
	
	var puzzle_path: String = queue.pop_front()
	%PuzzleInfoGenerator.write_puzzle_info(puzzle_path)
