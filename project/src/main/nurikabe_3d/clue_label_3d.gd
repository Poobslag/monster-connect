@tool
class_name ClueLabel3D
extends Label3D

var clue: int:
	set(value):
		if clue == value:
			return
		clue = value
		_refresh()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	text = "?" if clue == NurikabeUtils.CELL_MYSTERY_CLUE else str(clue)
	scale.x = 0.66667 if clue >= 10 else 1.0
