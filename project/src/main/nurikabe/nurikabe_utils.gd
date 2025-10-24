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
	
	# basic techniques
	CORNER_ISLAND, # add a wall diagonally from an island with only two directions to expand
	ISLAND_BUBBLE, # fill in a square surrounded by islands
	ISLAND_BUFFER, # add a wall to preserve space for an island to grow
	ISLAND_CHOKEPOINT, # expand an island through a chokepoint
	ISLAND_CONNECTOR, # connect a clueless island to a clued island
	ISLAND_DIVIDER, # fill in a square to keep two clued islands apart
	ISLAND_EXPANSION, # expand an island in the only possible direction
	ISLAND_MOAT, # seal a completed island with walls
	POOL_TRIPLET, # fill in the fourth cell to prevent a 2x2 grid of wall cells
	UNREACHABLE_SQUARE, # fill in a square which no clue can reach
	WALL_BUBBLE, # fill in a square surrounded by walls
	WALL_CONNECTOR, # connect two walls through a chokepoint
	WALL_EXPANSION, # expand a wall in the only possible direction
	
	# advanced techniques
	BIFURCATION, # fill in a square if the opposite assumption leads to a contradiction
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

## Basic techniques
const WALL_BUBBLE: Reason = Reason.WALL_BUBBLE
const ISLAND_BUBBLE: Reason = Reason.ISLAND_BUBBLE
const WALL_EXPANSION: Reason = Reason.WALL_EXPANSION
const WALL_CONNECTOR: Reason = Reason.WALL_CONNECTOR
const ISLAND_EXPANSION: Reason = Reason.ISLAND_EXPANSION
const ISLAND_CHOKEPOINT: Reason = Reason.ISLAND_CHOKEPOINT
const CORNER_ISLAND: Reason = Reason.CORNER_ISLAND
const ISLAND_BUFFER: NurikabeUtils.Reason = Reason.ISLAND_BUFFER
const ISLAND_CONNECTOR: Reason = Reason.ISLAND_CONNECTOR
const ISLAND_MOAT: Reason = Reason.ISLAND_MOAT
const POOL_TRIPLET: Reason = Reason.POOL_TRIPLET
const UNREACHABLE_SQUARE: Reason = Reason.UNREACHABLE_SQUARE
const ISLAND_DIVIDER: Reason = Reason.ISLAND_DIVIDER

## Advanced techniques
const BIFURCATION: Reason = Reason.BIFURCATION

const ERROR_FG_COLOR: Color = Color.WHITE
const ERROR_BG_COLOR: Color = Color("ff5a5a")
const CLUE_LOWLIGHT_COLOR: Color = Color("bbbbbb")
const CLUE_COLOR: Color = Color("666666")

const NEIGHBOR_DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
