class_name DecisionManager

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS
const POS_NOT_FOUND: Vector2i = NurikabeUtils.POS_NOT_FOUND

var board: SolverBoard
var probe_library: ProbeLibrary

func choose_probe(allow_bifurcation: bool = true) -> Probe:
	var available_probes: Array[Probe] = probe_library.get_available_probes()
	if not allow_bifurcation:
		available_probes = available_probes.filter(func(probe: Probe) -> bool:
			return probe.key != "create_bifurcation_probes")
	return null if available_probes.is_empty() else available_probes.pick_random()


func clear() -> void:
	pass
