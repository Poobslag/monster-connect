extends GutTest


func test_dist_to_rect() -> void:
	# inside
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 15), 5.0) # c
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 12), 2.0) # u
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(27, 15), 3.0) # r
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 16), 4.0) # d
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(12, 15), 2.0) # l
	
	# outside
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 8), 2.0) # u
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(33, 6), 5.0) # ur
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(33, 15), 3.0) # r
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(34, 23), 5.0) # dr
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 24), 4.0) # d
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(6, 23), 5.0) # dl
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(8, 15), 2.0) # l
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(7, 6), 5.0) # ul
	
	# on edge
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 10), 0.0) # u
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(30, 15), 0.0) # r
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 20), 0.0) # d
	_assert_dist_to_rect(Rect2(10, 10, 20, 10), Vector2(10, 15), 0.0) # l
	
	# zero-size rect
	_assert_dist_to_rect(Rect2(10, 10, 0, 0), Vector2(30, 20), 22.361)


func test_nearest_point_on_rect() -> void:
	# inside
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(20, 15), Vector2(20, 10)) # c
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(20, 12), Vector2(20, 10)) # u
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(27, 15), Vector2(30, 15)) # r
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(20, 16), Vector2(20, 20)) # d
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(12, 15), Vector2(10, 15)) # l
	
	# outside
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(20, 8), Vector2(20, 10)) # u
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(33, 6), Vector2(30, 10)) # ur
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(33, 15), Vector2(30, 15)) # r
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(34, 23), Vector2(30, 20)) # dr
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(20, 24), Vector2(20, 20)) # d
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(6, 23), Vector2(10, 20)) # dl
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(8, 15), Vector2(10, 15)) # l
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(7, 6), Vector2(10, 10)) # ul
	
	# on edge
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(20, 10), Vector2(20, 10)) # u
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(30, 15), Vector2(30, 15)) # r
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(20, 20), Vector2(20, 20)) # d
	_assert_nearest_point_on_rect(Rect2(10, 10, 20, 10), Vector2(10, 15), Vector2(10, 15)) # l
	
	# zero-size rect
	_assert_nearest_point_on_rect(Rect2(10, 10, 0, 0), Vector2(30, 20), Vector2(10, 10))


func _assert_dist_to_rect(rect: Rect2, point: Vector2, expected: float) -> void:
	assert_almost_eq(PlayerInputHandler.dist_to_rect(rect, point), expected, 0.001)


func _assert_nearest_point_on_rect(rect: Rect2, point: Vector2, expected: Vector2) -> void:
	assert_eq(PlayerInputHandler.nearest_point_on_rect(rect, point), expected)
