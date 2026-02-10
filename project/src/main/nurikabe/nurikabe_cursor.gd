@tool
extends Sprite2D

const TALL_OFFSET = Vector2(0, -24)
const TEXTURE_TALL_CENTER = preload("res://assets/main/nurikabe/sprites/cursor_tall_center.png")
const TEXTURE_TALL_OUTLINE = preload("res://assets/main/nurikabe/sprites/cursor_tall_outline.png")
const TEXTURE_CENTER = preload("res://assets/main/nurikabe/sprites/cursor_center.png")
const TEXTURE_OUTLINE = preload("res://assets/main/nurikabe/sprites/cursor_outline.png")

@export var tall: bool = false:
	set(value):
		if tall == value:
			return
		tall = value
		_dirty = true

@export var outline_color: Color = Color.BLACK:
	set(value):
		if outline_color == value:
			return
		outline_color = value
		_dirty = true

@export var cursor_color: Color = Color.WHITE:
	set(value):
		if cursor_color == value:
			return
		cursor_color = value
		_dirty = true

var _dirty: bool = false

func _ready() -> void:
	refresh()


func update_cursor(game_board: NurikabeGameBoard, monster: Monster, cell: Vector2i, tile_size: Vector2) -> void:
	if monster:
		cursor_color = monster.cursor.color
	position = (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size
	var cell_value: int = game_board.get_cell(cell)
	tall = true if cell_value == NurikabeUtils.CELL_WALL else false


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if not _dirty:
		return
	
	_dirty = false
	self_modulate = cursor_color
	%Outline.self_modulate = outline_color
	texture = TEXTURE_TALL_CENTER if tall else TEXTURE_CENTER
	%Outline.texture = TEXTURE_TALL_OUTLINE if tall else TEXTURE_OUTLINE
	offset = TALL_OFFSET if tall else Vector2.ZERO
	%Outline.offset = offset
