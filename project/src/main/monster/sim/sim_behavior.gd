class_name SimBehavior

const MOTIVATION: String = "motivation" # constantly active and moving

## solving a puzzle
const PUZZLE_CURSOR_COURTESY: String = "puzzle.cursor_courtesy" # avoid other player cursors
const PUZZLE_CURSOR_SPEED: String = "puzzle.cursor_speed" # fast cursor movements, no pauses
const PUZZLE_THINK_SPEED: String = "puzzle.think_speed" # fast at coming up with deductions

## choosing a puzzle
const PUZZLE_SIZE_PREFERENCE: String = "puzzle.size_preference" # prefer large puzzles
const PUZZLE_DIFFICULTY_PREFERENCE: String = "puzzle.difficulty_preference" # prefer hard puzzles
const PUZZLE_PICKINESS: String = "puzzle.pickiness" # strong preferences, will search for a specific puzzle

const STATS_BY_ARCHETYPE: Dictionary[String, Dictionary] = {
	"neutral": {
		MOTIVATION: 5,
		
		PUZZLE_CURSOR_COURTESY: 5,
		PUZZLE_CURSOR_SPEED: 5,
		PUZZLE_THINK_SPEED: 5,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 5,
		PUZZLE_SIZE_PREFERENCE: 5,
		PUZZLE_PICKINESS: 5,
	},
	"rat": {
		# Tenacious, quick witted, social. Happy to tackle the hardest puzzles as a group.
		MOTIVATION: 9,
		
		PUZZLE_CURSOR_COURTESY: 3,
		PUZZLE_CURSOR_SPEED: 10,
		PUZZLE_THINK_SPEED: 9,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 8,
		PUZZLE_SIZE_PREFERENCE: 2,
		PUZZLE_PICKINESS: 8,
	},
	"ox": {
		# Patient, unpretentious, perservering. Plodding and resourceful, just wants to work.
		MOTIVATION: 10,
		
		PUZZLE_CURSOR_COURTESY: 6,
		PUZZLE_CURSOR_SPEED: 0,
		PUZZLE_THINK_SPEED: 0,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 9,
		PUZZLE_SIZE_PREFERENCE: 10,
		PUZZLE_PICKINESS: 0,
	},
	"rabbit": {
		# Open, optimistic, sensitive. Avoids conflict and prefers comfortable, easy puzzles.
		MOTIVATION: 3,
		
		PUZZLE_CURSOR_COURTESY: 10,
		PUZZLE_CURSOR_SPEED: 8,
		PUZZLE_THINK_SPEED: 6,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 1,
		PUZZLE_SIZE_PREFERENCE: 3,
		PUZZLE_PICKINESS: 6,
	},
	"dragon": {
		# Powerful, energetic, ambitious. Visionary leaders who tackle the hardest challenges.
		MOTIVATION: 8,
		
		PUZZLE_CURSOR_COURTESY: 0,
		PUZZLE_CURSOR_SPEED: 4,
		PUZZLE_THINK_SPEED: 10,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 10,
		PUZZLE_SIZE_PREFERENCE: 9,
		PUZZLE_PICKINESS: 5,
	},
	"monkey": {
		# Playful, clever, unpredictable. They follow their whims and take frequent breaks.
		MOTIVATION: 0,
		
		PUZZLE_CURSOR_COURTESY: 2,
		PUZZLE_CURSOR_SPEED: 10,
		PUZZLE_THINK_SPEED: 7,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 5,
		PUZZLE_SIZE_PREFERENCE: 0,
		PUZZLE_PICKINESS: 10,
	},
	"pig": {
		# Cool-headed, intelligent and capable. Chill not competitive, well-liked by friends.
		MOTIVATION: 5,
		
		PUZZLE_CURSOR_COURTESY: 8,
		PUZZLE_CURSOR_SPEED: 2,
		PUZZLE_THINK_SPEED: 2,
		
		PUZZLE_DIFFICULTY_PREFERENCE: 0,
		PUZZLE_SIZE_PREFERENCE: 6,
		PUZZLE_PICKINESS: 9,
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
