class_name SimBehavior

const MOTIVATION: String = "motivation" # constantly active and moving

## solving a puzzle
const PUZZLE_CURSOR_SPEED: String = "puzzle.cursor_speed" # fast cursor movements, no pauses
const PUZZLE_THINK_SPEED: String = "puzzle.think_speed" # fast at coming up with deductions

## choosing a puzzle
const PUZZLE_SIZE_PREFERENCE: String = "puzzle.size_preference" # prefer large puzzles
const PUZZLE_DIFFICULTY_PREFERENCE: String = "puzzle.difficulty_preference" # prefer hard puzzles
const PUZZLE_PICKINESS: String = "puzzle.pickiness" # strong preferences, will search for a specific puzzle

const STATS_BY_ARCHETYPE: Dictionary[String, Dictionary] = {
	"neutral": {
		PUZZLE_CURSOR_SPEED: 5,
		PUZZLE_THINK_SPEED: 5,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 5,
		PUZZLE_SIZE_PREFERENCE: 5,
		PUZZLE_PICKINESS: 5,
		
		MOTIVATION: 5
	},
	"rat": {
		PUZZLE_CURSOR_SPEED: 8,
		PUZZLE_THINK_SPEED: 8,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 8,
		PUZZLE_SIZE_PREFERENCE: 7,
		PUZZLE_PICKINESS: 6,
		
		MOTIVATION: 8,
	},
	"pig": {
		PUZZLE_CURSOR_SPEED: 2,
		PUZZLE_THINK_SPEED: 2,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 2,
		PUZZLE_SIZE_PREFERENCE: 3,
		PUZZLE_PICKINESS: 8,
		
		MOTIVATION: 4,
	},
}

var stats: Dictionary[String, float] = {}

func get_stat(stat: String) -> float:
	var raw: float = get_stat_raw(stat)
	return inverse_lerp(0, 10, raw)


## Extrapolates a stat along a range with an optional midpoint.[br]
## [br]
## This method accepts a stat, a min/max and an optional midpoint, and returns a biased interpolation following an
## exponential ease. This makes it easier to convert stat values like "0.5" to useful numbers like "300 milliseconds".
func lerp_stat(stat: String, from: float, to: float, avg: float = (from + to) / 2.0) -> float:
	var scaled_avg: float = inverse_lerp(from, to, avg)
	var weight: float = pow(get_stat(stat), log(scaled_avg) / log(0.5))
	return lerp(from, to, weight)


func get_stat_raw(stat: String) -> float:
	var result: float
	if stats.has(stat):
		result = stats.get(stat)
	else:
		result = STATS_BY_ARCHETYPE["neutral"].get(stat, 5.0)
	return result
