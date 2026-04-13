extends GutTest

var saver: MonsterSaver = MonsterSaver.new()

func test_load_sim_behavior() -> void:
	var profile: SimProfile = saver.load_sim_profile("res://assets/test/monster/monster_611.txt")
	
	assert_eq(profile.version, "0.01")
	assert_eq(profile.name, "Ants")
	assert_eq(profile.author, "Poobslag")
	assert_eq(profile.description, "A recluse ratatouilled by a colony of ants living inside his brain. " \
			+ "His hobbies include sugar and fealty.")
	assert_eq(profile.skin, Monster.MonsterSkin.YELLOW)
	
	assert_eq(profile.archetypes.get("rat"), 9.0)
	assert_eq(profile.archetypes.get("pig"), 1.0)
	
	assert_almost_eq(profile.behavior.get_stat("puzzle.cursor_speed"), 0.92, 0.001)
	assert_almost_eq(profile.behavior.get_stat("puzzle.think_speed"), 0.83, 0.001)
	assert_almost_eq(profile.behavior.get_stat("puzzle.pickiness"), 0.0, 0.001)


func test_load_sim_behavior_empty() -> void:
	var profile: SimProfile = saver.load_sim_profile("res://assets/test/monster/monster_empty.txt")
	
	assert_eq(profile.version, "0.01")
	assert_eq(profile.name, "")
	assert_eq(profile.author, "")
	assert_eq(profile.description, "")
	assert_eq(profile.skin, Monster.MonsterSkin.NONE)
	
	assert_almost_eq(profile.behavior.get_stat("puzzle.cursor_speed"), 0.5, 0.001)
	assert_almost_eq(profile.behavior.get_stat("puzzle.think_speed"), 0.5, 0.001)
