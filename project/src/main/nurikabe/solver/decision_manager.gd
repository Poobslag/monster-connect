class_name DecisionManager

enum Strategy {
	DEFAULT,
	FIRST,
	RANDOM,
}

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS
const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var strategy: Strategy = Strategy.DEFAULT
var board: SolverBoard
var probe_library: ProbeLibrary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func choose_probe(allow_bifurcation: bool = true) -> Probe:
	var available_probes: Array[Probe] = probe_library.get_available_probes()
	if not allow_bifurcation:
		available_probes = available_probes.filter(func(p: Probe) -> bool:
			return not p.bifurcation)
	var probe: Probe = null
	if not available_probes.is_empty():
		match strategy:
			Strategy.RANDOM:
				probe = available_probes[rng.randi_range(0, available_probes.size() - 1)]
			_:
				probe = available_probes[0]
	return probe


func clear() -> void:
	pass
