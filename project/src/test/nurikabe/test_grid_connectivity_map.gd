extends GutTest

var gcm := GridConnectivityMap.new()
var grid: Array[String] = []

func before_each() -> void:
	gcm.clear()


func test_empty() -> void:
	assert_eq(gcm.get_groups(), [])
	assert_eq(false, gcm.has_cell(Vector2i(0, 0)))
	assert_eq(false, gcm.is_active(Vector2i(0, 0)))
	assert_groups([[]])


func test_single_active_cell() -> void:
	gcm.set_active(Vector2i(0, 0), true)
	assert_eq(true, gcm.has_cell(Vector2i(0, 0)))
	assert_eq(true, gcm.is_active(Vector2i(0, 0)))
	assert_groups([[Vector2i(0, 0)]])


func test_single_inactive_cell() -> void:
	gcm.set_active(Vector2i(0, 0), false)
	assert_eq(true, gcm.has_cell(Vector2i(0, 0)))
	assert_eq(false, gcm.is_active(Vector2i(0, 0)))
	assert_groups([[]])


func test_two_cells_adjacent() -> void:
	gcm.set_active(Vector2i(0, 0), true)
	gcm.set_active(Vector2i(1, 0), true)
	assert_groups([[Vector2i(0, 0), Vector2i(1, 0)]])


func test_two_cells_separate() -> void:
	gcm.set_active(Vector2i(0, 0), true)
	gcm.set_active(Vector2i(2, 0), true)
	assert_groups([[Vector2i(0, 0)], [Vector2i(2, 0)]])


func shrink_group() -> void:
	gcm.set_active(Vector2i(0, 0), true)
	gcm.set_active(Vector2i(1, 0), true)
	gcm.set_active(Vector2i(0, 0), false)
	assert_groups([[Vector2i(1, 0)]])


# set active false
# remove group
# merge two groups
# merge three groups
# merge four groups
# split two groups
# split three groups
# split four groups


func assert_groups(expected: Array[Array]) -> void:
	var actual: Array[Array] = gcm.get_groups()
	var actual_sorted: Array[Array] = sort_groups(actual)
	var expected_sorted: Array[Array] = sort_groups(expected)
	assert_eq(actual_sorted, expected_sorted)


func sort_groups(groups: Array[Array]) -> Array[Array]:
	var new_groups: Array[Array] = []
	for group in groups:
		var new_group: Array[Vector2i] = []
		new_group.assign(group)
		new_group.sort()
		new_groups.append(new_group)
	new_groups.sort_custom(func(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
		if a.is_empty() != b.is_empty():
			return a.is_empty()
		return a[0] < b[0])
	return new_groups
