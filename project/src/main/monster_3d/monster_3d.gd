class_name Monster3D
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

static var _next_id: int = 0

@export var skin: MonsterSkin = MonsterSkin.PURPLE:
	set(value):
		if skin == value:
			return
		skin = value
		_refresh_skin()

var direction: Vector2 = Vector2.ZERO:
	set(value):
		if value == direction:
			return
		direction = value
		_dirty = true

var _dirty: bool = false

var id: int

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var fsm: StateMachine = %StateMachine

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
	fsm.physics_update(delta)


## Overridden by subclasses to apply the monster's desired input (running around, moving the cursor)
func update_input(_delta: float) -> void:
	pass


func refresh(force: bool = false) -> void:
	if not force and not _dirty:
		return
	_dirty = false
	
	if direction.x != 0:
		sprite.flip_h = direction.x < 0


func _refresh_skin() -> void:
	if not is_inside_tree():
		return
	
	%AnimatedSprite2D.sprite_frames = SPRITE_FRAMES_BY_SKIN[skin]
