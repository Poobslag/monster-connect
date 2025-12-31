class_name PuzzleMutator

const POPULATION_SIZE: int = 9
const ELITE_COUNT: int = 2
const REPLACEMENT_COUNT: int = 3

## Selection pressure encouraging top candidates to propagate to the next generation.[br]
## 0.0 = uniform selection.[br]
## 1.0 = moderate bias, most picks are from the top 25%[br]
## 5.0 = very strong bias, most picks are from the top 1%
const SELECTION_PRESSURE: float = 1.0

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

var rng: RandomNumberGenerator = RandomNumberGenerator.new():
	set(value):
		rng = value
		_rng_ops.rng = rng
		_mutation_library.rng = rng
var candidates: Array[Solver] = []

var _mutation_library: MutationLibrary = MutationLibrary.new()
var _rng_ops: RngOps = RngOps.new(rng)

var fun_weights: Dictionary[Deduction.FunAxis, float] = {
	Deduction.FunAxis.FUN_TRIVIAL: -1.0,
	Deduction.FunAxis.FUN_FAST: 0.0,
	Deduction.FunAxis.FUN_NOVELTY: 1.0,
	Deduction.FunAxis.FUN_THINK: 1.0,
	Deduction.FunAxis.FUN_BIFURCATE: 1.0,
}

func _init(start_board: SolverBoard) -> void:
	_mutation_library.rng = rng
	
	var solver: Solver = Solver.new()
	solver.board = start_board.duplicate()
	solver.board.erase_solution_cells()
	solver.step_until_done(Solver.SolverPass.BIFURCATION)
	candidates.append(solver)


func duplicate_candidate(candidate_index: int) -> Solver:
	var copy: Solver = Solver.new()
	copy.board = candidates[candidate_index].board.duplicate()
	copy.metrics = candidates[candidate_index].metrics.duplicate(true)
	return copy


func step() -> void:
	if candidates.is_empty():
		push_error("Candidate pool is empty.")
		return
	
	var new_candidates: Array[Solver] = []
	# copy elites
	for i in ELITE_COUNT:
		if i >= candidates.size():
			break
		new_candidates.append(duplicate_candidate(i))
	
	# fill candidates with mutations
	for i in POPULATION_SIZE - REPLACEMENT_COUNT:
		if i >= candidates.size():
			break
		new_candidates.append(duplicate_candidate(i))
		mutate(new_candidates.back())
	
	while new_candidates.size() < POPULATION_SIZE:
		var i: int = int(candidates.size() * pow(randf(), 1.0 + SELECTION_PRESSURE))
		new_candidates.append(duplicate_candidate(i))
		mutate(new_candidates.back())
	
	# sort candidates
	var wrapped_candidates: Array[Dictionary] = []
	for candidate: Solver in new_candidates:
		candidate.step_until_done(Solver.SolverPass.BIFURCATION)
		var fitness: float = calculate_fitness(candidate)
		wrapped_candidates.append({
			"candidate": candidate,
			"fitness": fitness,
		} as Dictionary[String, Variant])
	wrapped_candidates.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
		return a["fitness"] > b["fitness"])
	for i in wrapped_candidates.size():
		new_candidates[i] = wrapped_candidates[i]["candidate"]
	
	candidates = new_candidates


func get_best_board() -> SolverBoard:
	return candidates.front().board


func mutate(solver: Solver) -> void:
	# populate the mutation picker
	var picker: MutationPicker = MutationPicker.new()
	var validation_errors: SolverBoard.ValidationResult = solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	if validation_errors.error_count != 0:
		picker.add(mutate_fix_errors.bind(solver), 4.0)
	elif not solver.board.is_filled():
		picker.add(mutate_fix_unfinished.bind(solver), 4.0)
	picker.add(_mutation_library.mutate_shrink_dead_end_wall.bind(solver.board))
	picker.add(_mutation_library.mutate_break_wall_loop.bind(solver.board))
	picker.add(_mutation_library.mutate_split_island.bind(solver.board))
	picker.add(_mutation_library.mutate_rebalance_neighbor_islands.bind(solver.board))
	picker.add(_mutation_library.mutate_move_clue.bind(solver.board))
	
	# mutate randomly
	picker.mutate(_rng_ops)
	
	solver.board.erase_solution_cells()
	solver.clear()
	solver.step_until_done(Solver.SolverPass.BIFURCATION)


