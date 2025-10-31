class_name NurikabeDeduction

var pos: Vector2i
var value: String
var reason: NurikabeSolver.Reason

func _init(init_pos: Vector2i, init_value: String, init_reason: NurikabeSolver.Reason) -> void:
	pos = init_pos
	value = init_value
	reason = init_reason


func to_change() -> Dictionary[String, Variant]:
	return {"pos": pos, "value": value}


func _to_string() -> String:
	return "%s->%s (%s)" % [pos, value, Utils.enum_to_snake_case(NurikabeSolver.Reason, reason),]
