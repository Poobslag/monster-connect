extends Label


func _ready() -> void:
	text = ""


func _on_timer_timeout() -> void:
	text = "fps: %s" % [Engine.get_frames_per_second()]