func mutate_fix_errors(solver: Solver) -> bool:
	var did_mutate: bool = false
	var validation_errors: SolverBoard.ValidationResult
	for _mercy in 10:
		validation_errors = solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
		if validation_errors.error_count == 0:
			break
		var mutate_options: Array[Callable] = []
		if not validation_errors.joined_islands.is_empty():
			mutate_options.append(_mutation_library.mutate_fix_joined_islands)
		if not validation_errors.pools.is_empty():
			mutate_options.append(_mutation_library.mutate_fix_pools)
		if not validation_errors.split_walls.is_empty():
			mutate_options.append(_mutation_library.mutate_fix_split_walls)
		if not validation_errors.unclued_islands.is_empty():
			mutate_options.append(_mutation_library.mutate_fix_unclued_islands_clue)
			mutate_options.append(_mutation_library.mutate_fix_unclued_islands_join)
		if not validation_errors.wrong_size.is_empty():
			mutate_options.append(_mutation_library.mutate_fix_wrong_size)
		if not mutate_options:
			break
		var mutate_option: Callable = _rng_ops.pick_random(mutate_options)
		if mutate_option.bind(solver.board).call():
			did_mutate = true
	
	_mutation_library.mutate_fix_enclosed_walls(solver.board)
	return did_mutate


func mutate_fix_unfinished(solver: Solver) -> bool:
	var did_mutate: bool = false
	for _mercy in 10:
		var mutate_options: Array[Callable] = []
		mutate_options.append(_mutation_library.mutate_force_exaggerate)
		mutate_options.append(_mutation_library.mutate_force_inject)
		mutate_options.append(_mutation_library.mutate_force_partition)
		if not mutate_options:
			break
		var mutate_option: Callable = _rng_ops.pick_random(mutate_options)
		if mutate_option.bind(solver.board).call():
			did_mutate = true
	return did_mutate


func calculate_fitness(solver: Solver) -> float:
	var fitness: float = 0.0
	var fun: Dictionary[Deduction.FunAxis, float] \
			= solver.metrics.get("fun", {} as Dictionary[Deduction.FunAxis, float])
	fitness += solver.board.cells.size()
	for fun_axis: Deduction.FunAxis in fun_weights:
		fitness += fun.get(fun_axis, 0.0) * fun_weights[fun_axis]
	
	var penalty: float = 0
	
	var validation_result: SolverBoard.ValidationResult \
			= solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	penalty += validation_result.joined_islands.size()
	penalty += validation_result.pools.size()
	if validation_result.split_walls:
		penalty += solver.board.walls.size()
	penalty += validation_result.unclued_islands.size()
	penalty += validation_result.wrong_size.size()
	
	penalty += solver.board.validate(SolverBoard.VALIDATE_SIMPLE).error_count
	penalty += solver.board.empty_cells.size()
	if penalty == 0:
		fitness += 5 * solver.board.cells.size()
	else:
		fitness *= 10.0 / (penalty + 10)
	
	return fitness


class MutationPicker:
	var callables: Array[Callable] = []
	var weights: Array[float] = []
	
	func add(callable: Callable, weight: float = 1.0) -> void:
		callables.append(callable)
		weights.append(weight)
	
	
	func mutate(rng_ops: RngOps) -> void:
		if not weights:
			return
		
		var callables_shuffled: Array[Callable] = callables.duplicate()
		rng_ops.shuffle_weighted(callables_shuffled, weights)
		for callable: Callable in callables_shuffled:
			var did_mutate: bool = callable.call()
			if did_mutate:
				break
