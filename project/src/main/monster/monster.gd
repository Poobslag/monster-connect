@tool
class_name Monster
extends CharacterBody3D

enum MonsterSkin {
	NONE,
	BEIGE,
	GREEN,
	PINK,
	PURPLE,
	YELLOW,
}

const SPRITE_FRAMES_BY_SKIN: Dictionary[MonsterSkin, SpriteFrames] = {
	MonsterSkin.NONE: preload("res://src/main/monster/monster_frames_beige.tres"),
	MonsterSkin.BEIGE: preload("res://src/main/monster/monster_frames_beige.tres"),
	MonsterSkin.GREEN: preload("res://src/main/monster/monster_frames_green.tres"),
	MonsterSkin.PINK: preload("res://src/main/monster/monster_frames_pink.tres"),
	MonsterSkin.PURPLE: preload("res://src/main/monster/monster_frames_purple.tres"),
	MonsterSkin.YELLOW: preload("res://src/main/monster/monster_frames_yellow.tres"),
}

const CURSOR_COLOR_BY_SKIN: Dictionary[MonsterSkin, Color] = {
	MonsterSkin.NONE: Color.BLACK,
	MonsterSkin.BEIGE: Color(0.886, 0.765, 0.671, 1.0),
	MonsterSkin.GREEN: Color(0.365, 0.831, 0.667, 1.0),
	MonsterSkin.PINK: Color(1.0, 0.541, 0.682, 1.0),
	MonsterSkin.PURPLE: Color(0.78, 0.714, 1.0, 1.0),
	MonsterSkin.YELLOW: Color(0.98, 0.729, 0.176, 1.0),
}

const FONT_COLOR_BY_SKIN: Dictionary[MonsterSkin, Color] = {
	MonsterSkin.NONE: Color.WHITE,
	MonsterSkin.BEIGE: Color(0.886, 0.765, 0.671, 1.0),
	MonsterSkin.GREEN: Color(0.365, 0.831, 0.667, 1.0),
	MonsterSkin.PINK: Color(1.0, 0.541, 0.682, 1.0),
	MonsterSkin.PURPLE: Color(0.78, 0.714, 1.0, 1.0),
	MonsterSkin.YELLOW: Color(0.98, 0.729, 0.176, 1.0),
}

const JUMP_DURATION: float = 0.3
const FALL_DURATION: float = 0.3
const MAX_SPEED: float = 4.375
const ACCELERATION: float = 31.25

const STEP_RAY_LENGTH: float = 0.5
const STEP_HEIGHT: float = 0.5

const FADE_DURATION: float = 0.20

static var _next_id: int = 0

@export var skin: MonsterSkin = MonsterSkin.PURPLE:
	set(value):
		if skin == value:
			return
		skin = value
		_refresh_skin()

## Movement direction. Length is at most 1.0.
var direction: Vector2 = Vector2.ZERO:
	set(value):
		if value == direction:
			return
		direction = value
		_dirty = true

var id: int
var cursor_board: NurikabeGameBoard3D
var display_name: String = "":
	set(value):
		display_name = value
		%NameLabel.text = display_name

var _dirty: bool = false
var _fade_tween: Tween

@onready var sprite: AnimatedSprite3D = %AnimatedSprite3D
@onready var fsm: StateMachine = %StateMachine
@onready var cursor_3d: Node3D = %Cursor
@onready var gravity: Vector3 = \
		ProjectSettings.get_setting("physics/3d/default_gravity_vector") \
		* ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	if Engine.is_editor_hint():
		# don't interact with fsm in editor
		return
	
	fsm.change_state("idle")
	refresh()
	_refresh_skin()
	
	id = _next_id
	_next_id += 1


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# don't run physics simulation in editor
		return
	
	refresh()
	update_input(delta)
	if not is_on_floor():
		velocity += gravity * delta
	
	fsm.physics_update(delta)


func apply_step_up() -> void:
	if direction.length() < 0.1:
		return
	
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for angle_offset: float in [0.0, -0.125 * PI, 0.125 * PI, -0.25 * PI, 0.25 * PI]:
		var rotated_dir: Vector2 = direction.rotated(angle_offset).normalized()
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			global_position,
			global_position + STEP_RAY_LENGTH * Vector3(rotated_dir.x, 0.1, rotated_dir.y),
		)
		query.collision_mask = 0b00000000_00000000_00000000_00000100
		var query_result: Dictionary = space.intersect_ray(query)
		if not query_result:
			continue
		var step_surface_y: float = _get_step_surface_y(
				query_result["position"] + 0.1 * Vector3(rotated_dir.x, 0.1, rotated_dir.y))
		var step_delta: float = step_surface_y - global_position.y
		if step_delta > 0.01 and step_delta <= STEP_HEIGHT:
			global_position.y = step_surface_y
			break


## Overridden by subclasses to apply the monster's desired input (running around, moving the cursor)
func update_input(_delta: float) -> void:
	pass


func refresh(force: bool = false) -> void:
	if not force and not _dirty:
		return
	_dirty = false
	
	if direction.x != 0:
		sprite.flip_h = direction.x < 0


func _get_step_surface_y(step_ray_hit: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		step_ray_hit + Vector3(0, 0.5, 0),
		step_ray_hit + Vector3(0, -0.5, 0),
	)
	query.collision_mask = 0b00000000_00000000_00000000_00000100
	var result: Dictionary = space.intersect_ray(query)
	return result["position"].y if result else global_position.y


func _refresh_skin() -> void:
	if not is_inside_tree():
		return
	
	%AnimatedSprite3D.sprite_frames = SPRITE_FRAMES_BY_SKIN[skin]
	%NameLabel.outline_modulate = FONT_COLOR_BY_SKIN[skin]
	%PuzzleCursor.cursor_color = CURSOR_COLOR_BY_SKIN[skin]


func _on_click_area_mouse_entered() -> void:
	_fade_tween = Utils.recreate_tween(self, _fade_tween).set_parallel()
	_fade_tween.tween_property(%AnimatedSprite3D, "modulate:a", 0.33, FADE_DURATION)
	_fade_tween.tween_property(%NameLabel, "modulate:a", 0.33, FADE_DURATION)
	_fade_tween.tween_property(%NameLabel, "outline_modulate:a", 0.33, FADE_DURATION)


func _on_click_area_mouse_exited() -> void:
	_fade_tween = Utils.recreate_tween(self, _fade_tween).set_parallel()
	_fade_tween.tween_property(%AnimatedSprite3D, "modulate:a", 1.0, FADE_DURATION)
	_fade_tween.tween_property(%NameLabel, "modulate:a", 1.0, FADE_DURATION)
	_fade_tween.tween_property(%NameLabel, "outline_modulate:a", 1.0, FADE_DURATION)
