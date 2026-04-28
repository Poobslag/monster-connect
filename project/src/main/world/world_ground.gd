class_name WorldGround
extends StaticBody3D

func moatify(rect: Rect2i) -> void:
	%GroundMap.moatify(rect)


func unmoatify(rect: Rect2i) -> void:
	%GroundMap.unmoatify(rect)


func aabb_to_map_rect(aabb: AABB, margin: int = 0) -> Rect2i:
	return %GroundMap.aabb_to_map_rect(aabb, margin)
