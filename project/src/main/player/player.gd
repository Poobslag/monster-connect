class_name Player
extends CharacterBody2D

const ELEVATION_PER_Z_INDEX: float = 24.0

const JUMP_DURATION: float = 0.2
const FALL_DURATION: float = 0.2
const MAX_SPEED: float = 400.0
const ACCELERATION: float = 3000.0

static var _next_id: int = 0

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
@onready var input: PlayerInputHandler = %InputHandler
@onready var cursor: PlayerCursor = %Cursor

func _ready() -> void:
	fsm.change_state("idle")
	refresh()
	
	id = _next_id
	_next_id += 1


func _physics_process(delta: float) -> void:
	refresh()
	input.update()
	fsm.physics_update(delta)


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
