extends RichTextLabel

@export var max_lines: int = 500

func show_message(message: String) -> void:
	if text:
		text += "\n"
	text += message
	while get_line_count() > max_lines:
		text = StringUtils.substring_after(text, "\n")
