@tool
class_name GroundMap
extends GridMap

const PATH_TILE: int = 2

const DITHER_PATTERNS: Dictionary = {
	0: {"variant": 1, "pattern": 0b1111_0000_1111_0000, "imprecision": 0.06}, # grass
	2: {"variant": 3, "pattern": 0b0000_0111_0000_1101, "imprecision": 0.03}, # paths
	4: {"variant": 5, "pattern": 0b1100_0000_0011_0000, "imprecision": 0.09}, # water
}

const DITHER_SEED: int = 0

@export_tool_button("Apply Dithering") var apply_dithering_action: Callable = apply_dithering

@export_tool_button("Unapply Dithering") var unapply_dithering_action: Callable = unapply_dithering

var _initial_tiles: Dictionary[Vector3i, int] = {}
var _moat_counts: Dictionary[Vector3i, int] = {}
var _variant_to_base: Dictionary[int, int] = {}

func _ready() -> void:
	for base: int in DITHER_PATTERNS.keys():
		var dither_pattern: Dictionary = DITHER_PATTERNS[base]
		_variant_to_base[base] = base
		_variant_to_base[dither_pattern["variant"]] = base
	
	if not Engine.is_editor_hint():
		for cell: Vector3i in get_used_cells():
			_initial_tiles[cell] = get_cell_item(cell)


func aabb_to_map_rect(aabb: AABB, margin: int = 0) -> Rect2i:
	var moat_from: Vector3i = local_to_map(to_local(aabb.position)) - Vector3i(margin, 0, margin)
	var moat_to: Vector3i = local_to_map(to_local(aabb.end)) + Vector3i(margin + 1, 0, margin + 1)
	return Rect2i(Vector2i(moat_from.x, moat_from.z), Vector2i(moat_to.x - moat_from.x, moat_to.z - moat_from.z))


func apply_dithering(cells: Array[Vector3i] = get_used_cells()) -> void:
	for cell: Vector3i in cells:
		set_cell_item(cell, _dithered_tile(cell))


func unapply_dithering(cells: Array[Vector3i] = get_used_cells()) -> void:
	for cell: Vector3i in cells:
		var cell_item: int = get_cell_item(cell)
		if not _variant_to_base.has(cell_item):
			continue
		
		set_cell_item(cell, _variant_to_base[cell_item])


func _dithered_tile(cell: Vector3i) -> int:
	var tile: int = get_cell_item(cell)
	if not _variant_to_base.has(tile):
		return tile
	
	var base_tile: int = _variant_to_base[tile]
	var pattern: Dictionary = DITHER_PATTERNS[base_tile]
	var bit_index: int = (cell.x & 3) + (cell.z & 3) * 4
	var use_variant: bool = pattern["pattern"] >> bit_index & 1 == 1
	var h: int = hash(Vector3i(cell.x, DITHER_SEED, cell.z))
	if float(h & 0xffff) / 0xffff < pattern["imprecision"]:
		use_variant = not use_variant
	return pattern["variant"] if use_variant else base_tile


func moatify(rect: Rect2i) -> void:
	for x in rect.size.x:
		for z in rect.size.y:
			var cell := Vector3i(rect.position.x + x, -1, rect.position.y + z)
			_moat_counts[cell] = _moat_counts.get(cell, 0) + 1
			if _moat_counts[cell] == 1:
				set_cell_item(cell, PATH_TILE)
				set_cell_item(cell, _dithered_tile(cell))


func unmoatify(rect: Rect2i) -> void:
	for x in rect.size.x:
		for z in rect.size.y:
			var cell := Vector3i(rect.position.x + x, -1, rect.position.y + z)
			_moat_counts[cell] = _moat_counts.get(cell, 0) - 1
			if _moat_counts[cell] <= 0:
				_moat_counts.erase(cell)
				var new_item: int = _initial_tiles.get(cell, INVALID_CELL_ITEM)
				set_cell_item(cell, new_item)
				if new_item != INVALID_CELL_ITEM:
					set_cell_item(cell, _dithered_tile(cell))
