@tool
extends Area2D

@export var tile_size: Vector2

@export var cursorable_rect: Rect2:
	set(value):
		cursorable_rect = value
		_dirty = true

var _dirty: bool = false

func _ready() -> void:
	area_entered.connect(func(_area: Area2D) -> void:
		print("15: entered"))
	area_exited.connect(func(_area: Area2D) -> void:
		print("15: exited"))


func _process(_delta: float) -> void:
	if _dirty:
		$CollisionPolygon2D.polygon = PackedVector2Array([
			cursorable_rect.position,
			cursorable_rect.position + Vector2(cursorable_rect.size.x, 0),
			cursorable_rect.position + Vector2(cursorable_rect.size.x, cursorable_rect.size.y),
			cursorable_rect.position + Vector2(0, cursorable_rect.size.y),
		])
		_dirty = false

func clear() -> void:
	cursorable_rect = Rect2()
	_dirty = true


func set_cell(cell: Vector2i) -> void:
	var to_point: Vector2 = (Vector2(cell) + Vector2.ONE) * tile_size
	if not cursorable_rect.has_point(to_point):
		cursorable_rect = cursorable_rect.expand(to_point)
