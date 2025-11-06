class_name ChokepointMap
## Identifies articulation points within the specified cells.[br]
## [br]
## Uses Tarjan's articulation-point algorithm. O(n) build.

var cells: Array[Vector2i]
var chokepoints_by_cell: Dictionary[Vector2i, bool] = {}

## Active neighbors for each cell (often called 'adj').
var _neighbors_by_cell: Dictionary[Vector2i, Array] = {}

## Discovery index for each cell (often called 'disc').
var _discovery_time_by_cell: Dictionary[Vector2i, int] = {}

## Lowest reachable discovery index for each cell (often called 'low').
var _lowest_index_by_cell: Dictionary[Vector2i, int] = {}

## Parent of each cell in the DFS tree.
var _parent_by_cell: Dictionary[Vector2i, Vector2i] = {}

## Topmost ancestor of each cell in the DFS tree.
var _subtree_cells_by_root: Dictionary[Vector2i, Array] = {}

var _subtree_root_by_cell: Dictionary[Vector2i, Vector2i] = {}

## Number of nodes in each cell's DFS subtree. Not required for Tarjan's algorithm, but used by [unchoked_cell_count].
var _subtree_size_by_cell: Dictionary[Vector2i, int] = {}

## Global discovery counter incremented during DFS (often called 'time')
var _discovery_time: int = 0

func _init(init_cells: Array[Vector2i]) -> void:
	cells = init_cells
	_build()


func get_component_cell_count(cell: Vector2i) -> int:
	var cell_root: Vector2i = get_subtree_root(cell)
	return _subtree_size_by_cell[cell_root]


func get_component_cells(cell: Vector2i) -> Array[Vector2i]:
	var cell_root: Vector2i = get_subtree_root(cell)
	return _subtree_cells_by_root[cell_root]


## Returns the topmost ancestor of [param cell] in the DFS tree.
func get_subtree_root(cell: Vector2i) -> Vector2i:
	return _subtree_root_by_cell[cell] if _subtree_root_by_cell.has(cell) else cell


## Returns the number of cells reachable from [param cell] if the specified [param chokepoint] were removed.
func get_unchoked_cell_count(chokepoint: Vector2i, cell: Vector2i) -> int:
	var result: int
	
	var chokepoint_root: Vector2i = get_subtree_root(chokepoint)
	var cell_root: Vector2i = get_subtree_root(cell)
	if not chokepoints_by_cell.get(chokepoint, false) or chokepoint_root != cell_root:
		# Specified chokepoint is not a chokepoint or it's in a different component.
		
		if cell_root == chokepoint_root:
			# Cell shares a component with chokepoint.
			# Return the size of the cell component - 1.
			result = _subtree_size_by_cell[cell_root] - 1
		else:
			# Cell does not share a component with chokepoint.
			# Return the size of the cell component.
			result = _subtree_size_by_cell[cell_root]
	else:
		var branch_root: Vector2i = _find_subtree_root_under_chokepoint(chokepoint, cell)
		if _parent_by_cell.get(branch_root) == chokepoint:
			# Cell is a descendant of the chokepoint.
			if _lowest_index_by_cell[branch_root] >= _discovery_time_by_cell[chokepoint]:
				# Cell is only connected to the root through the chokepoint.
				# Return the size of the chokepoint subtree containing cell.
				result = _subtree_size_by_cell[branch_root]
			else:
				# Cell is connected to the root through a back reference.
				# Return the size of the subtree excluding the chokepoint's subtrees and excluding the chokepoint
				# itself.
				var detached_sum := 0
				for neighbor_cell: Vector2i in _neighbors_by_cell[chokepoint]:
					if _parent_by_cell.get(neighbor_cell) == chokepoint \
							and _lowest_index_by_cell[neighbor_cell] >= _discovery_time_by_cell[chokepoint] \
							and neighbor_cell != branch_root:
						detached_sum += _subtree_size_by_cell[neighbor_cell]
				result = _subtree_size_by_cell[cell_root] - detached_sum - 1
		else:
			# Cell is not a descendant of the chokepoint.
			# Return the size of the subtree excluding the chokepoint's subtrees and excluding the chokepoint itself.
			var detached_sum := 0
			for neighbor_cell: Vector2i in _neighbors_by_cell[chokepoint]:
				if _parent_by_cell.get(neighbor_cell) == chokepoint \
						and _lowest_index_by_cell[neighbor_cell] >= _discovery_time_by_cell[chokepoint]:
					detached_sum += _subtree_size_by_cell[neighbor_cell]
			result = _subtree_size_by_cell[cell_root] - detached_sum - 1
	return result


func _build() -> void:
	# store adjacency graph in _neighbors_by_cell
	for cell: Vector2i in cells:
		_neighbors_by_cell[cell] = [] as Array[Vector2i]
	for cell: Vector2i in cells:
		for neighbor_cell: Vector2i in [
				cell + Vector2i.UP, cell + Vector2i.DOWN,
				cell + Vector2i.LEFT, cell + Vector2i.RIGHT]:
			if neighbor_cell in _neighbors_by_cell:
				_neighbors_by_cell[cell].append(neighbor_cell)
	
	# run tarjan's algorithm
	for cell: Vector2i in cells:
		if _discovery_time_by_cell.has(cell):
			# already visited
			continue
		_perform_dfs(cell)


func _perform_dfs(cell: Vector2i) -> void:
	_discovery_time_by_cell[cell] = _discovery_time
	_lowest_index_by_cell[cell] = _discovery_time
	_discovery_time += 1
	var children: int = 0
	var subtree_size: int = 1
	var subtree_root: Vector2i = get_subtree_root(cell)
	if not _subtree_cells_by_root.has(subtree_root):
		_subtree_cells_by_root[subtree_root] = [] as Array[Vector2i]
	_subtree_cells_by_root[subtree_root].append(cell)
	
	for neighbor_cell: Vector2i in _neighbors_by_cell[cell]:
		if not _discovery_time_by_cell.has(neighbor_cell):
			children += 1
			_parent_by_cell[neighbor_cell] = cell
			_subtree_root_by_cell[neighbor_cell] = subtree_root
			_perform_dfs(neighbor_cell)
			subtree_size += _subtree_size_by_cell[neighbor_cell]
			_lowest_index_by_cell[cell] = min(_lowest_index_by_cell[cell], _lowest_index_by_cell[neighbor_cell])
			if not _parent_by_cell.has(cell) and children > 1:
				chokepoints_by_cell[cell] = true
			if _parent_by_cell.has(cell) and _lowest_index_by_cell[neighbor_cell] >= _discovery_time_by_cell[cell]:
				chokepoints_by_cell[cell] = true
		elif neighbor_cell != _parent_by_cell.get(cell):
			_lowest_index_by_cell[cell] = min(_lowest_index_by_cell[cell], _discovery_time_by_cell[neighbor_cell])
	
	_subtree_size_by_cell[cell] = subtree_size


## Returns the topmost ancestor of [param cell] whose parent is [param chokepoint].[br]
## [br]
## If cell is not a descendant of chokepoint, returns the DFS root of its component.
func _find_subtree_root_under_chokepoint(chokepoint: Vector2i, cell: Vector2i) -> Vector2i:
	var curr: Vector2i = cell
	while _parent_by_cell.has(curr):
		var next: Vector2i = _parent_by_cell[curr]
		if next == chokepoint:
			break
		curr = next
	return curr
