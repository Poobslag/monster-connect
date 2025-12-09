class_name DecisionManager

enum Strategy {
	DEFAULT,
	FIRST, # the first probe in the list
	RANDOM, # random startup probes, then random probes (including bifurcations)
	SMART, # choose the probe with the best cost/impact ratio
}

## Exponential factor in the range [0.0, 1.0] for how aggressively we should avoid repeat probes.[br]
## [br]
## 0.0 = allow repeat probes[br]
## 0.5 = allow repeat probes after 1-2 cells are filled in[br]
## 0.9 = allow repeat probes after 5-6 cells are filled in[br]
## 1.0 = disallow repeat probes[br]
const REPEAT_PENALTY: float = 0.80

const METRICS_PATH: String = "res://assets/main/nurikabe/solver/probe_metrics.json"

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS
const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var strategy: Strategy = Strategy.DEFAULT
var board: SolverBoard
var probe_library: ProbeLibrary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _last_probe_name: String

static var _probe_metrics_loaded: bool = false
static var _probe_metrics: Dictionary[String, Dictionary] = {}

func choose_probe(metadata: Dictionary[String, Variant]) -> Probe:
	var available_probes: Array[Probe] = probe_library.get_available_probes()
	if not metadata.get("allow_bifurcation", true):
		available_probes = available_probes.filter(func(p: Probe) -> bool:
			return not p.bifurcation)
	var probe: Probe = null
	if not available_probes.is_empty():
		match strategy:
			Strategy.SMART:
				probe = _choose_best_probe(available_probes)
			Strategy.RANDOM:
				if available_probes.any(func(p: Probe) -> bool: return p.startup):
					available_probes = available_probes.filter(func(p: Probe) -> bool:
						return p.startup)
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
		var score: float
		if probe.name == "run_bifurcation_step":
			score = 0.001 if _last_probe_name == "run_bifurcation_step" else 999999.0
		else:
			var probe_metric: Dictionary[String, Variant] = _get_probe_metric(probe)
			score = probe_metric["total_score"]
			
			if score < best_score:
				continue
			
			# apply repeat penalty
			var last_run: int = probe_library.get_last_run(probe)
			if last_run != -1:
				score *= 1.0 - pow(REPEAT_PENALTY, board.version - last_run)
		
		if score > best_score:
			best_probe = probe
			best_score = score
	
	_last_probe_name = best_probe.name
	
	return best_probe


func _get_probe_metric(probe: Probe) -> Dictionary[String, Variant]:
	return _probe_metrics[probe.name]


func _load_probe_metrics() -> void:
	var metrics_text: String = FileAccess.get_file_as_string(METRICS_PATH)
	var test_json_conv := JSON.new()
	test_json_conv.parse(metrics_text)
	_probe_metrics.assign(test_json_conv.get_data())
	for key: String in _probe_metrics:
		var metric: Dictionary[String, Variant] = {}
		metric.assign(_probe_metrics[key])
		metric["total_cost"] = metric.get("cost", 0.0) + metric.get("spawn_cost", 0.0)
		metric["total_impact"] = metric.get("impact", 0.0) + metric.get("spawn_impact", 0.0)
		metric["total_score"] = metric["total_impact"] / metric["total_cost"]
		_probe_metrics[key] = metric
	_probe_metrics_loaded = true
