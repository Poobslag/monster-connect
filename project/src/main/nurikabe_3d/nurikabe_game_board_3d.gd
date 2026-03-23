@tool
class_name NurikabeGameBoard3D
extends Node3D

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = import_grid

@export var tile_size: Vector2 = Vector2(1, 1)

## Cells currently being edited. The value is the most recent monster id performing the edit.
var half_cells: Dictionary[Vector2i, int] = {}:
	set(value):
		half_cells = value
		_cells_dirty = true

var _cells_dirty: bool = false
var _values_by_cell: Dictionary[Vector2i, int] = {}

func _ready() -> void:
	%GroundLayer.tile_size = tile_size
	%ClueLayer.tile_size = tile_size
	
	if not Engine.is_editor_hint():
		import_grid()


func _process(_delta: float) -> void:
	refresh_cells()


func clear_half_cells(player_id: int) -> void:
	for cell: Vector2i in get_half_cells(player_id):
		half_cells.erase(cell)
	_cells_dirty = true


func get_half_cells(player_id: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in half_cells:
		if half_cells[cell] == player_id:
			result.append(cell)
	return result


func has_half_cells(player_id: int) -> bool:
	return half_cells.values().has(player_id)


func import_grid() -> void:
	%GroundLayer.clear()
	%IslandLayer.clear()
	%ClueLayer.clear()
	%WallLayer.clear()
	_values_by_cell.clear()
	
	var cells: Dictionary[Vector2i, int] = NurikabeUtils.cells_from_grid_string(grid_string)
	for cell: Vector2i in cells:
		set_cell(cell, cells[cell])
	
	half_cells = {}


func refresh_cells() -> void:
	if not _cells_dirty:
		return
	_cells_dirty = false
	
	for cell: Vector2i in %IslandLayer.get_used_cells():
		var island_id: int = 0
		if cell in half_cells:
			island_id += 3
		%IslandLayer.set_cell(cell, island_id)
	
	for cell: Vector2i in %WallLayer.get_used_cells():
		var wall_id: int = 0
		if cell in half_cells:
			wall_id += 2
		%WallLayer.set_cell(cell, wall_id)


func set_cell(cell_pos: Vector2i, value: int, _player_id: int = -1) -> void:
	# update cell value
	_set_cell_internal(cell_pos, value)


func get_cell(cell_pos: Vector2i) -> int:
	return _values_by_cell.get(cell_pos, -1)


func set_half_cell(cell_pos: Vector2i, player_id: int) -> void:
	half_cells[cell_pos] = player_id
	_cells_dirty = true


func set_half_cells(cell_positions: Array[Vector2i], player_id: int) -> void:
	for cell_pos: Vector2i in cell_positions:
		half_cells[cell_pos] = player_id
	_cells_dirty = true


## Note: This method should be moved to an input manager, is the logic is global and not per-board.
func get_board_hit_at_mouse() -> Dictionary[String, Variant]:
	var board_hit: Dictionary[String, Variant] = {}
	
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * 200.0
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var query_result: Dictionary = space.intersect_ray(query)
	
	if not query_result.is_empty():
		var board_cell: Node3D = Utils.find_parent_in_group(query_result["collider"], "board_cells")
		if board_cell != null:
			board_hit["board"] = board_cell.get_meta("board")
			board_hit["cell"] = board_cell.get_meta("cell")
	
	return board_hit


func _set_cell_internal(cell_pos: Vector2i, value: int) -> void:
	if value == -1:
		_values_by_cell.erase(cell_pos)
	else:
		_values_by_cell[cell_pos] = value
	
	var ground_id: int = 0 if (cell_pos.x + cell_pos.y) % 2 == 0 else 1
	%GroundLayer.set_cell(cell_pos, ground_id)
	
	var island_id: int
	if value != CELL_ISLAND:
		island_id = -1
	else:
		island_id = 0
		if half_cells.has(cell_pos):
			island_id += 3
	%IslandLayer.set_cell(cell_pos, island_id)
	
	%ClueLayer.set_cell(cell_pos, value)
	
	var wall_id: int
	if value != CELL_WALL:
		wall_id = -1
	else:
		wall_id = 0
		if half_cells.has(cell_pos):
			wall_id += 2
	%WallLayer.set_cell(cell_pos, wall_id)
