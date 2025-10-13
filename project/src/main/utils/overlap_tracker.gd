extends Area2D

signal overlap_started

signal overlap_ended

var has_overlap: bool = false:
	set(value):
		if has_overlap == value:
			return
		has_overlap = value
		if has_overlap:
			overlap_started.emit()
		else:
			overlap_ended.emit()

var overlaps: Dictionary[Area2D, bool] = {}

func _ready() -> void:
	area_entered.connect(func(area: Area2D) -> void:
		overlaps[area] = true
		has_overlap = not overlaps.is_empty())
	area_exited.connect(func(area: Area2D) -> void:
		overlaps.erase(area)
		has_overlap = not overlaps.is_empty())
