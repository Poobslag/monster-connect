@tool
extends Node3D

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

@export_multiline var grid_string: String

@export_tool_button("Import Grid String") var import_grid_action: Callable = import_grid

@export var tile_size: Vector2 = Vector2(1, 1)


func _ready() -> void:
	%GroundLayer.tile_size = tile_size
	%ClueLayer.tile_size = tile_size
	
	if not Engine.is_editor_hint():
		import_grid()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Board hit at mouse: %s" % [_get_board_hit_at_mouse()])


## Note: This method should be moved to an input manager, is the logic is global and not per-board.
func _get_board_hit_at_mouse() -> Dictionary[String, Variant]:
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


func import_grid() -> void:
	%GroundLayer.clear()
	%ClueLayer.clear()
	
	var cells: Dictionary[Vector2i, int] = NurikabeUtils.cells_from_grid_string(grid_string)
	for cell: Vector2i in cells:
		set_cell(cell, cells[cell])


func set_cell(cell_pos: Vector2i, value: int, _player_id: int = -1) -> void:
	# update cell value
	_set_cell_internal(cell_pos, value)


func _set_cell_internal(cell_pos: Vector2i, value: int) -> void:
	%GroundLayer.set_cell(cell_pos, value)
	%ClueLayer.set_cell(cell_pos, value)
