extends Node

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var _last_set_cell_from: int = CELL_INVALID
var _last_set_cell_to: int = CELL_INVALID
var _mb_press_cell: Vector2i = POS_NOT_FOUND


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_handle_lmb_press()
		else:
			_handle_lmb_release()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var board_hit: Dictionary[String, Variant] = get_board_hit_at_mouse()
	if board_hit:
		var board: NurikabeGameBoard3D = board_hit["board"]
		var cell: Vector2i = board_hit["cell"]
		%Cursor.visible = true
		%Cursor.position = board.map_to_global(cell)
		%Cursor.position += Vector3(
				board.tile_size.x * 0.5,
				NurikabeGameBoard3D.GROUND_HEIGHT,
				board.tile_size.y * 0.5)
	else:
		%Cursor.visible = false


func get_board_hit_at_mouse() -> Dictionary[String, Variant]:
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
		if query_result["collider"] is GridMap:
			var grid_map: GridMap = query_result["collider"]
			var cell_3: Vector3i = grid_map.local_to_map(grid_map.to_local(query_result["position"]))
			board_hit["board"] = grid_map.get_parent()
			board_hit["cell"] = Vector2i(cell_3.x, cell_3.z)
	
	return board_hit


func _handle_lmb_press() -> void:
	var board_hit: Dictionary[String, Variant] = get_board_hit_at_mouse()
	if not board_hit:
		return
	
	var board: NurikabeGameBoard3D = board_hit["board"]
	var cell: Vector2i = board_hit["cell"]
	var cell_value: int = board.get_cell(cell)
	if cell_value == CELL_EMPTY:
		_mb_press_cell = cell
		_last_set_cell_from = CELL_EMPTY
		_last_set_cell_to = CELL_WALL
		board.set_half_cell(_mb_press_cell, 0)
		board.set_cell(_mb_press_cell, CELL_WALL)
	elif cell_value == CELL_WALL:
		_mb_press_cell = cell
		_last_set_cell_from = CELL_WALL
		_last_set_cell_to = CELL_ISLAND
		board.set_half_cell(_mb_press_cell, 0)
		board.set_cell(_mb_press_cell, CELL_ISLAND)
	elif cell_value == CELL_ISLAND:
		_mb_press_cell = cell
		_last_set_cell_from = CELL_ISLAND
		_last_set_cell_to = CELL_EMPTY
		board.set_half_cell(_mb_press_cell, 0)


func _handle_lmb_release() -> void:
	var board_hit: Dictionary[String, Variant] = get_board_hit_at_mouse()
	if not board_hit:
		return
	
	if _mb_press_cell == POS_NOT_FOUND:
		return
	
	var board: NurikabeGameBoard3D = board_hit["board"]
	if _last_set_cell_to == CELL_EMPTY:
		board.clear_half_cells(0)
		board.set_cell(_mb_press_cell, CELL_EMPTY)
		board.validate()
	elif _last_set_cell_to == CELL_WALL:
		board.clear_half_cells(0)
		board.set_cell(_mb_press_cell, CELL_WALL)
		board.validate()
	elif _last_set_cell_to == CELL_ISLAND:
		board.clear_half_cells(0)
		board.set_cell(_mb_press_cell, CELL_ISLAND)
		board.validate()
