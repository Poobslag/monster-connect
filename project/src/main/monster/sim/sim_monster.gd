@tool
class_name SimMonster
extends Monster

const BOREDOM_PER_SECOND: float = 1.6667 # 100 boredom per minute

@onready var input: SimInput = %Input

var game_board: NurikabeGameBoard
var boredom: float = 0.0

func update_input() -> void:
	input.update()


func _process(delta: float) -> void:
	if game_board == null:
		boredom = clamp(boredom + delta * BOREDOM_PER_SECOND, 0, 100)
	else:
		boredom = clamp(boredom - delta * BOREDOM_PER_SECOND, 0, 100)
