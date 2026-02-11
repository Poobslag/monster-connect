class_name SimBehavior

const PUZZLE_CURSOR_SPEED: String = "puzzle.cursor_speed"
const PUZZLE_THINK_SPEED: String = "puzzle.think_speed"

const STATS_BY_ARCHETYPE: Dictionary[String, Dictionary] = {
	"neutral": {
		PUZZLE_CURSOR_SPEED: 5,
		PUZZLE_THINK_SPEED: 5,
	},
	"rat": {
		PUZZLE_CURSOR_SPEED: 8,
		PUZZLE_THINK_SPEED: 8,
	},
	"pig": {
		PUZZLE_CURSOR_SPEED: 2,
		PUZZLE_THINK_SPEED: 2,
	},
}

var stats: Dictionary[String, float] = {}

func get_stat(stat: String) -> float:
	var raw: float = get_stat_raw(stat)
	return inverse_lerp(0, 10, raw)


func get_stat_raw(stat: String) -> float:
	var result: float
	if stats.has(stat):
		result = stats.get(stat)
	else:
		result = STATS_BY_ARCHETYPE["neutral"].get(stat, 5.0)
	return result
