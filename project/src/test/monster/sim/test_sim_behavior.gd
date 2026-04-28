extends GutTest

var behavior: SimBehavior = SimBehavior.new()

func test_lerp_stat_linear() -> void:
	behavior.stats["asdf"] = 0
	assert_eq(behavior.lerp_stat("asdf", 200, 400), 200.0)
	
	behavior.stats["asdf"] = 5
	assert_almost_eq(behavior.lerp_stat("asdf", 200, 400), 300.0, 0.001)

	behavior.stats["asdf"] = 10
	assert_eq(behavior.lerp_stat("asdf", 200, 400), 400.0)


func test_lerp_stat_ease_in() -> void:
	behavior.stats["asdf"] = 0
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 250), 200.0)
	
	behavior.stats["asdf"] = 5
	assert_almost_eq(behavior.lerp_stat("asdf", 200, 400, 250), 250.0, 0.001)

	behavior.stats["asdf"] = 10
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 250), 400.0)


func test_lerp_stat_ease_in_2() -> void:
	behavior.stats["asdf"] = 0
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 225), 200.0)
	
	behavior.stats["asdf"] = 5
	assert_almost_eq(behavior.lerp_stat("asdf", 200, 400, 225), 225.0, 0.001)

	behavior.stats["asdf"] = 10
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 225), 400.0)


func test_lerp_stat_ease_in_3() -> void:
	behavior.stats["asdf"] = 0
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 201), 200.0)
	
	behavior.stats["asdf"] = 5
	assert_almost_eq(behavior.lerp_stat("asdf", 200, 400, 201), 201.0, 0.001)

	behavior.stats["asdf"] = 10
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 201), 400.0)


func test_lerp_stat_ease_out() -> void:
	behavior.stats["asdf"] = 0
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 350), 200.0)
	
	behavior.stats["asdf"] = 5
	assert_almost_eq(behavior.lerp_stat("asdf", 200, 400, 350), 350.0, 0.001)

	behavior.stats["asdf"] = 10
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 350), 400.0)


func test_lerp_stat_ease_out_2() -> void:
	behavior.stats["asdf"] = 0
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 375), 200.0)
	
	behavior.stats["asdf"] = 5
	assert_almost_eq(behavior.lerp_stat("asdf", 200, 400, 375), 375.0, 0.001)

	behavior.stats["asdf"] = 10
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 375), 400.0)


func test_lerp_stat_ease_out_3() -> void:
	behavior.stats["asdf"] = 0
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 399), 200.0)
	
	behavior.stats["asdf"] = 5
	assert_almost_eq(behavior.lerp_stat("asdf", 200, 400, 399), 399.0, 0.001)

	behavior.stats["asdf"] = 10
	assert_eq(behavior.lerp_stat("asdf", 200, 400, 399), 400.0)
