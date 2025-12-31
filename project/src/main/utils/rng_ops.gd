class_name RngOps

const EPSILON = 0.0001

var rng: RandomNumberGenerator

func _init(init_rng: RandomNumberGenerator) -> void:
	rng = init_rng


func pick_random(arr: Array[Variant]) -> Variant:
	return arr[rng.randi_range(0, arr.size() - 1)]


## Shuffles the array in place using the Fisher–Yates algorithm.[br]
## [br]
## Uses the injected RNG for deterministic behavior when seeded.
func shuffle(arr: Array[Variant]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## Shuffles an array with non-uniform weights.[br]
## [br]
## Higher weighted items are sorted to the front more frequently. Uses Efraimidis–Spirakis weighted random ordering.
func shuffle_weighted(arr: Array[Variant], weights: PackedFloat32Array) -> void:
	var decorated: Array[Dictionary] = []
	for i in arr.size():
		decorated.append({
			"value": arr[i],
			"key": pow(rng.randf(), 1.0 / max(weights[i], EPSILON)),
		})
	decorated.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["key"] > b["key"])
	for i in arr.size():
		arr[i] = decorated[i]["value"]
