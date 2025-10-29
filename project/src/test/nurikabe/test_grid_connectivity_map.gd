extends GutTest

var gcm := GridConnectivityMap.new()

func before_each() -> void:
	gcm.clear()


func test_empty() -> void:
	assert_eq(false, gcm.has_cell(Vector2i(0, 0)))
	assert_eq(false, gcm.is_active(Vector2i(0, 0)))
	assert_groups(gcm.get_groups(), [])


func test_single_active_cell() -> void:
	gcm.set_active(Vector2i(0, 0), true)
	assert_eq(true, gcm.has_cell(Vector2i(0, 0)))
	assert_eq(true, gcm.is_active(Vector2i(0, 0)))
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0)]])


func test_single_inactive_cell() -> void:
	gcm.set_active(Vector2i(0, 0), false)
	assert_eq(false, gcm.has_cell(Vector2i(0, 0)))
	assert_eq(false, gcm.is_active(Vector2i(0, 0)))
	assert_groups(gcm.get_groups(), [])


func test_two_cells_adjacent() -> void:
	load_grid([
		"12",
	])
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0), Vector2i(1, 0)]])


func test_two_cells_separate() -> void:
	load_grid([
		"1 2",
	])
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0)], [Vector2i(2, 0)]])


func test_shrink_group() -> void:
	load_grid([
		"12",
	])
	gcm.set_active(Vector2i(0, 0), false)
	assert_groups(gcm.get_groups(), [[Vector2i(1, 0)]])


func test_remove_group() -> void:
	gcm.set_active(Vector2i(0, 0), true)
	gcm.set_active(Vector2i(0, 0), false)
	assert_groups(gcm.get_groups(), [])


func test_merge_groups_two() -> void:
	load_grid([
		"13",
		" 2",
	])
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]])


func test_merge_groups_three() -> void:
	load_grid([
		"143",
		" 2",
	])
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 0)]])


func test_merge_groups_four() -> void:
	load_grid([
		" 1 ",
		"254",
		" 3",
	])
	assert_groups(gcm.get_groups(), [[Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1)]])


func test_split_groups_two() -> void:
	load_grid([
		"123",
	])
	gcm.set_active(Vector2i(1, 0), false)
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0)], [Vector2i(2, 0)]])


func test_split_groups_three() -> void:
	load_grid([
		"123",
		" 4 ",
	])
	gcm.set_active(Vector2i(1, 0), false)
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0)], [Vector2i(1, 1)], [Vector2i(2, 0)]])


func test_split_groups_four() -> void:
	load_grid([
		" 1 ",
		"234",
		" 5 ",
	])
	gcm.set_active(Vector2i(1, 1), false)
	assert_groups(gcm.get_groups(), [[Vector2i(0, 1)], [Vector2i(1, 0)], [Vector2i(1, 2)], [Vector2i(2, 1)]])


func test_split_groups_half() -> void:
	load_grid([
		"1 4",
		"235",
		"  6",
	])
	gcm.set_active(Vector2i(1, 1), false)
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0), Vector2i(0, 1)], [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]])


func test_duplicate() -> void:
	gcm.set_active(Vector2i(0, 0), true)
	var gcm_copy: GridConnectivityMap = gcm.duplicate()
	gcm_copy.set_active(Vector2i(1, 0), true)
	
	assert_eq(true, gcm.has_cell(Vector2i(0, 0)))
	assert_eq(true, gcm.is_active(Vector2i(0, 0)))
	assert_eq(false, gcm.has_cell(Vector2i(1, 0)))
	assert_eq(false, gcm.is_active(Vector2i(1, 0)))
	assert_groups(gcm.get_groups(), [[Vector2i(0, 0)]])
	
	assert_eq(true, gcm_copy.has_cell(Vector2i(0, 0)))
	assert_eq(true, gcm_copy.is_active(Vector2i(0, 0)))
	assert_eq(true, gcm_copy.has_cell(Vector2i(1, 0)))
	assert_eq(true, gcm_copy.is_active(Vector2i(1, 0)))
	assert_groups(gcm_copy.get_groups(), [[Vector2i(0, 0), Vector2i(1, 0)]])


func assert_groups(actual: Array[Array], expected: Array[Array]) -> void:
	var actual_sorted: Array[Array] = NurikabeTestUtils.sort_groups(actual)
	var expected_sorted: Array[Array] = NurikabeTestUtils.sort_groups(expected)
	assert_eq(actual_sorted, expected_sorted)


func load_grid(rows: Array[String]) -> void:
	var active_cells: Array[Dictionary] = []
	for y in rows.size():
		var row := rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == " ":
				continue
			active_cells.append({"label": int(ch), "pos": Vector2i(x, y)} as Dictionary[String, Variant])
	active_cells.sort_custom(
		func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
			return a.label < b.label)
	for entry: Dictionary[String, Variant] in active_cells:
		gcm.set_active(entry.pos, true)
