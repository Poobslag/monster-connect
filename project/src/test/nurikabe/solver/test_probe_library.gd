extends TestSolver

func test_has_scheduled_task() -> void:
	assert_eq(solver.probe_library.has_probe(solver.create_island_of_one_probes), false)
	solver.probe_library.add_probe(solver.create_island_of_one_probes)
	assert_eq(solver.probe_library.has_probe(solver.create_island_of_one_probes), true)


func test_get_scheduled_task() -> void:
	assert_null(solver.probe_library.get_probe(solver.create_island_of_one_probes))
	solver.probe_library.add_probe(solver.create_island_of_one_probes)
	assert_not_null(solver.probe_library.get_probe(solver.create_island_of_one_probes))
