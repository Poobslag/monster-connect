@tool
class_name GroundMap
extends GridMap

const PATH_TILE: int = 2

## Template for running arbitrary code in the editor
@export_tool_button("Editor Action") var editor_action: Callable = func() -> void:
	#for x in range(-75, 75):
	#	for z in range(-75, 75):
	#		set_cell_item(Vector3(x, -1, z), 0)
	pass

var _initial_tiles: Dictionary[Vector3i, int] = {}
var _moat_counts: Dictionary[Vector3i, int] = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	for cell: Vector3i in get_used_cells():
		_initial_tiles[cell] = get_cell_item(cell)


func aabb_to_map_rect(aabb: AABB, margin: int = 0) -> Rect2i:
	var moat_from: Vector3i = local_to_map(to_local(aabb.position)) - Vector3i(margin, 0, margin)
	var moat_to: Vector3i = local_to_map(to_local(aabb.end)) + Vector3i(margin + 1, 0, margin + 1)
	return Rect2i(Vector2i(moat_from.x, moat_from.z), Vector2i(moat_to.x - moat_from.x, moat_to.z - moat_from.z))


func moatify(rect: Rect2i) -> void:
	for x in rect.size.x:
		for z in rect.size.y:
			var cell := Vector3i(rect.position.x + x, -1, rect.position.y + z)
			_moat_counts[cell] = _moat_counts.get(cell, 0) + 1
			if _moat_counts[cell] == 1:
				set_cell_item(cell, PATH_TILE)


func unmoatify(rect: Rect2i) -> void:
	for x in rect.size.x:
		for z in rect.size.y:
			var cell := Vector3i(rect.position.x + x, -1, rect.position.y + z)
			_moat_counts[cell] = _moat_counts.get(cell, 0) - 1
			if _moat_counts[cell] <= 0:
				_moat_counts.erase(cell)
				set_cell_item(cell, _initial_tiles.get(cell, INVALID_CELL_ITEM))
