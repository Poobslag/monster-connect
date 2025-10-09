class_name PlayerBaseState
extends State

var player: Player:
	get: return object


var input: Vector2:
	get: return player.input.dir


func play(animation: String) -> void:
	player.sprite.play(animation)


func accelerate(delta: float, direction: Vector2 = input) -> void:
	player.velocity = player.velocity.move_toward(Player.MAX_SPEED * direction, Player.ACCELERATION * delta)


func move(delta: float, update_direction: bool = true, direction: Vector2 = input) -> void:
	accelerate(delta, direction)
	if update_direction:
		player.direction = direction
	player.move_and_slide()
