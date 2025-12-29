class_name NurikabeUtils
extends Node

## Nurikabe cells:
## 	0: Invalid (out of bounds)
## 	1-255: Clue
## 	256: Island
## 	257: Empty (unknown, either island or wall)
## 	258: Wall
## 	259: Clue (unknown size)
const CELL_INVALID := 0
const CELL_ISLAND := 256
const CELL_EMPTY := 257
const CELL_WALL := 258
const CELL_MYSTERY_CLUE := 259

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
const CELL_STRING_MYSTERY_CLUE := "?"

const ERROR_FG_COLOR: Color = Color.WHITE
const ERROR_BG_COLOR: Color = Color("ff5a5a")
const CLUE_LOWLIGHT_COLOR: Color = Color("bbbbbb")
const CLUE_COLOR: Color = Color("666666")

const POS_NOT_FOUND: Vector2i = Vector2i(-1, -1)

const NEIGHBOR_DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const NEIGHBOR_DIRS_WITH_SELF: Array[Vector2i] = [Vector2i.ZERO,
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

static func pool_triplet(cell: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	return [cell + dir, cell + Vector2i(dir.x, 0), cell + Vector2i(0, dir.y)]


static func is_clue(value: int) -> int:
	return value >= 1 and value <= 255 or value == CELL_MYSTERY_CLUE


static func to_cell_string(value: int) -> String:
	match value:
		CELL_INVALID: return CELL_STRING_INVALID
		CELL_ISLAND: return CELL_STRING_ISLAND
		CELL_WALL: return CELL_STRING_WALL
		CELL_EMPTY: return CELL_STRING_EMPTY
		CELL_MYSTERY_CLUE: return CELL_STRING_MYSTERY_CLUE
		_: return str(value)


static func from_cell_string(value: String) -> int:
	match value.strip_edges():
		CELL_STRING_INVALID: return CELL_INVALID
		CELL_STRING_ISLAND: return CELL_ISLAND
		CELL_STRING_WALL: return CELL_WALL
		CELL_STRING_EMPTY: return CELL_EMPTY
		CELL_STRING_MYSTERY_CLUE: return CELL_MYSTERY_CLUE
		_: return value.to_int()


static func load_grid_string_from_file(puzzle_path: String) -> String:
	var s: String = FileAccess.get_file_as_string(puzzle_path)
	var grid_string: String
	if puzzle_path.ends_with(".janko"):
		grid_string = _parse_janko_text(s)
	else:
		grid_string = _parse_mc_text(s)
	return grid_string


static func _parse_mc_text(file_text: String) -> String:
	var puzzle_lines: Array[String] = []
	var file_lines: PackedStringArray = file_text.split("\n")
	for file_line: String in file_lines:
		if file_line.begins_with("//"):
			continue
		puzzle_lines.append(file_line)
	return "\n".join(PackedStringArray(puzzle_lines))


## Test data includes Nurikabe puzzles scraped from janko.at for solver development and benchmarking. These files are
## not distributed with Monster Connect.
static func _parse_janko_text(file_text: String) -> String:
	var janko_section: String
	var puzzle_lines: Array[String] = []
	var janko_lines: PackedStringArray = file_text.split("\n")
	for janko_line: String in janko_lines:
		if janko_line.begins_with("["):
			janko_section = janko_line
		elif janko_section == "[problem]":
			if janko_line == "":
				# some files end with a blank line
				continue
			var janko_line_split: PackedStringArray = janko_line.split(" ")
			var puzzle_cells_split: Array[String] = []
			for janko_cell: String in janko_line_split:
				var puzzle_cell: String = CELL_STRING_EMPTY
				if janko_cell == "":
					# some lines end with a blank character
					continue
				elif janko_cell == "-":
					puzzle_cell = CELL_STRING_EMPTY
				elif janko_cell.is_valid_int() and janko_cell.length() <= 2:
					puzzle_cell = janko_cell
				else:
					push_warning("Invalid cell in %s: %s" % [file_text, puzzle_cell])
				puzzle_cells_split.append(puzzle_cell.lpad(2))
			puzzle_lines.append("".join(puzzle_cells_split))
	return "\n".join(PackedStringArray(puzzle_lines))
