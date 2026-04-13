extends ColorRect

@export var max_lines: int = 500

var text: String:
	get():
		return %RichTextLabel.text
	set(value):
		%RichTextLabel.text = text

func log_message(message: String) -> void:
	if %RichTextLabel.text:
		%RichTextLabel.text += "\n"
	%RichTextLabel.text += message
	while %RichTextLabel.get_line_count() > max_lines:
		%RichTextLabel.text = StringUtils.substring_after(%RichTextLabel.text, "\n")
