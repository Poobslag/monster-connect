extends GutTest

func test_snap_to_rect() -> void:
	# inside
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 15)), Vector2(20, 15))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(15, 12)), Vector2(15, 12))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 14)), Vector2(20, 14))
	
	# outside
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(40, 25)), Vector2(30, 20))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(0, 5)), Vector2(10, 10))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(40, 15)), Vector2(30, 15))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 5)), Vector2(20, 10))
	
	# on edge
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(30, 20)), Vector2(30, 20))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(10, 10)), Vector2(10, 10))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(30, 15)), Vector2(30, 15))
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 20, 10), Vector2(20, 10)), Vector2(20, 10))
	
	# zero-size rect
	assert_eq(PlayerInputHandler.snap_to_rect(Rect2(10, 10, 0, 0), Vector2(30, 20)), Vector2(10, 10))
