class_name BulkGenerator
extends Node
## [b]Keys:[/b][br]
## 	[kbd]G[/kbd]: Toggle generator, continuously writes new puzzles to GENERATED_PUZZLE_DIR.
## 	[kbd]A[/kbd]: Toggle analyzer; analyzes puzzles in PUZZLE_DIR and writes .info files.

const PUZZLE_DIR: String = "res://assets/main/nurikabe/official"
const GENERATED_PUZZLE_DIR: String = "res://assets/main/nurikabe/official/generated"

const MAX_LINES: int = 500
const PUZZLE_TYPES: Array[Dictionary] = [
	{
		"id": "micro",
		"weight": 5.0,
		"cells_mean": 40,
		"cells_spread": 15,
		"cells_min": 25,
		"cells_max": 60,
		
		"difficulty_mean": 0.1,
		"difficulty_spread": 0.3,
	},
	{
		"id": "small",
		"weight": 25.0,
		"cells_mean": 80,
		"cells_spread": 20,
		"cells_min": 50,
		"cells_max": 100,
		
		"difficulty_mean": 0.2,
		"difficulty_spread": 0.3,
	},
	{
		"id": "medium",
		"weight": 25.0,
		"cells_mean": 120,
		"cells_spread": 40,
		"cells_min": 90,
		"cells_max": 180,
		
		"difficulty_mean": 0.3,
		"difficulty_spread": 0.3,
	},
	{
		"id": "large",
		"weight": 12.0,
		"cells_mean": 200,
		"cells_spread": 60,
		"cells_min": 150,
		"cells_max": 300,
		
		"difficulty_mean": 0.4,
		"difficulty_spread": 0.3,
	},
	{
		"id": "xl",
		"weight": 8.0,
		"cells_mean": 330,
		"cells_spread": 120,
		"cells_min": 240,
		"cells_max": 480,
		
		"difficulty_mean": 0.5,
		"difficulty_spread": 0.3,
	},
	{
		"id": "xxl",
		"weight": 4.0,
		"cells_mean": 550,
		"cells_spread": 200,
		"cells_min": 400,
		"cells_max": 800,
		
		"difficulty_mean": 0.6,
		"difficulty_spread": 0.3,
	},
]

var fixed_seed: int = -1

func _ready() -> void:
	%GameBoard.allow_unclued_islands = true


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_G:
			toggle_state("generate")
		KEY_A:
			toggle_state("analyze")


func _process(delta: float) -> void:
	%StateMachine.update(delta)


func toggle_state(state: String) -> void:
	var old_state: String = %StateMachine.current_state
	%StateMachine.change_state("idle" if %StateMachine.current_state == state else state)
	show_message("state: %s -> %s" % [old_state, %StateMachine.current_state])


func show_message(s: String) -> void:
	if %MessageLabel.text:
		%MessageLabel.text += "\n"
	%MessageLabel.text += s
	while %MessageLabel.get_line_count() > MAX_LINES:
		%MessageLabel.text = StringUtils.substring_after(%MessageLabel.text, "\n")
