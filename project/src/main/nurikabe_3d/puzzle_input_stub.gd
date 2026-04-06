extends Node

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var mouse_hit: Dictionary[String, Variant] = get_hit_at_mouse()
	if _is_valid_board_hit(mouse_hit):
		var board: NurikabeGameBoard3D = mouse_hit["board"]
		var cell: Vector2i = mouse_hit["cell"]
		%Cursor.visible = true
		%Cursor.position = board.map_to_global(cell)
		%Cursor.position += Vector3(
				board.tile_size.x * 0.5,
				NurikabeGameBoard3D.GROUND_HEIGHT,
				board.tile_size.y * 0.5)
		%Player.cursor_board = board
	else:
		%Cursor.visible = false
		%Player.cursor_board = null
	
	if mouse_hit:
		%Player.cursor_3d.global_position = mouse_hit["position"]


func get_hit_at_mouse() -> Dictionary[String, Variant]:
	var board_hit: Dictionary[String, Variant] = {}
	
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * 200.0
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 0b00000000_00000000_00000000_00010000
	var query_result: Dictionary = space.intersect_ray(query)
	
	if not query_result.is_empty():
		board_hit.assign(query_result)
		board_hit["type"] = "unknown"
	
	if not query_result.is_empty() and query_result["collider"] is GridMap:
		board_hit["type"] = "board"
		var grid_map: GridMap = query_result["collider"]
		var cell_3: Vector3i = grid_map.local_to_map(grid_map.to_local(query_result["position"]))
		board_hit["board"] = grid_map.get_parent()
		if grid_map.get_cell_item(cell_3) == -1:
			board_hit["cell"] = POS_NOT_FOUND
		else:
			board_hit["cell"] = Vector2i(cell_3.x, cell_3.z)
	
	return board_hit


func _is_valid_board_hit(mouse_hit: Dictionary[String, Variant]) -> bool:
	return mouse_hit and mouse_hit["type"] == "board" and mouse_hit["cell"] != POS_NOT_FOUND
