class_name DeductionScorer

const UNKNOWN_REASON: Deduction.Reason = Deduction.Reason.UNKNOWN

## break-in techniques
const ISLAND_OF_ONE: Deduction.Reason = Deduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Deduction.Reason = Deduction.Reason.ADJACENT_CLUES

## easy techniques
const ISLAND_BUBBLE: Deduction.Reason = Deduction.Reason.ISLAND_BUBBLE
const ISLAND_DIVIDER: Deduction.Reason = Deduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: Deduction.Reason = Deduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Deduction.Reason = Deduction.Reason.ISLAND_MOAT
const POOL_TRIPLET: Deduction.Reason = Deduction.Reason.POOL_TRIPLET
const WALL_BUBBLE: Deduction.Reason = Deduction.Reason.WALL_BUBBLE
const WALL_EXPANSION: Deduction.Reason = Deduction.Reason.WALL_EXPANSION

## standard techniques
const CORNER_BUFFER: Deduction.Reason = Deduction.Reason.CORNER_BUFFER
const CORNER_ISLAND: Deduction.Reason = Deduction.Reason.CORNER_ISLAND
const ISLAND_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_BUFFER
const ISLAND_CHAIN: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN
const ISLAND_CHAIN_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN_BUFFER
const ISLAND_CHOKEPOINT: Deduction.Reason = Deduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: Deduction.Reason = Deduction.Reason.ISLAND_CONNECTOR
const ISLAND_SNUG: Deduction.Reason = Deduction.Reason.ISLAND_SNUG
const POOL_CHOKEPOINT: Deduction.Reason = Deduction.Reason.POOL_CHOKEPOINT
const UNCLUED_LIFELINE: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE
const UNCLUED_LIFELINE_BUFFER: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE_BUFFER
const UNREACHABLE_CELL: Deduction.Reason = Deduction.Reason.UNREACHABLE_CELL
const WALL_CONNECTOR: Deduction.Reason = Deduction.Reason.WALL_CONNECTOR
const WALL_WEAVER: Deduction.Reason = Deduction.Reason.WALL_WEAVER

## advanced techniques
const ASSUMPTION: Deduction.Reason = Deduction.Reason.ASSUMPTION
const BORDER_HUG: Deduction.Reason = Deduction.Reason.BORDER_HUG
const ISLAND_BATTLEGROUND: Deduction.Reason = Deduction.Reason.ISLAND_BATTLEGROUND
const ISLAND_RELEASE: Deduction.Reason = Deduction.Reason.ISLAND_RELEASE
const ISLAND_STRANGLE: Deduction.Reason = Deduction.Reason.ISLAND_STRANGLE
const WALL_STRANGLE: Deduction.Reason = Deduction.Reason.WALL_STRANGLE

const FUN_TRIVIAL: Deduction.FunAxis = Deduction.FunAxis.FUN_TRIVIAL
const FUN_FAST: Deduction.FunAxis = Deduction.FunAxis.FUN_FAST
const FUN_NOVELTY: Deduction.FunAxis = Deduction.FunAxis.FUN_NOVELTY
const FUN_THINK: Deduction.FunAxis = Deduction.FunAxis.FUN_THINK
const FUN_BIFURCATE: Deduction.FunAxis = Deduction.FunAxis.FUN_BIFURCATE

const DEDUCTION_PRIORITY_FOR_REASON: Dictionary[Deduction.Reason, float] = {
	# break-in techniques
	ISLAND_OF_ONE: 20.0,
	ADJACENT_CLUES: 20.0,
	
	# easy techniques
	ISLAND_BUBBLE: 10.0,
	ISLAND_DIVIDER: 10.0,
	ISLAND_EXPANSION: 10.0,
	ISLAND_MOAT: 10.0,
	POOL_TRIPLET: 10.0,
	WALL_BUBBLE: 10.0,
	WALL_EXPANSION: 10.0,
	
	# standard techniques
	CORNER_BUFFER: 5.0,
	CORNER_ISLAND: 5.0,
	ISLAND_BUFFER: 5.0,
	ISLAND_CHAIN: 5.0,
	ISLAND_CHAIN_BUFFER: 5.0,
	ISLAND_CHOKEPOINT: 5.0,
	ISLAND_CONNECTOR: 5.0,
	ISLAND_SNUG: 5.0,
	POOL_CHOKEPOINT: 5.0,
	UNCLUED_LIFELINE: 5.0,
	UNCLUED_LIFELINE_BUFFER: 5.0,
	UNREACHABLE_CELL: 5.0,
	WALL_CONNECTOR: 5.0,
	WALL_WEAVER: 5.0,
	
	# advanced techniques; low priority
	ASSUMPTION: 0.0,
	BORDER_HUG: 0.0,
	ISLAND_BATTLEGROUND: 0.0,
	ISLAND_RELEASE: 0.0,
	ISLAND_STRANGLE: 0.0,
	WALL_STRANGLE: 0.0,
	
	UNKNOWN_REASON: 0.0,
}

const DEDUCTION_DELAY_FOR_REASON: Dictionary[Deduction.Reason, float] = {
	UNKNOWN_REASON: 10.0,
	
	# break-in techniques
	ISLAND_OF_ONE: 0.4,
	ADJACENT_CLUES: 0.4,
	
	# easy techniques
	ISLAND_BUBBLE: 0.8,
	ISLAND_DIVIDER: 0.8,
	ISLAND_EXPANSION: 0.8,
	ISLAND_MOAT: 0.8,
	POOL_TRIPLET: 0.8,
	WALL_BUBBLE: 0.8,
	WALL_EXPANSION: 0.8,
	
	# standard techniques
	CORNER_BUFFER: 1.2,
	CORNER_ISLAND: 1.2,
	ISLAND_BUFFER: 1.2,
	ISLAND_CHAIN: 1.2,
	ISLAND_CHAIN_BUFFER: 1.2,
	ISLAND_CHOKEPOINT: 1.2,
	ISLAND_CONNECTOR: 1.2,
	ISLAND_SNUG: 1.2,
	POOL_CHOKEPOINT: 1.2,
	UNCLUED_LIFELINE: 1.2,
	UNCLUED_LIFELINE_BUFFER: 1.2,
	UNREACHABLE_CELL: 1.2,
	WALL_CONNECTOR: 1.2,
	WALL_WEAVER: 1.2,
	
	# advanced techniques
	ASSUMPTION: 3.6,
	BORDER_HUG: 3.6,
	ISLAND_BATTLEGROUND: 3.6,
	ISLAND_RELEASE: 3.6,
	ISLAND_STRANGLE: 3.6,
	WALL_STRANGLE: 3.6,
}


static func get_delay(reason: Deduction.Reason) -> float:
	return DEDUCTION_DELAY_FOR_REASON.get(reason, 0.6)


static func get_priority(reason: Deduction.Reason) -> float:
	return DEDUCTION_PRIORITY_FOR_REASON.get(reason, 0.0)
