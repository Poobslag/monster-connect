class_name MonsterBaseState
extends State

var monster: Monster:
	get: return object


var input: Vector2:
	get: return monster.input.dir


func play(animation: String) -> void:
	monster.sprite.play(animation)


func accelerate(delta: float, direction: Vector2 = input) -> void:
	monster.velocity = monster.velocity.move_toward(Monster.MAX_SPEED * direction, Monster.ACCELERATION * delta)


func move(delta: float, update_direction: bool = true, direction: Vector2 = input) -> void:
	accelerate(delta, direction)
	if update_direction:
		monster.direction = direction
	monster.move_and_slide()
