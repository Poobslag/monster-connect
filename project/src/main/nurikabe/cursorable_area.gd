@tool
class_name CursorableArea
extends Area2D

@export var cursor_scene: PackedScene

@export var tile_size: Vector2

@export var cursorable_rect: Rect2:
	set(value):
		cursorable_rect = value
		_dirty = true

var _cursors_by_area: Dictionary[Area2D, Node2D] = {}

var _dirty: bool = false

func _ready() -> void:
	remove_all_cursors()
	area_entered.connect(func(area: Area2D) -> void:
		add_cursor(area))
	area_exited.connect(func(area: Area2D) -> void:
		remove_cursor(area))


func _process(_delta: float) -> void:
	if _dirty:
		$CollisionPolygon2D.polygon = PackedVector2Array([
			cursorable_rect.position,
			cursorable_rect.position + Vector2(cursorable_rect.size.x, 0),
			cursorable_rect.position + Vector2(cursorable_rect.size.x, cursorable_rect.size.y),
			cursorable_rect.position + Vector2(0, cursorable_rect.size.y),
		])
		_dirty = false
	
	for area: Area2D in _cursors_by_area:
		update_cursor(area)


func add_cursor(area: Area2D) -> void:
	var cursor: Node2D = cursor_scene.instantiate()
	cursor.z_index = 1
	_cursors_by_area[area] = cursor
	%Cursors.add_child(cursor)
	update_cursor(area)
	
	var monster: Monster = _find_monster_for_cursor(area)
	if monster:
		monster.current_game_board = _find_game_board()


func remove_cursor(area: Area2D) -> void:
	var cursor: Node2D = _cursors_by_area[area]
	_cursors_by_area.erase(area)
	cursor.queue_free()
	
	var monster: Monster = _find_monster_for_cursor(area)
	if monster and monster.current_game_board == _find_game_board():
		monster.current_game_board = null


func update_cursor(area: Area2D) -> void:
	var cursor: Node2D = _cursors_by_area[area]
	
	var area_local_position: Vector2 = get_global_transform().affine_inverse() * area.global_position
	var cursor_cell: Vector2i = (area_local_position / tile_size - Vector2(0.5, 0.5)).snapped(Vector2.ONE)
	cursor_cell = cursor_cell.clamp(Vector2i.ZERO, Vector2i(cursorable_rect.size / tile_size) - Vector2i.ONE)
	
	var monster: Monster = _find_monster_for_cursor(area)
	var game_board: Node = _find_game_board()
	
	cursor.update_cursor(game_board, monster, cursor_cell, tile_size)


func remove_all_cursors() -> void:
	for area: Area2D in _cursors_by_area.duplicate():
		remove_cursor(area)
	for cursor in %Cursors.get_children():
		cursor.queue_free()


func clear() -> void:
	cursorable_rect = Rect2()
	_dirty = true


func set_cell(cell: Vector2i) -> void:
	var to_point: Vector2 = (Vector2(cell) + Vector2.ONE) * tile_size
	if not cursorable_rect.has_point(to_point):
		cursorable_rect = cursorable_rect.expand(to_point)


func _find_game_board() -> NurikabeGameBoard:
	return Utils.find_parent_of_type(self, NurikabeGameBoard)


func _find_monster_for_cursor(area: Area2D) -> Monster:
	return Utils.find_parent_of_type(area, Monster)
