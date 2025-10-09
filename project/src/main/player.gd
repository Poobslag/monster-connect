class_name Player
extends CharacterBody2D

const ELEVATION_PER_Z_INDEX: float = 32.0

const MAX_SPEED: float = 400.0
const ACCELERATION: float = 3000.0

var direction: Vector2 = Vector2.ZERO:
	set(value):
		if value == direction:
			return
		direction = value
		_dirty = true

@export var elevation: float:
	set(value):
		if elevation == value:
			return
		elevation = value
		_dirty = true

var _dirty: bool = false
var _elevation_tween: Tween

var on_steppable: bool = false

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var fsm: StateMachine = %StateMachine
@onready var input: PlayerInputHandler = %InputHandler

func _ready() -> void:
	fsm.change_state("idle")
	refresh()


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
	z_index = clampi(ceili(elevation / ELEVATION_PER_Z_INDEX), 0, 10)
	sprite.position = Vector2(0.0, -elevation)


func tween_elevation(final_val: float, duration: float) -> PropertyTweener:
	_elevation_tween = Utils.recreate_tween(self, _elevation_tween)
	return _elevation_tween.tween_property(self, "elevation", final_val, duration)


func _on_steppable_detector_stepped_on() -> void:
	on_steppable = true


func _on_steppable_detector_stepped_off() -> void:
	on_steppable = false
