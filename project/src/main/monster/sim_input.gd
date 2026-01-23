class_name SimInput
extends MonsterInput

@onready var monster: Monster = Utils.find_parent_of_type(self, Monster)

func update() -> void:
	pass


func _find_other_monster() -> Monster:
	var monsters: Array[Node] = get_tree().get_nodes_in_group("monsters")
	if monsters.size() <= 1:
		return null
	monsters.shuffle()
	return monsters[1] if monsters[0] == monster else monsters[0]


func _on_input_timer_timeout() -> void:
	if dir != Vector2.ZERO:
		dir = Vector2.ZERO
	elif randf() < 0.3:
		# move towards another monster
		var other_monster: Monster = _find_other_monster()
		if other_monster != null:
			dir = (other_monster.position - monster.position).normalized()
	else:
		# move randomly
		dir = Vector2.RIGHT.rotated(randf_range(-PI, PI))
