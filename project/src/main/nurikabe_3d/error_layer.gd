@tool
extends TileLayer3D

const ERROR_FLOAT_OFFSET: float = GroundLayer.ERROR_FLOAT_OFFSET

func _prepare_tile(_cell_pos: Vector2i, _cell_value: int, tile: Node3D) -> void:
	tile.position.y = ERROR_FLOAT_OFFSET
