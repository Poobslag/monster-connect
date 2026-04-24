@tool
class_name PuzzleSpawn
extends Marker3D

@export var max_puzzle_size: Vector2i = Vector2(20, 20):
	set(value):
		max_puzzle_size = value
		%MeshInstance3D.mesh.size = Vector2(max_puzzle_size)

func _ready() -> void:
	if not Engine.is_editor_hint():
		%MeshInstance3D.visible = false
