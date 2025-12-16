class_name ChangeRecord

var pos: Vector2i
var value: int
var sources: Array[Vector2i]

func _init(init_pos: Vector2i, init_value: int,
		init_reason_cells: Array[Vector2i] = []) -> void:
	pos = init_pos
	value = init_value
	sources = init_reason_cells


func to_change() -> Dictionary[String, Variant]:
	return {"pos": pos, "value": value}


func _to_string() -> String:
	var cells_str: String = "" if sources.is_empty() else " " + " ".join(sources)
	return "%s->%s %s" % [pos, NurikabeUtils.to_cell_string(value), cells_str]
