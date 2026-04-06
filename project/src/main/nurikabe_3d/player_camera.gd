class_name PlayerCamera3D
extends Camera3D
## A camera which follows the player and focuses on puzzles.
## [br]
## This camera handles the logic for focusing on a target from a given offset and the camera drift. The child states
## manipulate the target and offset.

const PUZZLE_PADDING: float = 1.2
const PAN_DURATION: float = 0.6
const ZOOM_DEFAULT: Vector2 = Vector2(1.2, 1.2)

@export var player: PlayerMonster3D
@export var follow_speed: float = 3.0
@export var player_offset: Vector3 = Vector3.ZERO

@export var target_position: Vector3 = Vector3.ZERO
@export var target_offset: Vector3 = Vector3.ZERO

@export var drift_amount: float = 0.0
@export var drift_duration: float = 15.0

func _ready() -> void:
	target_position = player.position
	target_offset = player_offset
	position = target_position + target_offset
	
	%StateMachine.change_state("toplayer")
	player.solving_board_changed.connect(func() -> void:
		var new_state: String = "toplayer" if player.solving_board == null else "topuzzle"
		%StateMachine.change_state(new_state))


func _process(delta: float) -> void:
	if !player:
		return
	
	%StateMachine.update(delta)
	
	position = lerp(position, target_position + target_offset, follow_speed * delta)
	
	# Sway the camera to prevent horizontal banding (issue #371)
	var sway_cycle: float = Time.get_ticks_usec() / 1000000.0 / drift_duration
	rotation = Vector3(
			deg_to_rad(-60 + drift_amount * cos(sway_cycle)),
			deg_to_rad(0 + drift_amount * sin(sway_cycle)),
			0)


## Returns the camera focus point for the active puzzle.[br]
## [br]
## The focus point is adjusted slightly to compensate for camera pitch.
func get_puzzle_position() -> Vector3:
	var puzzle_aabb: AABB = player.solving_board.get_aabb()
	return puzzle_aabb.position + Vector3(
		puzzle_aabb.size.x * 0.5,
		puzzle_aabb.size.y * 0.0,
		puzzle_aabb.size.z * 0.57,
	)


func get_puzzle_offset() -> Vector3:
	var target_size: Vector3 = player.solving_board.get_aabb().size
	var vfov: float = deg_to_rad(fov) # Camera.fov is vertical
	var hfov: float = deg_to_rad(get_camera_projection().get_fov()) # Projection.fov is horizontal
	
	# The puzzle is flat, but the camera is pitched downward, so the puzzle's depth is foreshortened on screen. Adjust
	# for this by multiplying by sin(pitch)
	var camera_pitch: float = abs(rotation.x)
	var projected_height: float = target_size.z * sin(camera_pitch)
	
	# Calculate the camera distance where the puzzle edge lands at the frustum edge using trig.
	# distance = half_extent / tan(half_fov)
	var dist_for_height: float = (projected_height / 2.0) / tan(vfov / 2.0)
	var dist_for_width: float = (target_size.x / 2.0) / tan(hfov / 2.0)
	
	var dist: float = max(dist_for_width, dist_for_height) * PUZZLE_PADDING
	dist = max(dist, player_offset.length())
	
	return player_offset.normalized() * dist
