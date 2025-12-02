class_name DecisionManager

enum Strategy {
	DEFAULT,
	FIRST,
	RANDOM,
	SMART,
}

const METRICS_PATH: String = "res://assets/main/nurikabe/solver/probe_metrics.json"

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS
const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var strategy: Strategy = Strategy.DEFAULT
var board: SolverBoard
var probe_library: ProbeLibrary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

static var _probe_metrics_loaded: bool = false
static var _probe_metrics: Dictionary[String, Dictionary] = {}

func choose_probe(allow_bifurcation: bool = true) -> Probe:
	var available_probes: Array[Probe] = probe_library.get_available_probes()
	if not allow_bifurcation:
		available_probes = available_probes.filter(func(p: Probe) -> bool:
			return not p.bifurcation)
	var probe: Probe = null
	if not available_probes.is_empty():
		match strategy:
			Strategy.SMART:
				probe = _choose_best_probe(available_probes)
			Strategy.RANDOM:
				probe = available_probes[rng.randi_range(0, available_probes.size() - 1)]
			Strategy.FIRST, _:
				probe = available_probes[0]
	return probe


func clear() -> void:
	pass


func _choose_best_probe(available_probes: Array[Probe]) -> Probe:
	if not _probe_metrics_loaded:
		_load_probe_metrics()
	
	var best_probe: Probe = null
	var best_score: float = 0.0
	
	for probe: Probe in available_probes:
		if probe.callable.get_method() == "run_bifurcation_step":
			best_probe = probe
			best_score = 999999.0
			break
		
		var metric_name: String
		if probe.callable.get_method() == "add_bifurcation_scenario":
			metric_name = probe.callable.get_bound_arguments()[0]
		else:
			metric_name = probe.callable.get_method()
		
		var probe_metric: Dictionary = _probe_metrics[metric_name]
		var total_cost: float = probe_metric.get("cost", 0.0) + probe_metric.get("spawn_cost", 0.0)
		var total_impact: float = probe_metric.get("impact", 0.0) + probe_metric.get("spawn_impact", 0.0)
		var score: float = total_impact / total_cost
		if score > best_score:
			best_probe = probe
			best_score = score
	
	return best_probe


func _load_probe_metrics() -> void:
	var metrics_text: String = FileAccess.get_file_as_string(METRICS_PATH)
	var test_json_conv := JSON.new()
	test_json_conv.parse(metrics_text)
	_probe_metrics.assign(test_json_conv.get_data())
	_probe_metrics_loaded = true
