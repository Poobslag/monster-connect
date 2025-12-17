extends TestGenerator

func test_fix_pool_1() -> void:
	grid = [
		"    ######## . 2",
		"       ?########",
		"    #### ?## 1##",
		"     ?#### 1## 2",
		"    ## . ?#### .",
		"    ###### .####",
		"       . . ?## ?",
		"    ########## .",
	]
	var expected: Array[String] = [
		"(7, 0)->3 fix_pool (4, 0) (4, 1) (5, 0) (5, 1)",
	]
	assert_placements(generator.attempt_pool_fix_from.bind(Vector2i(5, 0)), expected)


func test_fix_pool_2() -> void:
	grid = [
		"######## ?",
		"## ? .## .",
		" 2## .####",
		" .#### ?##",
		"##########",
	]
	var expected: Array[String] = [
		"(0, 2)->4 fix_pool (1, 3) (1, 4) (2, 3) (2, 4)",
	]
	var callable: Callable = generator.attempt_pool_fix_from.bind( \
			Vector2i(1, 4), [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN] as Array[Vector2i])
	assert_placements(callable, expected)
