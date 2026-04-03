class_name MonsterBaseState3D
extends State

const JUMP_THRESHOLD: float = 0.10

var position_delta: Vector3 = Vector3.ZERO

var monster: Monster3D:
	get: return object


var input: Vector2:
	get: return monster.input.dir


func play(animation: String) -> void:
	monster.sprite.play(animation)


func accelerate(delta: float, direction: Vector2 = input) -> void:
	var direction_3d := Vector3(direction.x, monster.velocity.y, direction.y)
	monster.velocity = monster.velocity.move_toward(Monster3D.MAX_SPEED * direction_3d, Monster3D.ACCELERATION * delta)


func move(delta: float, update_direction: bool = true, direction: Vector2 = input) -> void:
	var old_position: Vector3 = monster.position
	accelerate(delta, direction)
	if update_direction:
		monster.direction = direction
	monster.move_and_slide()
	position_delta = monster.position - old_position
