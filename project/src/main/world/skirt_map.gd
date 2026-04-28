@tool
class_name SkirtMap
extends GridMap

const DIRT_TEXTURE_OFFSET: Vector2i = Vector2i(10, 10)

@export var ground_map: GroundMap

@export var surface_texture: Texture2D

@export_tool_button("Apply Skirt") var apply_skirt_action: Callable = _apply_skirt

@export_tool_button("Unapply Skirt") var unapply_skirt_action: Callable = _unapply_skirt

func _apply_skirt() -> void:
	var cells: Array[Vector3i] = ground_map.get_used_cells()
	for cell: Vector3i in cells:
		var surface_tile: int = ground_map.get_cell_item(cell)
		if surface_tile == GroundMap.BARRIER_TILE:
			continue
		
		var surface_cell_count: int = _noise_range(Vector2i(cell.x, cell.z), 2, 5)
		var skirt_cell: Vector3i = _add_skirt_cells(cell + Vector3i.DOWN, surface_tile, surface_cell_count)
		
		var dirt_tile: int = ground_map.dithered_tile(cell, GroundMap.PATH_TILE)
		var dirt_cell_count: int = _noise_range(Vector2i(cell.x, cell.z) + DIRT_TEXTURE_OFFSET, 2, 5)
		_add_skirt_cells(skirt_cell, dirt_tile, dirt_cell_count)


func _noise_range(pixel: Vector2i, min_val: int, max_val: int) -> int:
	var image: Image = surface_texture.get_image()
	var wrapped_pixel: Vector2i = Vector2i(posmod(pixel.x, image.get_size().x), posmod(pixel.y, image.get_size().y))
	return floori(lerp(float(min_val), float(max_val) - 0.00001, image.get_pixelv(wrapped_pixel).r))


func _add_skirt_cells(skirt_cell: Vector3i, tile: int, count: int) -> Vector3i:
	for i in count:
		set_cell_item(skirt_cell, tile)
		skirt_cell += Vector3i.DOWN
	return skirt_cell


func _unapply_skirt() -> void:
	clear()
