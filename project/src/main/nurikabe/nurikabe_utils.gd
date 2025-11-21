class_name NurikabeUtils
extends Node

## Nurikabe cells:
## 	0: Invalid (out of bounds)
## 	1-255: Clue
## 	256: Island
## 	257: Wall
## 	258: Empty (unknown, either island or wall)
const CELL_INVALID := 0
const CELL_ISLAND := 256
const CELL_WALL := 258
const CELL_EMPTY := 257

## Nurikabe cell strings:
## 	['0'-'99']: Clue
## 	'!': Invalid (out of bounds)
## 	'': Empty (unknown, either island or wall)
## 	'.': Island
## 	'##': Wall
const CELL_STRING_EMPTY := ""
const CELL_STRING_INVALID := "!"
const CELL_STRING_ISLAND := "."
const CELL_STRING_WALL := "##"

const ERROR_FG_COLOR: Color = Color.WHITE
const ERROR_BG_COLOR: Color = Color("ff5a5a")
const CLUE_LOWLIGHT_COLOR: Color = Color("bbbbbb")
const CLUE_COLOR: Color = Color("666666")

const POS_NOT_FOUND: Vector2i = Vector2i(-1, -1)

const NEIGHBOR_DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


static func pool_triplet(cell: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	return [cell + dir, cell + Vector2i(dir.x, 0), cell + Vector2i(0, dir.y)]


static func is_clue(value: int) -> int:
	return value >= 1 and value <= 255


static func to_cell_string(value: int) -> String:
	match value:
		CELL_INVALID: return CELL_STRING_INVALID
		CELL_ISLAND: return CELL_STRING_ISLAND
		CELL_WALL: return CELL_STRING_WALL
		CELL_EMPTY: return CELL_STRING_EMPTY
		_: return str(value)


static func from_cell_string(value: String) -> int:
	match value.strip_edges():
		CELL_STRING_INVALID: return CELL_INVALID
		CELL_STRING_ISLAND: return CELL_ISLAND
		CELL_STRING_WALL: return CELL_WALL
		CELL_STRING_EMPTY: return CELL_EMPTY
		_: return value.to_int()
