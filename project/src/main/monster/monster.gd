@tool
class_name Monster
extends CharacterBody2D

enum MonsterSkin {
	BEIGE,
	GREEN,
	PINK,
	PURPLE,
	YELLOW,
}

const SPRITE_FRAMES_BY_SKIN: Dictionary[MonsterSkin, SpriteFrames] = {
	MonsterSkin.BEIGE: preload("res://src/main/monster/monster_frames_beige.tres"),
	MonsterSkin.GREEN: preload("res://src/main/monster/monster_frames_green.tres"),
	MonsterSkin.PINK: preload("res://src/main/monster/monster_frames_pink.tres"),
	MonsterSkin.PURPLE: preload("res://src/main/monster/monster_frames_purple.tres"),
	MonsterSkin.YELLOW: preload("res://src/main/monster/monster_frames_yellow.tres"),
}

const CURSOR_COLOR_BY_SKIN: Dictionary[MonsterSkin, Color] = {
	MonsterSkin.BEIGE: Color(0.886, 0.765, 0.671, 1.0),
	MonsterSkin.GREEN: Color(0.365, 0.831, 0.667, 1.0),
	MonsterSkin.PINK: Color(1.0, 0.541, 0.682, 1.0),
	MonsterSkin.PURPLE: Color(0.78, 0.714, 1.0, 1.0),
	MonsterSkin.YELLOW: Color(0.98, 0.729, 0.176, 1.0),
}

const ELEVATION_PER_Z_INDEX: float = 24.0

const JUMP_DURATION: float = 0.2
const FALL_DURATION: float = 0.2
const MAX_SPEED: float = 400.0
const ACCELERATION: float = 3000.0

static var _next_id: int = 0

@export var skin: MonsterSkin = MonsterSkin.PURPLE:
	set(value):
		if skin == value:
			return
		skin = value
		_refresh_skin()


@export var elevation: float:
	set(value):
		if elevation == value:
			return
		elevation = value
		_dirty = true

var direction: Vector2 = Vector2.ZERO:
	set(value):
		if value == direction:
			return
		direction = value
		_dirty = true

var _dirty: bool = false
var _elevation_tween: Tween
var _fade_tween: Tween

var id: int

var on_steppable: bool = false
var current_game_board: NurikabeGameBoard

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var fsm: StateMachine = %StateMachine
@onready var cursor: MonsterCursor = %Cursor

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
	update_input()
	fsm.physics_update(delta)


## Overridden by subclasses to apply the monster's desired input (running around, moving the cursor)
func update_input() -> void:
	pass


func refresh(force: bool = false) -> void:
	if not force and not _dirty:
		return
	_dirty = false
	
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	z_index = clampi(2 * ceili(elevation / ELEVATION_PER_Z_INDEX), 0, 10)
	sprite.position = Vector2(0.0, -elevation)


func tween_elevation(final_val: float, duration: float) -> PropertyTweener:
	_elevation_tween = Utils.recreate_tween(self, _elevation_tween)
	return _elevation_tween.tween_property(self, "elevation", final_val, duration)


func _refresh_skin() -> void:
	if not is_inside_tree():
		return
	
	%AnimatedSprite2D.sprite_frames = SPRITE_FRAMES_BY_SKIN[skin]
	%Cursor.color = CURSOR_COLOR_BY_SKIN[skin]


func _on_cursor_tracker_overlap_ended() -> void:
	_fade_tween = Utils.recreate_tween(self, _fade_tween)
	_fade_tween.tween_property(%AnimatedSprite2D, "modulate:a", 1.0, 0.25)


func _on_cursor_tracker_overlap_started() -> void:
	_fade_tween = Utils.recreate_tween(self, _fade_tween)
	_fade_tween.tween_property(%AnimatedSprite2D, "modulate:a", 0.33, 0.25)


func _on_steppable_tracker_overlap_ended() -> void:
	on_steppable = false


func _on_steppable_tracker_overlap_started() -> void:
	on_steppable = true
