@tool
extends TileLayer3D

const GROUND_HEIGHT: float = GroundLayer.GROUND_HEIGHT
const FLOAT_OFFSET_BY_VALUE: Dictionary[int, float] = {
	0: 0.25, # wall
	1: 0.25, # wall error
	2: 0.1, # wall half
	3: 0.1, # wall half error
}

func _prepare_tile(_cell_pos: Vector2i, cell_value: int, tile: Node3D) -> void:
	tile.position.y = GROUND_HEIGHT + FLOAT_OFFSET_BY_VALUE[cell_value]
