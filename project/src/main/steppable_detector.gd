extends Area2D

signal stepped_on

signal stepped_off

var on_steppable: bool = false:
	set(value):
		if on_steppable == value:
			return
		on_steppable = value
		if on_steppable:
			stepped_on.emit()
		else:
			stepped_off.emit()

var areas_entered: Dictionary[Area2D, bool] = {}

func _ready() -> void:
	area_entered.connect(func(area: Area2D) -> void:
		areas_entered[area] = true
		on_steppable = not areas_entered.is_empty())
	area_exited.connect(func(area: Area2D) -> void:
		areas_entered.erase(area)
		on_steppable = not areas_entered.is_empty())
