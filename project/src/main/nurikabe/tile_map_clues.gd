@tool
extends Node2D

@export var tile_size: Vector2i:
	set(value):
		tile_size = value
		queue_redraw()

@export var font: Font:
	set(value):
		font = value
		queue_redraw()

@export var font_size: int = 16:
	set(value):
		font_size = value
		queue_redraw()

@export var font_padding: float = 0.0:
	set(value):
		font_padding = value
		queue_redraw()

@export var color: Color = Color.BLACK:
	set(value):
		color = value
		queue_redraw()

@export var clues_by_cell: Dictionary[Vector2i, int] = {}:
	set(value):
		clues_by_cell = value
		queue_redraw()

func _draw() -> void:
	for cell: Vector2i in clues_by_cell:
		var clue: int = clues_by_cell[cell]
		var clue_scale := Vector2.ONE if clue <= 9 else Vector2(0.66667, 1)
		draw_set_transform(Vector2(tile_size) * (Vector2(cell) + Vector2.DOWN) + Vector2.UP * font_padding,
				0.0, clue_scale)
		draw_string(font, Vector2.ZERO, str(clue), HORIZONTAL_ALIGNMENT_CENTER,
				tile_size.x / clue_scale.x, font_size, color)


func clear() -> void:
	clues_by_cell.clear()
	notify_property_list_changed()
	queue_redraw()


func erase_cell(cell: Vector2i) -> void:
	clues_by_cell.erase(cell)
	notify_property_list_changed()
	queue_redraw()


func get_cell_clue(cell: Vector2i) -> int:
	return clues_by_cell.get(cell, -1)


func set_cell(cell: Vector2i, value: int) -> void:
	clues_by_cell[cell] = value
	notify_property_list_changed()
	queue_redraw()
