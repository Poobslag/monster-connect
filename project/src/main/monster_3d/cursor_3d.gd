class_name Cursor3D
extends Sprite3D

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

@onready var monster: Monster3D = get_parent()

func raycast(from: Vector3, to: Vector3) -> Dictionary[String, Variant]:
	var board_hit: Dictionary[String, Variant] = _execute_raycast(from, to)
	_update_cursor(board_hit)
	return board_hit


func _execute_raycast(from: Vector3, to: Vector3) -> Dictionary[String, Variant]:
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0b00000000_00000000_00000000_00010000
	var query_result: Dictionary = space.intersect_ray(query)
	
	var board_hit: Dictionary[String, Variant] = {}
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


func _update_cursor(board_hit: Dictionary[String, Variant]) -> void:
	if board_hit and board_hit["type"] == "board" and board_hit["cell"] != POS_NOT_FOUND:
		var board: NurikabeGameBoard3D = board_hit["board"]
		var cell: Vector2i = board_hit["cell"]
		%PuzzleCursor.visible = true
		%PuzzleCursor.global_position = board.map_to_global(cell)
		%PuzzleCursor.global_position.y += NurikabeGameBoard3D.GROUND_HEIGHT
		monster.cursor_board = board
	else:
		%PuzzleCursor.visible = false
		monster.cursor_board = null
