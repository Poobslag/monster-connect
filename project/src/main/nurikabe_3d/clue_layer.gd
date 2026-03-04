@tool
extends Node3D

const LABEL_OFFSET: Vector2 = Vector2(0.0, 0.025)
const TILE_HEIGHT: float = 0.051

const CLUE_LABEL_SCENE: PackedScene = preload("res://src/main/nurikabe_3d/clue_label_3d.tscn")

var tile_size: Vector2 = Vector2(1, 1)
var tiles_by_cell: Dictionary[Vector2i, ClueLabel3D] = {}

func clear() -> void:
	tiles_by_cell.clear()
	for child: Node in get_children():
		child.queue_free()
		remove_child(child)


func set_cell(cell_pos: Vector2i, value: int) -> void:
	var should_have_clue: bool = NurikabeUtils.is_clue(value)
	var has_clue: bool = tiles_by_cell.has(cell_pos)
	
	if not has_clue and should_have_clue:
		var label: ClueLabel3D = CLUE_LABEL_SCENE.instantiate()
		label.name = "clue_%s_%s" % [cell_pos.x, cell_pos.y]
		add_child(label)
		tiles_by_cell[cell_pos] = label
		if Engine.is_editor_hint():
			label.owner = get_tree().edited_scene_root
		
		label.scale.x = tile_size.x
		label.scale.z = tile_size.y
		label.position.x = cell_pos.x * tile_size.x + LABEL_OFFSET.x * tile_size.x
		label.position.y = TILE_HEIGHT # elevate the label above the tile
		label.position.z = cell_pos.y * tile_size.y + LABEL_OFFSET.y * tile_size.y
	elif has_clue and not should_have_clue:
		tiles_by_cell[cell_pos].queue_free()
		tiles_by_cell.erase(cell_pos)
	
	if should_have_clue:
		# assign the tile properties
		tiles_by_cell[cell_pos].clue = value
