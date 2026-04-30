@tool
extends Node

const GRASS_TILES: Array[int] = [1, 2]

@export var scatter_seed: int = 0
@export_tool_button("Scatter") var scatter_action: Callable = scatter

@export var ground_map: GroundMap
@export var prop_map: GridMap

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var rng_ops: RngOps = RngOps.new(rng)

var scatter_definitions: Dictionary[int, ScatterDef] = {
	0: ScatterDef.new(0.003, GRASS_TILES, 1), # tree 1
	1: ScatterDef.new(0.003, GRASS_TILES, 1), # tree 2
	2: ScatterDef.new(0.003, GRASS_TILES, 1), # tree 3
	3: ScatterDef.new(0.012, GRASS_TILES), # bush 1
	4: ScatterDef.new(0.012, GRASS_TILES), # bush 2
	5: ScatterDef.new(0.018, GRASS_TILES), # flower 1
	6: ScatterDef.new(0.018, GRASS_TILES), # flower 2
}

func scatter() -> void:
	rng.seed = scatter_seed
	prop_map.clear()
	
	var scatterable_cell_set: Dictionary[Vector3i, bool] = {}
	for cell: Vector3i in ground_map.get_used_cells():
		scatterable_cell_set[Vector3i(cell.x, 0, cell.z)] = true
	var scatterable_cells: Array[Vector3i] = scatterable_cell_set.keys()
	rng_ops.shuffle(scatterable_cells)
	
	# cells excluded from scattering
	var blocked_cells: Dictionary[Vector3i, bool] = {}
	
	# drop placeholders to ensure trees aren't scattered near puzzles
	var placeholder_cells: Array[Vector3i] = []
	for spawn: PuzzleSpawn in get_tree().get_nodes_in_group("puzzle_spawns"):
		var map_rect: Rect2i = ground_map.aabb_to_map_rect(spawn.get_global_aabb())
		for x in range(map_rect.position.x, map_rect.end.x):
			for y in range(map_rect.position.y, map_rect.end.y):
				placeholder_cells.append(Vector3i(x, 0, y))
	
	for cell: Vector3i in placeholder_cells:
		prop_map.set_cell_item(cell, 5)
		blocked_cells[cell] = true
	
	for prop_cell: Vector3i in scatterable_cells:
		if prop_cell in blocked_cells:
			continue
		var ground_cell: Vector3i = Vector3i(prop_cell.x, -1, prop_cell.z)
		var ground_tile: int = ground_map.get_cell_item(ground_cell)
		for prop_tile: int in scatter_definitions:
			var scatter_def: ScatterDef = scatter_definitions[prop_tile]
			if not rng.randf() < scatter_def.freq:
				continue
			if not scatter_def.target.has(ground_tile):
				continue
			if not has_clearance(prop_cell, scatter_def):
				continue
			prop_map.set_cell_item(prop_cell, prop_tile)
			blocked_cells[prop_cell] = true
			var clearance_prop_cells: Array[Vector3i] = get_clearance_prop_cells(prop_cell, scatter_def)
			for clearance_prop_cell: Vector3i in clearance_prop_cells:
				blocked_cells[clearance_prop_cell] = true
			break
	
	# erase placeholders
	for cell: Vector3i in placeholder_cells:
		prop_map.set_cell_item(cell, -1)


func has_clearance(prop_cell: Vector3i, scatter_def: ScatterDef) -> bool:
	var result: bool = true
	var clearance_prop_cells: Array[Vector3i] = get_clearance_prop_cells(prop_cell, scatter_def)
	for clearance_prop_cell: Vector3i in clearance_prop_cells:
		var clearance_ground_cell: Vector3i = Vector3i(clearance_prop_cell.x, -1, clearance_prop_cell.z)
		var clearance_ground_tile: int = ground_map.get_cell_item(clearance_ground_cell)
		if not scatter_def.target.has(clearance_ground_tile):
			# prop is too close to a non-target tile (e.g. tree is near water)
			result = false
			break
		var clearance_prop_tile: int = prop_map.get_cell_item(clearance_prop_cell)
		if clearance_prop_tile != -1:
			# prop is too close to another prop
			result = false
			break
	return result


func get_clearance_prop_cells(prop_cell: Vector3i, scatter_def: ScatterDef) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for dx: int in range(-scatter_def.min_clearance, scatter_def.min_clearance + 1):
		var dz_range: int = scatter_def.min_clearance - abs(dx)
		for dz: int in range(-dz_range, dz_range + 1):
			if dx == 0 and dz == 0:
				continue
			cells.append(prop_cell + Vector3i(dx, 0, dz))
	return cells


class ScatterDef:
	var freq: float = 0.0
	var target: Array[int] = []
	var min_clearance: int = 0
	
	func _init(init_freq: float, init_target: Array[int] = [], init_min_clearance: int = 0) -> void:
		freq = init_freq
		target = init_target
		min_clearance = init_min_clearance
