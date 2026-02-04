class_name GridTransform

static func mirror_cells(cells: Dictionary[Variant, Variant]) -> Dictionary[Variant, Variant]:
	var result: Dictionary[Variant, Variant] = {}
	for cell: Vector2i in cells:
		result[Vector2i(-cell.x, cell.y)] = cells[cell]
	result = _normalize_cells(result)
	return result


static func rotate_cells(cells: Dictionary[Variant, Variant], turns: int) -> Dictionary[Variant, Variant]:
	if turns == 0:
		return cells.duplicate()
	
	var result: Dictionary[Variant, Variant] = {}
	for cell: Vector2i in cells:
		var target_cell: Vector2i
		match wrapi(turns, 0, 4):
			0: target_cell = cell
			1: target_cell = Vector2i(-cell.y, cell.x)
			2: target_cell = Vector2i(-cell.x, -cell.y)
			3: target_cell = Vector2i(cell.y, -cell.x)
		result[target_cell] = cells[cell]
	result = _normalize_cells(result)
	return result


static func _normalize_cells(cells: Dictionary[Variant, Variant]) -> Dictionary[Variant, Variant]:
	var result: Dictionary[Variant, Variant] = {}
	var bounds: Rect2i = _bounds(cells)
	for cell: Vector2i in cells:
		result[cell - bounds.position] = cells[cell]
	return result


static func _bounds(cells: Dictionary[Variant, Variant]) -> Rect2i:
	if not cells:
		return Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	
	var result: Rect2i = Rect2i(cells.keys()[0], Vector2i.ZERO)
	for cell: Vector2i in cells:
		result = result.expand(cell)
	result.size += Vector2i.ONE
	return result
