extends Control

@export var cursor_scene: PackedScene

var _cursors_by_monster: Dictionary[Monster3D, Node2D] = {}

func _ready() -> void:
	remove_all_cursors()
	%Monsters.child_entered_tree.connect(func(node: Node) -> void:
		add_cursor(node))
	%Monsters.child_exiting_tree.connect(func(node: Node) -> void:
		remove_cursor(node))
	for monster: Monster3D in get_tree().get_nodes_in_group("monsters"):
		add_cursor(monster)


func _process(_delta: float) -> void:
	for monster: Monster3D in _cursors_by_monster:
		update_cursor(monster)


func add_cursor(monster: Monster3D) -> void:
	var cursor: Node2D = cursor_scene.instantiate()
	_cursors_by_monster[monster] = cursor
	add_child(cursor)
	update_cursor(monster)


func remove_cursor(monster: Monster3D) -> void:
	var cursor: Node2D = _cursors_by_monster[monster]
	_cursors_by_monster.erase(monster)
	cursor.queue_free()


func update_cursor(monster: Monster3D) -> void:
	var cursor: Node2D = _cursors_by_monster[monster]
	var camera: Camera3D = get_viewport().get_camera_3d()
	cursor.position = camera.unproject_position(monster.cursor_3d.global_position)


func remove_all_cursors() -> void:
	for cursor: Node in get_children():
		cursor.queue_free()
