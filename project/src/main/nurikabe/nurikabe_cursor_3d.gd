@tool
extends Node3D

const TEXTURE_OUTLINE: Texture2D = preload("res://assets/main/nurikabe/cursor_outline_cursor_outline.png")
const TEXTURE_CENTER: Texture2D = preload("res://assets/main/nurikabe/cursor_center_cursor_center.png")

@export var outline_color: Color = Color.BLACK:
	set(value):
		if outline_color == value:
			return
		outline_color = value
		_dirty = true

@export var cursor_color: Color = Color.WHITE:
	set(value):
		if cursor_color == value:
			return
		cursor_color = value
		_dirty = true

var _dirty: bool = false

func _ready() -> void:
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if not _dirty:
		return
	
	_dirty = false
	
	var outline_mesh: MeshInstance3D = %Outline.get_child(0)
	var outline_mat: StandardMaterial3D = StandardMaterial3D.new()
	outline_mat.albedo_color = outline_color
	outline_mat.albedo_texture = TEXTURE_OUTLINE
	outline_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_mat.no_depth_test = true
	outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_mat.render_priority = 2
	outline_mesh.material_override = outline_mat
	
	var center_mesh: MeshInstance3D = %Center.get_child(0)
	var center_mat: StandardMaterial3D = StandardMaterial3D.new()
	center_mat.albedo_color = cursor_color
	center_mat.albedo_texture = TEXTURE_CENTER
	center_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	center_mat.no_depth_test = true
	center_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	center_mat.render_priority = 1
	center_mesh.material_override = center_mat
