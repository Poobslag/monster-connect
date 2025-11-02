class_name GroupMap

var cells: Array[Vector2i]
var groups_by_cell: Dictionary[Vector2i, Array]
var groups: Array[Array]

func _init(init_cells: Array[Vector2i]) -> void:
	cells = init_cells
	_build()


func _build() -> void:
	groups_by_cell = {}
	groups = []
	
	var unvisited: Dictionary[Vector2i, bool] = {}
	for next_cell: Vector2i in cells:
		unvisited[next_cell] = true
	
	while not unvisited.is_empty():
		# start a new group
		var start: Vector2i = unvisited.keys().front()
		unvisited.erase(start)
		
		var group: Array[Vector2i] = []
		var queue: Array[Vector2i] = [start]
		
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_front()
			group.append(cell)
			groups_by_cell[cell] = group
			
			for neighbor_cell: Vector2i in [
				cell + Vector2i.UP, cell + Vector2i.DOWN,
				cell + Vector2i.LEFT, cell + Vector2i.RIGHT]:
				if neighbor_cell in unvisited:
					queue.push_back(neighbor_cell)
					unvisited.erase(neighbor_cell)
		
		groups.append(group)
