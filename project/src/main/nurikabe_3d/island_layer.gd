@tool
extends TileLayer3D

func _prepare_tile(_cell_pos: Vector2i, _cell_value: int, tile: Node3D) -> void:
	tile.position.y = GroundLayer.TEXT_FLOAT_OFFSET
