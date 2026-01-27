@tool
class_name MonsterCursor
extends Node2D

const OUTLINE_COLOR := Color("353541")
const GHOST_COLOR := Color("35354188")

@export var color: Color

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10, OUTLINE_COLOR, true, -1.0, true)
	draw_circle(Vector2.ZERO, 5, color, true, -1.0, true)
