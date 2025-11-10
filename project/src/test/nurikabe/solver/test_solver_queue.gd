extends TestSolver

func test_has_scheduled_task() -> void:
	assert_eq(solver.has_scheduled_task(solver.enqueue_islands_of_one), false)
	solver.schedule_task(solver.enqueue_islands_of_one, 100)
	assert_eq(solver.has_scheduled_task(solver.enqueue_islands_of_one), true)


func test_get_scheduled_task() -> void:
	assert_eq(solver.get_scheduled_task(solver.enqueue_islands_of_one), {} as Dictionary[String, Variant])
	solver.schedule_task(solver.enqueue_islands_of_one, 100)
	var scheduled_task: Dictionary[String, Variant] = solver.get_scheduled_task(solver.enqueue_islands_of_one)
	assert_eq(scheduled_task.get("priority"), 100)
	assert_eq(scheduled_task.get("callable"), solver.enqueue_islands_of_one)
