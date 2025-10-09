@tool
extends Node2D

const OUTLINE_COLOR := Color("353541")

@export var color: Color

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10, OUTLINE_COLOR, true, -1.0, true)
	draw_circle(Vector2.ZERO, 5, color, true, -1.0, true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var character_center: Vector2 = -Vector2(0, 60)
	position = (get_parent().input.cursor_dir - character_center).limit_length(256) + character_center
