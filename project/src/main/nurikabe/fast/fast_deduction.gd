class_name FastDeduction

var pos: Vector2i
var value: String
var reason: String

func _init(init_pos: Vector2i, init_value: String, init_reason: String) -> void:
	pos = init_pos
	value = init_value
	reason = init_reason


func to_change() -> Dictionary[String, Variant]:
	return {"pos": pos, "value": value}


func _to_string() -> String:
	return "%s->%s (%s)" % [pos, value, reason,]
