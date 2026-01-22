class_name Goap
extends Node
## Contains goap utilities.

static func greater_than(condition_value: int) -> GoapCondition:
	return GoapCondition.new(GoapCondition.GreaterThan, condition_value)


static func at_least(condition_value: int) -> GoapCondition:
	return GoapCondition.new(GoapCondition.GreaterThanOrEqual, condition_value)


static func less_than(condition_value: int) -> GoapCondition:
	return GoapCondition.new(GoapCondition.LessThan, condition_value)


static func at_most(condition_value: int) -> GoapCondition:
	return GoapCondition.new(GoapCondition.LessThanOrEqual, condition_value)
