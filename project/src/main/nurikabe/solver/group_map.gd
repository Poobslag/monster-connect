class_name GroupMap
## Groups connected cells into disjoint sets.[br]
## [br]
## Flood-fills all provided cells. O(n) build, single pass over grid.

var cells: Array[Vector2i]
var groups_by_cell: Dictionary[Vector2i, Array]
var groups: Array[Array]
var roots_by_cell: Dictionary[Vector2i, Vector2i]

func _init(init_cells: Array[Vector2i]) -> void:
	cells = init_cells
	_build()


func _build() -> void:
	roots_by_cell = {}
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
			roots_by_cell[cell] = group.front()
			
			for neighbor: Vector2i in [
				cell + Vector2i.UP, cell + Vector2i.DOWN,
				cell + Vector2i.LEFT, cell + Vector2i.RIGHT]:
				if neighbor in unvisited:
					queue.push_back(neighbor)
					unvisited.erase(neighbor)
		
		groups.append(group)
