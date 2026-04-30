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


func get_global_aabb() -> AABB:
	var size: Vector3 = Vector3(max_puzzle_size.x, 0.0, max_puzzle_size.y)
	return AABB(global_position - 0.5 * size, size)
