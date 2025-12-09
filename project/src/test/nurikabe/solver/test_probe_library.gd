extends TestSolver

func test_has_scheduled_task() -> void:
	assert_eq(solver.probe_library.has_probe(solver.deduce_all_islands_of_one), false)
	solver.probe_library.add_probe(solver.deduce_all_islands_of_one)
	assert_eq(solver.probe_library.has_probe(solver.deduce_all_islands_of_one), true)


func test_get_scheduled_task() -> void:
	assert_null(solver.probe_library.get_probe(solver.deduce_all_islands_of_one))
	solver.probe_library.add_probe(solver.deduce_all_islands_of_one)
	assert_not_null(solver.probe_library.get_probe(solver.deduce_all_islands_of_one))
