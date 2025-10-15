class_name NurikabeUtils
extends Node

## Nurikabe cells:
## 	['0'-'99']: Clue
## 	'!': Invalid (out of bounds)
## 	'': Empty
## 	'.': Island
## 	'##': Wall
const CELL_EMPTY := ""
const CELL_INVALID := "!"
const CELL_ISLAND := "."
const CELL_WALL := "##"

const ERROR_FG_COLOR: Color = Color.WHITE
const ERROR_BG_COLOR: Color = Color("ff5a5a")
const CLUE_LOWLIGHT_COLOR: Color = Color("bbbbbb")
const CLUE_COLOR: Color = Color("666666")
