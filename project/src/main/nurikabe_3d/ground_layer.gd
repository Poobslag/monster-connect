@tool
class_name GroundLayer
extends TileLayer3D

const GROUND_HEIGHT: float = 0.050
const TEXT_FLOAT_OFFSET: float = 0.052
const ERROR_FLOAT_OFFSET: float = 0.051

func _prepare_tile(cell_pos: Vector2i, _cell_value: int, tile: Node3D) -> void:
	# Assign tile group and metadata for raycasting. Maps colliders back to their board and cell.
	# Only ground tiles are clickable -- walls aren't, to avoid click targets shifting as walls are toggled.
	var child: MeshInstance3D = tile.get_child(0)
	child.set_layer_mask_value(Global.LAYER_CLICKABLE, true)
	tile.add_to_group("board_cells")
	
	if not Engine.is_editor_hint():
		# Metadata is runtime-only. Serializing it would bloat the .tscn.
		tile.set_meta("board", get_parent())
		tile.set_meta("cell", cell_pos)
