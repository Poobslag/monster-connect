class_name SqueezeFill
## Fills an empty corridor with walls (or islands) until it hits another wall (or island).

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var changes: Dictionary[Vector2i, int] = {}

var _board: SolverBoard
var _queue: Array[Vector2i] = []
var _visited: Dictionary[Vector2i, bool] = {}
var _step_count: int = 0

func _init(init_board: SolverBoard) -> void:
	_board = init_board


func skip_cells(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		_visited[cell] = true


func push_change(cell: Vector2i, value: int) -> void:
	changes[cell] = value
	_visited[cell] = true
	_queue.push_back(cell)


func step() -> void:
	var next_cell: Vector2i = _queue.pop_front()
	var next_cell_value: int = get_cell(next_cell)
	
	var neighbor_match_cells: Array[Vector2i] = []
	var neighbor_empty_cells: Array[Vector2i] = []
	for neighbor_dir: Vector2i in NurikabeUtils.NEIGHBOR_DIRS:
		var neighbor: Vector2i = next_cell + neighbor_dir
		var neighbor_value: int = get_cell(neighbor)
		if neighbor_value == CELL_EMPTY:
			neighbor_empty_cells.append(neighbor)
		elif neighbor_value == CELL_INVALID:
			pass
		elif ((neighbor_value == CELL_WALL) == (next_cell_value == CELL_WALL)):
			neighbor_match_cells.append(neighbor)
	
	var unvisited_neighbor_match: bool = false
	for neighbor_match_cell: Vector2i in neighbor_match_cells:
		if not _visited.has(neighbor_match_cell):
			unvisited_neighbor_match = true
			break
	
	if not unvisited_neighbor_match and neighbor_empty_cells.size() == 1:
		push_change(neighbor_empty_cells[0], next_cell_value)
	
	_step_count += 1


func fill(max_steps: int = 999999) -> void:
	while not _queue.is_empty() and _step_count < max_steps:
		step()


func get_cell(cell: Vector2i) -> int:
	var cell_value: int
	if changes.has(cell):
		cell_value = changes[cell]
	else:
		cell_value = _board.get_cell(cell)
	return cell_value
