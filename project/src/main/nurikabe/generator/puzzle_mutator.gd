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
var difficulty: float = 0.5:
	set(value):
		difficulty = value
		_refresh_difficulty()

var _mutation_library: MutationLibrary = MutationLibrary.new()
var _rng_ops: RngOps = RngOps.new(rng)

var fun_weights_by_difficulty: Array[Dictionary] = [
	{
		# trivial difficulty, very few techniques required
		Deduction.FunAxis.FUN_TRIVIAL: 0.0,
		Deduction.FunAxis.FUN_FAST: 4.0,
		Deduction.FunAxis.FUN_NOVELTY: 0.0,
		Deduction.FunAxis.FUN_THINK: -1.0,
		Deduction.FunAxis.FUN_BIFURCATE: -1.0,
	},
	{
		# easy difficulty, basic techniques required
		Deduction.FunAxis.FUN_TRIVIAL: 0.0,
		Deduction.FunAxis.FUN_FAST: 2.0,
		Deduction.FunAxis.FUN_NOVELTY: 1.5,
		Deduction.FunAxis.FUN_THINK: -0.5,
		Deduction.FunAxis.FUN_BIFURCATE: -1.0,
	},
	{
		# moderate difficulty, advanced techniques required
		Deduction.FunAxis.FUN_TRIVIAL: -1.0,
		Deduction.FunAxis.FUN_FAST: 1.0,
		Deduction.FunAxis.FUN_NOVELTY: 1.5,
		Deduction.FunAxis.FUN_THINK: 1.0,
		Deduction.FunAxis.FUN_BIFURCATE: -0.5,
	},
	{
		# hard difficulty, bifurcation required
		Deduction.FunAxis.FUN_TRIVIAL: -1.0,
		Deduction.FunAxis.FUN_FAST: 0.0,
		Deduction.FunAxis.FUN_NOVELTY: 1.0,
		Deduction.FunAxis.FUN_THINK: 1.5,
		Deduction.FunAxis.FUN_BIFURCATE: 1.0,
	},
	{
		# extreme difficulty, tons of bifurcation
		Deduction.FunAxis.FUN_TRIVIAL: -1.0,
		Deduction.FunAxis.FUN_FAST: -1.0,
		Deduction.FunAxis.FUN_NOVELTY: 0.5,
		Deduction.FunAxis.FUN_THINK: 1.5,
		Deduction.FunAxis.FUN_BIFURCATE: 2.0,
	}
]

var fun_weights: Dictionary[Deduction.FunAxis, float] = {
}

func _init(start_board: SolverBoard) -> void:
	_mutation_library.rng = rng
	
	var solver: Solver = Solver.new()
	solver.board = start_board.duplicate()
	solver.board.erase_solution_cells()
	solver.step_until_done(Solver.SolverPass.BIFURCATION)
	candidates.append(solver)
	
	_refresh_difficulty()


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
			break
	return did_mutate


func calculate_fitness(solver: Solver) -> float:
	var fitness: float = 0.0
	var fun: Dictionary[Deduction.FunAxis, float] \
			= solver.metrics.get("fun", {} as Dictionary[Deduction.FunAxis, float])
	fitness += solver.board.cells.size()
	for fun_axis: Deduction.FunAxis in fun_weights:
		fitness += fun.get(fun_axis, 0.0) * fun_weights[fun_axis]
	
	# puzzles with huge empty spaces are penalized
	var blob_penalty: float = 0
	for island: CellGroup in solver.board.islands:
		blob_penalty += max(0, island.size() - solver.board.cells.size() * 0.25)
	if blob_penalty == 0:
		pass
	else:
		fitness *= 10.0 / (blob_penalty + 10.0)
	
	# invalid/unfinished puzzles are penalized
	var validation_penalty: float = 0
	var validation_result: SolverBoard.ValidationResult \
			= solver.board.validate(SolverBoard.VALIDATE_SIMPLE)
	validation_penalty += validation_result.joined_islands.size()
	validation_penalty += validation_result.pools.size()
	if validation_result.split_walls:
		validation_penalty += solver.board.walls.size()
	validation_penalty += validation_result.unclued_islands.size()
	validation_penalty += validation_result.wrong_size.size()
	validation_penalty += solver.board.validate(SolverBoard.VALIDATE_SIMPLE).error_count
	validation_penalty += solver.board.empty_cells.size()
	if validation_penalty == 0:
		fitness += 5 * solver.board.cells.size()
	else:
		fitness *= 10.0 / (validation_penalty + 10)
	
	return fitness


func _refresh_difficulty() -> void:
	var band_pos: float = difficulty * (fun_weights_by_difficulty.size() - 1)
	var band_index_low: int = clampi(floori(band_pos), 0, fun_weights_by_difficulty.size() - 2)
	var band_index_high: int = clampi(ceili(band_pos), 1, fun_weights_by_difficulty.size() - 1)

	var low_weights: Dictionary = fun_weights_by_difficulty[band_index_low]
	var high_weights: Dictionary = fun_weights_by_difficulty[band_index_high]
	var band_lerp: float = band_pos - band_index_low

	for axis: Deduction.FunAxis in Deduction.FunAxis.values():
		fun_weights[axis] = lerp(low_weights[axis], high_weights[axis], band_lerp)


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
