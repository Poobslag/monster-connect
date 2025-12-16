class_name TechniqueScheduler

var _techniques: Array[Dictionary]

func _init(init_techniques: Array[Dictionary]) -> void:
	_techniques = init_techniques


func next_cycle() -> Array[Callable]:
	var technique_weights: Array[float] = []
	technique_weights.resize(_techniques.size())
	for i in _techniques.size():
		technique_weights[i] = _techniques[i]["weight"]
	var shuffled_techniques: Array[Dictionary] = _techniques.duplicate()
	Utils.shuffle_weighted(shuffled_techniques, technique_weights)
	
	var result: Array[Callable] = []
	for shuffled_technique: Dictionary in shuffled_techniques:
		result.append(shuffled_technique["callable"])
	return result
