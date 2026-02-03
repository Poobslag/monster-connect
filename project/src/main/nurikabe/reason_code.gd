class_name ReasonCode

const UNKNOWN_REASON: Deduction.Reason = Deduction.Reason.UNKNOWN

## starting reasons
const ISLAND_OF_ONE: Deduction.Reason = Deduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Deduction.Reason = Deduction.Reason.ADJACENT_CLUES

## basic reasons
const CORNER_BUFFER: Deduction.Reason = Deduction.Reason.CORNER_BUFFER
const CORNER_ISLAND: Deduction.Reason = Deduction.Reason.CORNER_ISLAND
const ISLAND_BUBBLE: Deduction.Reason = Deduction.Reason.ISLAND_BUBBLE
const ISLAND_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_BUFFER
const ISLAND_CHAIN: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN
const ISLAND_CHAIN_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN_BUFFER
const ISLAND_CHOKEPOINT: Deduction.Reason = Deduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: Deduction.Reason = Deduction.Reason.ISLAND_CONNECTOR
const ISLAND_DIVIDER: Deduction.Reason = Deduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: Deduction.Reason = Deduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Deduction.Reason = Deduction.Reason.ISLAND_MOAT
const ISLAND_SNUG: Deduction.Reason = Deduction.Reason.ISLAND_SNUG
const POOL_CHOKEPOINT: Deduction.Reason = Deduction.Reason.POOL_CHOKEPOINT
const POOL_TRIPLET: Deduction.Reason = Deduction.Reason.POOL_TRIPLET
const UNCLUED_LIFELINE: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE
const UNCLUED_LIFELINE_BUFFER: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE_BUFFER
const UNREACHABLE_CELL: Deduction.Reason = Deduction.Reason.UNREACHABLE_CELL
const WALL_BUBBLE: Deduction.Reason = Deduction.Reason.WALL_BUBBLE
const WALL_CONNECTOR: Deduction.Reason = Deduction.Reason.WALL_CONNECTOR
const WALL_EXPANSION: Deduction.Reason = Deduction.Reason.WALL_EXPANSION
const WALL_WEAVER: Deduction.Reason = Deduction.Reason.WALL_WEAVER

## advanced reasons
const ASSUMPTION: Deduction.Reason = Deduction.Reason.ASSUMPTION
const BORDER_HUG: Deduction.Reason = Deduction.Reason.BORDER_HUG
const ISLAND_BATTLEGROUND: Deduction.Reason = Deduction.Reason.ISLAND_BATTLEGROUND
const ISLAND_RELEASE: Deduction.Reason = Deduction.Reason.ISLAND_RELEASE
const ISLAND_STRANGLE: Deduction.Reason = Deduction.Reason.ISLAND_STRANGLE
const WALL_STRANGLE: Deduction.Reason = Deduction.Reason.WALL_STRANGLE

const CODES: Dictionary[String, Deduction.Reason] = {
	"-": UNKNOWN_REASON,
	
	# starting reasons
	"i1": ISLAND_OF_ONE,
	"ac": ADJACENT_CLUES,
	
	# basic reasons
	"cb": CORNER_BUFFER,
	"ci": CORNER_ISLAND,
	"ib": ISLAND_BUBBLE,
	"iB": ISLAND_BUFFER,
	"ic": ISLAND_CHAIN,
	"iC": ISLAND_CHAIN_BUFFER,
	"ik": ISLAND_CHOKEPOINT,
	"ie": ISLAND_CONNECTOR,
	"id": ISLAND_DIVIDER,
	"ix": ISLAND_EXPANSION,
	"im": ISLAND_MOAT,
	"is": ISLAND_SNUG,
	"pk": POOL_CHOKEPOINT,
	"p3": POOL_TRIPLET,
	"ul": UNCLUED_LIFELINE,
	"uL": UNCLUED_LIFELINE_BUFFER,
	"ur": UNREACHABLE_CELL,
	"wb": WALL_BUBBLE,
	"we": WALL_CONNECTOR,
	"wx": WALL_EXPANSION,
	"wv": WALL_WEAVER,
	
	"??": ASSUMPTION,
	"Bh": BORDER_HUG,
	"Bg": ISLAND_BATTLEGROUND,
	"Bi": ISLAND_RELEASE,
	"Bj": ISLAND_STRANGLE,
	"Bw": WALL_STRANGLE,
}

static var _codes_by_reason: Dictionary[Deduction.Reason, String]

static func _static_init() -> void:
	for code: String in CODES:
		var reason: Deduction.Reason = CODES[code]
		assert(!reason in _codes_by_reason, "Duplicate reason in ReasonCode: %s" % [reason])
		_codes_by_reason[reason] = code


static func encode(reason: Deduction.Reason) -> String:
	return _codes_by_reason[reason]


static func decode(code: String) -> Deduction.Reason:
	return CODES[code]
