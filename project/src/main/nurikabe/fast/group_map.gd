class_name GroupMap

var cells: Array[Vector2i]
var groups_by_cell: Dictionary[Vector2i, Array]
var groups: Array[Array]

func _init(init_cells: Array[Vector2i]) -> void:
	cells = init_cells
	_build()


func _build() -> void:
	var remaining_cells: Dictionary[Vector2i, bool] = {}
	for next_cell: Vector2i in cells:
		remaining_cells[next_cell] = true
	
	groups_by_cell = {}
	groups = []
	var queue: Array[Vector2i] = []
	while not remaining_cells.is_empty() or not queue.is_empty():
		var next_cell: Vector2i
		if queue.is_empty():
			# start a new group
			next_cell = remaining_cells.keys().front()
			remaining_cells.erase(next_cell)
			groups.append([] as Array[Vector2i])
		else:
			# pop the next cell from the queue
			next_cell = queue.pop_front()
		
		# append the next cell to this group
		groups.back().append(next_cell)
		groups_by_cell[next_cell] = groups.back()
		
		# recurse to neighboring _board.cells
		for neighbor_cell: Vector2i in [
				next_cell + Vector2i.UP, next_cell + Vector2i.DOWN,
				next_cell + Vector2i.LEFT, next_cell + Vector2i.RIGHT]:
			if neighbor_cell in remaining_cells:
				queue.push_back(neighbor_cell)
				remaining_cells.erase(neighbor_cell)
