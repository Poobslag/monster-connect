@tool
extends Control

@export_multiline var grid_string: String
@export_tool_button("Import Grid String") var import_grid_action: Callable = _import_grid

func _ready() -> void:
	if not Engine.is_editor_hint():
		for cell: Vector2i in %TileMapObject.get_used_cells():
			%SteppableTiles.set_cell(cell)


func _import_grid() -> void:
	%TileMapGround.clear()
	%TileMapClues.clear()
	%TileMapObject.clear()
	if not Engine.is_editor_hint():
		%SteppableTiles.clear()
	%CursorableArea.clear()
	var grid_string_rows: PackedStringArray = grid_string.split("\n")
	for y in grid_string_rows.size():
		var row_string: String = grid_string_rows[y]
		@warning_ignore("integer_division")
		for x in row_string.length() / 2:
			_assign_cell_from_string(Vector2i(x, y), row_string.substr(x * 2, 2).strip_edges())


func _erase_cell(cell: Vector2i) -> void:
	%TileMapGround.erase_cell(cell)
	%TileMapClues.erase_cell(cell)
	%TileMapObject.erase_cell(cell)
	if not Engine.is_editor_hint():
		%SteppableTiles.erase_cell(cell)


func _assign_cell_from_string(cell: Vector2i, string: String) -> void:
	if string.is_valid_int():
		%TileMapClues.set_cell(cell, int(string))
	else:
		%TileMapClues.erase_cell(cell)
	
	var object_id: int = 0 if string == "##" else -1
	%TileMapObject.set_cell(cell, object_id, Vector2.ZERO)
	
	if not Engine.is_editor_hint():
		if object_id == -1:
			%SteppableTiles.set_cell(cell)
		elif object_id == 0:
			%SteppableTiles.erase(cell)
	
	var ground_id: int = 1 if string == "." else 0
	%TileMapGround.set_cell(cell, ground_id, Vector2.ZERO)
	
	%CursorableArea.set_cell(cell)
