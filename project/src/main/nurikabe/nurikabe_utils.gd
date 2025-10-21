class_name NurikabeUtils
extends Node

enum Reason {
	UNKNOWN_REASON,
	
	# starting techniques
	ISLAND_OF_ONE, # surround single-square island with walls
	ADJACENT_CLUES, # two clues separated by one square horizontally/vertically
	DIAGONAL_CLUES, # two clues diagonally adjacent
	
	# rules
	JOINED_ISLAND, # island with 2 or more clues
	UNCLUED_ISLAND, # island with 0 clues
	ISLAND_TOO_LARGE, # large island with a small clue
	ISLAND_TOO_SMALL, # small island with a large clue
	POOLS, # 2x2 grid of wall cells
	SPLIT_WALLS, # wall cells cannot be joined
}

## Nurikabe cells:
## 	['0'-'99']: Clue
## 	'!': Invalid (out of bounds)
## 	'': Empty (unknown, either island or wall)
## 	'.': Island
## 	'##': Wall
const CELL_EMPTY := ""
const CELL_INVALID := "!"
const CELL_ISLAND := "."
const CELL_WALL := "##"

const UNKNOWN_REASON: Reason = Reason.UNKNOWN_REASON

## Starting techniques
const ISLAND_OF_ONE: Reason = Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Reason = Reason.ADJACENT_CLUES
const DIAGONAL_CLUES: Reason = Reason.DIAGONAL_CLUES

## Rules
const JOINED_ISLAND: Reason = Reason.JOINED_ISLAND
const UNCLUED_ISLAND: Reason = Reason.UNCLUED_ISLAND
const ISLAND_TOO_LARGE: Reason = Reason.ISLAND_TOO_LARGE
const ISLAND_TOO_SMALL: Reason = Reason.ISLAND_TOO_SMALL
const POOLS: Reason = Reason.POOLS
const SPLIT_WALLS: Reason = Reason.SPLIT_WALLS

const ERROR_FG_COLOR: Color = Color.WHITE
const ERROR_BG_COLOR: Color = Color("ff5a5a")
const CLUE_LOWLIGHT_COLOR: Color = Color("bbbbbb")
const CLUE_COLOR: Color = Color("666666")

const NEIGHBOR_DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
