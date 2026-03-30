@tool
class_name ClueLabel3D
extends Label3D

@export var clue: int:
	set(value):
		if clue == value:
			return
		clue = value
		_refresh()

@export var error: bool:
	set(value):
		if error == value:
			return
		error = value
		_refresh()

@export var lowlight: bool:
	set(value):
		if lowlight == value:
			return
		lowlight = value
		_refresh()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	text = "?" if clue == NurikabeUtils.CELL_MYSTERY_CLUE else str(clue)
	scale.x = 0.66667 if clue >= 10 else 1.0
	if error:
		outline_size = 54
		outline_modulate = NurikabeUtils.ERROR_BG_COLOR
		modulate = NurikabeUtils.ERROR_FG_COLOR
	elif lowlight:
		outline_size = 0
		outline_modulate = Color.BLACK
		modulate = NurikabeUtils.CLUE_LOWLIGHT_COLOR
	else:
		outline_size = 0
		outline_modulate = Color.BLACK
		modulate = NurikabeUtils.CLUE_COLOR
