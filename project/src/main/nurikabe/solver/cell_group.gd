class_name CellGroup

var cells: Array[Vector2i]

## Clue value for this group: 0=none, N=single clue, -1=multiple clues.
var clue: int = 0

var liberties: Array[Vector2i]

func _to_string() -> String:
	return JSON.stringify({
		"cells": cells,
		"clue": clue,
		"liberties": liberties,
	})


func duplicate() -> CellGroup:
	var copy: CellGroup = CellGroup.new()
	copy.cells = cells.duplicate()
	copy.clue = clue
	copy.liberties = liberties.duplicate()
	return copy


## Merges two non-overlapping, non-adjacent groups.
func merge(other_group: CellGroup) -> void:
	cells.append_array(other_group.cells)
	clue = max(clue, other_group.clue) if clue == 0 or other_group.clue == 0 else -1
	var liberties_set: Dictionary[Vector2i, bool] = {}
	for liberty: Vector2i in liberties:
		liberties_set[liberty] = true
	for other_liberty: Vector2i in other_group.liberties:
		if not liberties_set.has(other_liberty):
			liberties.append(other_liberty)


func size() -> int:
	return cells.size()
