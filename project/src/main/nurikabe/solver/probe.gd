class_name Probe

var callable: Callable
var key: String
var name: String
var deduction_cells: Array[Vector2i] = []

var bifurcation: bool = false
var one_shot: bool = false
var startup: bool = false

func _init(init_callable: Callable) -> void:
	callable = init_callable
	key = probe_key(callable)
	name = probe_name(callable)


func run() -> void:
	callable.call()


func add_deduction_cells(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		add_deduction_cell(cell)


func add_deduction_cell(cell: Vector2i) -> void:
	if not cell in deduction_cells:
		deduction_cells.append(cell)


static func probe_key(target: Callable) -> String:
	var value: String = target.get_method()
	var args: Array[Variant] = target.get_bound_arguments()
	if not args.is_empty():
		# only the first two arguments; add_bifurcation_scenario takes a lot of length arguments which aren't needed
		# in the key
		value += ":" + JSON.stringify(args.slice(0, 2))
	return value


static func probe_name(target: Callable) -> String:
	var value: String
	if target.get_method() == "add_bifurcation_scenario":
		value = target.get_bound_arguments()[0]
	else:
		value = target.get_method()
	return value
