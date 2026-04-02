extends Node

@onready var input_handler: MonsterInput3D = get_parent()
@onready var monster: Monster3D = Utils.find_parent_of_type(self, Monster3D)

func handle(_event: InputEvent) -> void:
	pass


func update() -> void:
	pass
