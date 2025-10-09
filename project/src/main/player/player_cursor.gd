@tool
extends Node2D

const OUTLINE_COLOR := Color("353541")
const GHOST_COLOR := Color("35354188")

@export var color: Color
@export var ghost: bool = true

func _draw() -> void:
	if ghost:
		draw_circle(Vector2.ZERO, 6, GHOST_COLOR, true, -1.0, true)
	else:
		draw_circle(Vector2.ZERO, 10, OUTLINE_COLOR, true, -1.0, true)
		draw_circle(Vector2.ZERO, 5, color, true, -1.0, true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	position = get_parent().input.cursor_dir
