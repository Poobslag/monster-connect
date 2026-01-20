extends Control

signal refresh_requested

const MAX_SHOWN_TIME_SECONDS: int = 5999 # 99:99 display limit

var shown_time_remaining: int = -1
var hovered: bool = false
var scale_tween: Tween
var flash_tween: Tween

func _ready() -> void:
	%AnimatedSprite2D.play()


func _process(_delta: float) -> void:
	shown_time_remaining = ceili(clamp(%RefreshTimer.time_left, 0, MAX_SHOWN_TIME_SECONDS))
	if hovered:
		%Label.text = "New puzzles\nnow?"
	else:
		%Label.text = "New puzzles\nin %s" % [_format_duration(shown_time_remaining)]


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
	scale_tween.tween_property(%AnimatedSprite2D, "scale", 1.7 * Vector2.ONE, 0.05) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_sprite(0.5)
	SoundManager.play_sfx("button_hover")


func _on_click_area_mouse_exited() -> void:
	if hovered == false:
		return
	hovered = false
	
	scale_tween = Utils.recreate_tween(self, scale_tween)
	scale_tween.tween_property(%AnimatedSprite2D, "scale", 1.5 * Vector2.ONE, 0.05) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		refresh_requested.emit()
		%RefreshTimer.start()
		
		scale_tween = Utils.recreate_tween(self, scale_tween)
		scale_tween.tween_property(%AnimatedSprite2D, "scale", Vector2(1.70, 1.30), 0.04)
		scale_tween.tween_property(%AnimatedSprite2D, "scale", Vector2(1.40, 1.60), 0.08)
		scale_tween.tween_property(%AnimatedSprite2D, "scale", Vector2(1.50, 1.50), 0.08)
		_flash_sprite()
		
		SoundManager.play_sfx("refresh_puzzles")
		SoundManager.play_sfx("button_click")
		get_viewport().set_input_as_handled()


func _flash_sprite(amount: float = 1.0) -> void:
	var flash_color: Color = Color(1.0, 1.0, 1.0, lerp(0.0, 1.0, amount))
	var flash_duration: float = lerp(0.0, 0.5, amount)
	
	%AnimatedSprite2D.material.set_shader_parameter("mix_color", flash_color)
	flash_tween = Utils.recreate_tween(self, flash_tween)
	flash_tween.tween_property(%AnimatedSprite2D, "material:shader_parameter/mix_color",
			Color(1.0, 1.0, 1.0, 0.0), flash_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
