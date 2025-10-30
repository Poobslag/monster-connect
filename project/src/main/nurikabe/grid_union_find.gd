class_name GridUnionFind
## Implementation of the union-find data structure.[br]
## [br]
## Stores a collection of disjoint (non-overlapping) sets, providing operations for adding new sets, merging sets, and
## finding a representative member of a set. The last operation makes it possible to determine efficiently whether any
## two elements belong to the same set or to different sets. See
## https://en.wikipedia.org/wiki/Disjoint-set_data_structure

var _active: Dictionary[Vector2i, bool] = {}
var _parent: Dictionary[Vector2i, Vector2i] = {}
var _size: Dictionary[Vector2i, int] = {}
var _groups_dirty: bool = true
var _cached_groups_by_root: Dictionary[Vector2i, Array] = {}

func clear() -> void:
	_active.clear()
	_parent.clear()
	_size.clear()
	_groups_dirty = true


func duplicate() -> GridUnionFind:
	var copy: GridUnionFind = GridUnionFind.new()
	copy._active = _active.duplicate()
	copy._parent = _parent.duplicate()
	copy._size = _size.duplicate()
	copy._groups_dirty = _groups_dirty
	copy._cached_groups_by_root = _cached_groups_by_root.duplicate()
	return copy


func has_cell(cell: Vector2i) -> bool:
	return _active.has(cell)


func is_active(cell: Vector2i) -> bool:
	return _active.get(cell, false)


func set_active(cell: Vector2i, active: bool) -> void:
	var was_active: bool = _active.get(cell, false)
	if was_active == active:
		return

	_active[cell] = active
	if active:
		_add_cell(cell)
	else:
		_remove_cell(cell)
	_groups_dirty = true


func get_groups() -> Array[Array]:
	if _groups_dirty:
		_refresh_cached_groups_by_cell()
	return _cached_groups_by_root.values()


func get_neighbor_groups(cell: Vector2i) -> Array[Array]:
	if _groups_dirty:
		_refresh_cached_groups_by_cell()
	var visited: Dictionary[Vector2i, bool] = {}
	var result: Array[Array] = []
	for neighbor_cell in _get_neighbors(cell):
		if not _active.get(neighbor_cell, false):
			continue
		var root: Vector2i = _find(neighbor_cell)
		if not root in visited:
			visited[root] = true
			result.append(_cached_groups_by_root[root])
	return result


func _refresh_cached_groups_by_cell() -> void:
	_cached_groups_by_root = {}
	for cell: Vector2i in _active:
		if not _active[cell]:
			continue
		var root: Vector2i = _find(cell)
		if not _cached_groups_by_root.has(root):
			_cached_groups_by_root[root] = [] as Array[Vector2i]
		_cached_groups_by_root[root].append(cell)
	_groups_dirty = false


func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i.LEFT,
		cell + Vector2i.RIGHT,
		cell + Vector2i.UP,
		cell + Vector2i.DOWN,
	]


func _find(cell: Vector2i) -> Vector2i:
	if _parent.get(cell) != cell:
		_parent[cell] = _find(_parent[cell])
	return _parent[cell]


func _union(cell_a: Vector2i, cell_b: Vector2i) -> void:
	var root_a: Vector2i = _find(cell_a)
	var root_b: Vector2i = _find(cell_b)
	if root_a == root_b:
		return
	if _size[root_a] < _size[root_b]:
		_parent[root_a] = root_b
		_size[root_b] += _size[root_a]
		_size.erase(root_a)
	else:
		_parent[root_b] = root_a
		_size[root_a] += _size[root_b]
		_size.erase(root_b)


func _add_cell(cell: Vector2i) -> void:
	_parent[cell] = cell
	_size[cell] = 1
	for neighbor_cell: Vector2i in _get_neighbors(cell):
		if _active.get(neighbor_cell, false):
			_union(cell, neighbor_cell)


func _remove_cell(cell: Vector2i) -> void:
	_active.erase(cell)
	_parent.erase(cell)
	_size.erase(cell)

	# find potentially split neighbors
	var active_neighbor_cells: Array[Vector2i] = []
	for neighbor_cell: Vector2i in _get_neighbors(cell):
		if _active.get(neighbor_cell, false):
			active_neighbor_cells.append(neighbor_cell)

	# clear connectivity among affected neighbors
	for neighbor_group: Vector2i in active_neighbor_cells:
		_clear_component(neighbor_group)

	# rebuild connectivity for each separated component
	for neighbor_group: Vector2i in active_neighbor_cells:
		if not _parent.has(neighbor_group):
			_rebuild_component(neighbor_group)


func _clear_component(cell: Vector2i) -> void:
	var stack: Array[Vector2i] = [cell]
	while not stack.is_empty():
		var next_cell: Vector2i = stack.pop_back()
		if not _parent.has(next_cell):
			continue
		_parent.erase(next_cell)
		_size.erase(next_cell)
		for neighbor_cell: Vector2i in _get_neighbors(next_cell):
			if _active.get(neighbor_cell, false):
				stack.append(neighbor_cell)


func _rebuild_component(cell: Vector2i) -> void:
	var stack: Array[Vector2i] = [cell]
	var members: Array[Vector2i] = []
	while not stack.is_empty():
		var next_cell: Vector2i = stack.pop_back()
		if _parent.has(next_cell):
			continue
		_parent[next_cell] = cell
		members.append(next_cell)
		for neighbor_cell in _get_neighbors(next_cell):
			if _active.get(neighbor_cell, false):
				stack.append(neighbor_cell)
	_size[cell] = members.size()
