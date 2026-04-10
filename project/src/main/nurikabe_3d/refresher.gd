extends Node3D

signal refresh_requested

const MAX_SHOWN_TIME_SECONDS: int = 5999 # 99:99 display limit
const SPRITE_SCALE: Vector3 = Vector3(2.3, 2.3, 2.3)

var shown_time_remaining: int = -1
var hovered: bool = false
var scale_tween: Tween
var flash_tween: Tween

func _ready() -> void:
	%AnimatedSprite3D.play()


func get_global_aabb() -> AABB:
	return AABB(global_position + Vector3(0.0, 1.0, 0.0), Vector3(4.0, 2.0, 2.0))


func _process(_delta: float) -> void:
	shown_time_remaining = ceili(clamp(%RefreshTimer.time_left, 0, MAX_SHOWN_TIME_SECONDS))
	if hovered:
		%Label3D.text = "New puzzles\nnow?"
	else:
		%Label3D.text = "New puzzles\nin %s" % [_format_duration(shown_time_remaining)]


func _format_duration(seconds: float) -> String:
	var seconds_int: int = ceili(seconds)
	@warning_ignore("integer_division")
	return "%01d:%02d" % [seconds_int / 60, seconds_int % 60]


func _on_refresh_timer_timeout() -> void:
	SoundManager.play_sfx("refresh_puzzles")
	refresh_requested.emit()


func _on_click_area_mouse_entered() -> void:
	if hovered == true:
		return
	hovered = true
	
	scale_tween = Utils.recreate_tween(self, scale_tween)
	scale_tween.tween_property(%AnimatedSprite3D, "scale", SPRITE_SCALE * 1.13, 0.05) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_sprite(0.5)
	SoundManager.play_sfx("button_hover")


func _on_click_area_mouse_exited() -> void:
	if hovered == false:
		return
	hovered = false
	
	scale_tween = Utils.recreate_tween(self, scale_tween)
	scale_tween.tween_property(%AnimatedSprite3D, "scale", SPRITE_SCALE, 0.05) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_click_area_input_event(
		_camera: Node, event: InputEvent, _event_position: Vector3,
		_normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		refresh_requested.emit()
		%RefreshTimer.start()
		
		scale_tween = Utils.recreate_tween(self, scale_tween)
		scale_tween.tween_property(%AnimatedSprite3D, "scale", SPRITE_SCALE * Vector3(1.13, 0.87, 1.0), 0.04)
		scale_tween.tween_property(%AnimatedSprite3D, "scale", SPRITE_SCALE * Vector3(0.93, 1.06, 1.0), 0.08)
		scale_tween.tween_property(%AnimatedSprite3D, "scale", SPRITE_SCALE, 0.08)
		_flash_sprite()
		
		SoundManager.play_sfx("refresh_puzzles")
		SoundManager.play_sfx("button_click")
		get_viewport().set_input_as_handled()


func _flash_sprite(amount: float = 1.0) -> void:
	var flash_color: Color = Color(1.0, 1.0, 1.0, lerp(0.0, 1.0, amount))
	var flash_duration: float = lerp(0.0, 0.5, amount)
	
	%AnimatedSprite3D.material_override.set_shader_parameter("mix_color", flash_color)
	flash_tween = Utils.recreate_tween(self, flash_tween)
	flash_tween.tween_property(%AnimatedSprite3D, "material_override:shader_parameter/mix_color",
			Color(1.0, 1.0, 1.0, 0.0), flash_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_animated_sprite_3d_frame_changed() -> void:
	%AnimatedSprite3D.material_override.set_shader_parameter("tex", \
			%AnimatedSprite3D.sprite_frames.get_frame_texture(%AnimatedSprite3D.animation, %AnimatedSprite3D.frame))
