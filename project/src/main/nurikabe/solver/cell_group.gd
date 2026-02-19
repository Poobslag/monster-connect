class_name CellGroup

var cells: Array[Vector2i]

var root: Vector2i:
	get():
		return cells.front() if not cells.is_empty() else NurikabeUtils.POS_NOT_FOUND

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


func get_remaining_capacity() -> int:
	return clue - cells.size() if clue != NurikabeUtils.CELL_MYSTERY_CLUE else 999999


## Merges two non-overlapping, non-adjacent groups.
func merge(other_group: CellGroup) -> void:
	cells.append_array(other_group.cells)
	clue = merge_clue_values(clue, other_group.clue)
	var liberties_set: Dictionary[Vector2i, bool] = {}
	for liberty: Vector2i in liberties:
		liberties_set[liberty] = true
	for other_liberty: Vector2i in other_group.liberties:
		if not liberties_set.has(other_liberty):
			liberties.append(other_liberty)


func size() -> int:
	return cells.size()


static func merge_clue_values(a: int, b: int) -> int:
	if a == 0:
		return b
	elif b == 0:
		return a
	else:
		return -1
