class_name Probe

var callable: Callable
var key: String

var bifurcation: bool = false
var one_shot: bool = false

func _init(init_callable: Callable) -> void:
	callable = init_callable
	key = probe_key(callable)


func run() -> void:
	callable.call()


static func probe_key(target: Callable) -> String:
	var value: String = target.get_method()
	var args: Array[Variant] = target.get_bound_arguments()
	if not args.is_empty():
		# only the first two arguments; add_bifurcation_scenario takes a lot of length arguments which aren't needed
		# in the key
		value += ":" + JSON.stringify(args.slice(0, 2))
	return value
