class_name GridConnectivityMap

var _active: Dictionary[Vector2i, bool] = {}
var _parent: Dictionary[Vector2i, Vector2i] = {}
var _size: Dictionary[Vector2i, int] = {}
var _groups_dirty: bool = true
var _cached_groups: Array[Array] = []

func clear() -> void:
	_active.clear()
	_parent.clear()
	_size.clear()
	_groups_dirty = true


func duplicate() -> GridConnectivityMap:
	var copy: GridConnectivityMap = GridConnectivityMap.new()
	copy._active = _active.duplicate()
	copy._parent = _parent.duplicate()
	copy._size = _size.duplicate()
	copy._groups_dirty = _groups_dirty
	copy._cached_groups = _cached_groups.duplicate()
	return copy


func has_cell(pos: Vector2i) -> bool:
	return _active.has(pos)


func is_active(pos: Vector2i) -> bool:
	return _active.get(pos, false)


func set_active(pos: Vector2i, active: bool) -> void:
	var was_active: bool = _active.get(pos, false)
	if was_active == active:
		return

	_active[pos] = active
	if active:
		_add_cell(pos)
	else:
		_remove_cell(pos)
	_groups_dirty = true


func get_groups() -> Array[Array]:
	if _groups_dirty:
		var groups_by_cell: Dictionary[Vector2i, Array] = {}
		for cell: Vector2i in _active:
			if not _active[cell]:
				continue
			var root: Vector2i = _find(cell)
			if not groups_by_cell.has(root):
				groups_by_cell[root] = [] as Array[Vector2i]
			groups_by_cell[root].append(cell)
		_cached_groups = groups_by_cell.values()
		_groups_dirty = false
	
	return _cached_groups


func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i.LEFT,
		pos + Vector2i.RIGHT,
		pos + Vector2i.UP,
		pos + Vector2i.DOWN,
	]


func _find(pos: Vector2i) -> Vector2i:
	if _parent.get(pos) != pos:
		_parent[pos] = _find(_parent[pos])
	return _parent[pos]


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


func _add_cell(pos: Vector2i) -> void:
	_parent[pos] = pos
	_size[pos] = 1
	for neighbor_cell: Vector2i in _get_neighbors(pos):
		if _active.get(neighbor_cell, false):
			_union(pos, neighbor_cell)


func _remove_cell(pos: Vector2i) -> void:
	_active.erase(pos)
	_parent.erase(pos)
	_size.erase(pos)

	# find potentially split neighbors
	var active_neighbor_cells: Array[Vector2i] = []
	for neighbor_cell: Vector2i in _get_neighbors(pos):
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
