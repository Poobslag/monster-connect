@tool
extends GridMap

## Template for running arbitrary code in the editor
@export_tool_button("Editor Action") var editor_action: Callable = func() -> void:
	#for x in range(-75, 75):
	#	for z in range(-75, 75):
	#		set_cell_item(Vector3(x, -1, z), 0)
	pass
