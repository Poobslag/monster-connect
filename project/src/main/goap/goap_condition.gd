class_name GoapCondition
extends Node

enum Comparison {
	LessThan,
	LessThanOrEqual,
	GreaterThan,
	GreaterThanOrEqual,
}

const LessThan: Comparison = Comparison.LessThan
const LessThanOrEqual: Comparison = Comparison.LessThanOrEqual
const GreaterThan: Comparison = Comparison.GreaterThan
const GreaterThanOrEqual: Comparison = Comparison.GreaterThanOrEqual

var comparison: Comparison
var value: int

func _init(init_comparison: Comparison, init_value: int) -> void:
	comparison = init_comparison
	value = init_value
