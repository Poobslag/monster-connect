extends GutTest

var saver: MonsterSaver = MonsterSaver.new()

func test_load_sim_behavior() -> void:
	var behavior: SimBehavior = saver.load_sim_behavior("res://assets/test/monster/monster_611.txt")
	
	assert_eq(behavior.version, "0.01")
	assert_eq(behavior.name, "Ants")
	assert_eq(behavior.author, "Poobslag")
	assert_eq(behavior.description, "A recluse ratatouilled by a colony of ants living inside his brain. " \
			+ "His hobbies include sugar and fealty.")
	assert_eq(behavior.skin, Monster.MonsterSkin.YELLOW)
	
	assert_eq(behavior.archetypes.get("rat"), 9.0)
	assert_eq(behavior.archetypes.get("pig"), 1.0)
	
	assert_almost_eq(behavior.get_stat("puzzle.cursor_speed"), 0.74, 0.001)
	assert_almost_eq(behavior.get_stat("puzzle.think_speed"), 0.74, 0.001)


func test_load_sim_behavior_empty() -> void:
	var behavior: SimBehavior = saver.load_sim_behavior("res://assets/test/monster/monster_empty.txt")
	
	assert_eq(behavior.version, "0.01")
	assert_eq(behavior.name, "")
	assert_eq(behavior.author, "")
	assert_eq(behavior.description, "")
	assert_eq(behavior.skin, null)
	
	assert_almost_eq(behavior.get_stat("puzzle.cursor_speed"), 0.5, 0.001)
	assert_almost_eq(behavior.get_stat("puzzle.think_speed"), 0.5, 0.001)
