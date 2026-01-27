class_name NaiveSolver
extends Node

const BUDGET_USEC: int = 4167 # 1/240 of a second

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

const NEIGHBOR_DIRS: Array[Vector2i] = NurikabeUtils.NEIGHBOR_DIRS

## starting techniques
const ISLAND_OF_ONE: Deduction.Reason = Deduction.Reason.ISLAND_OF_ONE
const ADJACENT_CLUES: Deduction.Reason = Deduction.Reason.ADJACENT_CLUES

## basic techniques
const CORNER_BUFFER: Deduction.Reason = Deduction.Reason.CORNER_BUFFER
const CORNER_ISLAND: Deduction.Reason = Deduction.Reason.CORNER_ISLAND
const ISLAND_BUBBLE: Deduction.Reason = Deduction.Reason.ISLAND_BUBBLE
const ISLAND_BUFFER: Deduction.Reason = Deduction.Reason.ISLAND_BUFFER
const ISLAND_CHAIN: Deduction.Reason = Deduction.Reason.ISLAND_CHAIN
const ISLAND_CHOKEPOINT: Deduction.Reason = Deduction.Reason.ISLAND_CHOKEPOINT
const ISLAND_CONNECTOR: Deduction.Reason = Deduction.Reason.ISLAND_CONNECTOR
const ISLAND_DIVIDER: Deduction.Reason = Deduction.Reason.ISLAND_DIVIDER
const ISLAND_EXPANSION: Deduction.Reason = Deduction.Reason.ISLAND_EXPANSION
const ISLAND_MOAT: Deduction.Reason = Deduction.Reason.ISLAND_MOAT
const ISLAND_SNUG: Deduction.Reason = Deduction.Reason.ISLAND_SNUG
const POOL_CHOKEPOINT: Deduction.Reason = Deduction.Reason.POOL_CHOKEPOINT
const POOL_TRIPLET: Deduction.Reason = Deduction.Reason.POOL_TRIPLET
const UNCLUED_LIFELINE: Deduction.Reason = Deduction.Reason.UNCLUED_LIFELINE
const UNREACHABLE_CELL: Deduction.Reason = Deduction.Reason.UNREACHABLE_CELL
const WALL_BUBBLE: Deduction.Reason = Deduction.Reason.WALL_BUBBLE
const WALL_CONNECTOR: Deduction.Reason = Deduction.Reason.WALL_CONNECTOR
const WALL_EXPANSION: Deduction.Reason = Deduction.Reason.WALL_EXPANSION
const WALL_WEAVER: Deduction.Reason = Deduction.Reason.WALL_WEAVER

## advanced techniques
const ASSUMPTION: Deduction.Reason = Deduction.Reason.ASSUMPTION
const BORDER_HUG: Deduction.Reason = Deduction.Reason.BORDER_HUG
const ISLAND_BATTLEGROUND: Deduction.Reason = Deduction.Reason.ISLAND_BATTLEGROUND
const ISLAND_RELEASE: Deduction.Reason = Deduction.Reason.ISLAND_RELEASE
const ISLAND_STRANGLE: Deduction.Reason = Deduction.Reason.ISLAND_STRANGLE
const WALL_STRANGLE: Deduction.Reason = Deduction.Reason.WALL_STRANGLE

const FUN_TRIVIAL: Deduction.FunAxis = Deduction.FunAxis.FUN_TRIVIAL
const FUN_FAST: Deduction.FunAxis = Deduction.FunAxis.FUN_FAST
const FUN_NOVELTY: Deduction.FunAxis = Deduction.FunAxis.FUN_NOVELTY
const FUN_THINK: Deduction.FunAxis = Deduction.FunAxis.FUN_THINK
const FUN_BIFURCATE: Deduction.FunAxis = Deduction.FunAxis.FUN_BIFURCATE

@export var verbose: bool = false

var monster_index: int = -1
var monsters: Array[SimMonster] = []
var scanners_by_monster: Dictionary[SimMonster, Array] = {}

var _budget_available: int = 0
var _budget_used: int = 0
var _frames_available: int = 0
var _frames_active: int = 0

func _ready() -> void:
	if verbose:
		%VerboseTimer.start()


func _process(_delta: float) -> void:
	_frames_available += 1
	if not monsters:
		return
	
	monster_index = clampi(monster_index, 0, monsters.size() - 1)
	var start_time: int = Time.get_ticks_usec()
	while not scanners_by_monster.is_empty():
		# get the current monster
		var monster: SimMonster = monsters[monster_index]
		var scanners: Array[NaiveScanner] = scanners_by_monster[monster]
		var scanner: NaiveScanner = scanners.front()
		var finished: bool = scanner.update(start_time)
		if finished:
			scanners.pop_front()
		if scanners.is_empty():
			cancel_request(monster)
		
		var elapsed: int = Time.get_ticks_usec() - start_time
		if elapsed >= BUDGET_USEC:
			break
	
	# increment to the next monster for the next frame
	monster_index = wrapi(monster_index + 1, 0, monsters.size())
	
	if verbose:
		_frames_active += 1
		_budget_available += BUDGET_USEC
		_budget_used += Time.get_ticks_usec() - start_time


func is_move_requested(monster: SimMonster) -> bool:
	return scanners_by_monster.has(monster)


func request_move(monster: SimMonster) -> void:
	var scanners: Array[NaiveScanner] = [
		IslandOfOneScanner.new(),
		AdjacentClueScanner.new(),
	]
	
	var cells: Dictionary[Vector2i, int] = monster.game_board.get_cells()
	for scanner: NaiveScanner in scanners:
		scanner.monster = monster
		scanner.cells = cells
		scanner.cell_list = cells.keys()
	
	scanners_by_monster[monster] = scanners
	monsters.append(monster)


func cancel_request(monster: SimMonster) -> void:
	var monster_pos: int = monsters.find(monster)
	if monster_pos == -1:
		return
	
	if monster_index > monster_pos:
		# shift monster index back one
		monster_index -= 1
	elif monster_index == monster_pos and monster_index >= monsters.size() - 1:
		# reset monster index to the beginning
		monster_index = 0 if monsters.size() > 1 else -1
	
	scanners_by_monster.erase(monster)
	monsters.erase(monster)


func _on_verbose_timer_timeout() -> void:
	if _frames_active == 0:
		return
	
	print("budget: %s/%s frames: %s/%s" % [_budget_used, _budget_available, _frames_active, _frames_available])
	
	_budget_used = 0
	_budget_available = 0
	_frames_active = 0
	_frames_available = 0


static func find_instance(node: Node) -> NaiveSolver:
	return node.get_tree().get_first_node_in_group("naive_solvers")


class NaiveScanner:
	var monster: SimMonster
	var cells: Dictionary[Vector2i, int]
	var cell_list: Array[Vector2i]
	var next_cell_index: int = 0
	
	func update(_start_time: int) -> bool:
		return true
	
	
	func out_of_time(start_time: int) -> bool:
		return Time.get_ticks_usec() - start_time >= BUDGET_USEC
	
	
	func should_deduce(cell: Vector2i) -> bool:
		return cells.get(cell, CELL_INVALID) == CELL_EMPTY \
				and not monster.pending_deductions.has(cell)


class IslandOfOneScanner extends NaiveScanner:
	func update(start_time: int) -> bool:
		while next_cell_index < cell_list.size():
			if out_of_time(start_time):
				break
			_check_cell(cell_list[next_cell_index])
			next_cell_index += 1
		return next_cell_index >= cell_list.size()
	
	
	func _check_cell(cell: Vector2i) -> void:
		if cells[cell] != 1:
			return
		
		for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
			var neighbor: Vector2i = cell + neighbor_dir
			if not should_deduce(neighbor):
				continue
			monster.add_pending_deduction(neighbor, CELL_WALL, ISLAND_OF_ONE)


class AdjacentClueScanner extends NaiveScanner:
	func update(start_time: int) -> bool:
		while next_cell_index < cell_list.size():
			if out_of_time(start_time):
				break
			_check_cell(cell_list[next_cell_index])
			next_cell_index += 1
		return next_cell_index >= cell_list.size()
	
	
	func _check_cell(cell: Vector2i) -> void:
		if cells[cell] <= 0:
			return
		
		for other_dir: Vector2i in [
			Vector2i(-2,  0), Vector2i( 0, -2), Vector2i( 0,  2), Vector2i( 2,  0),
			Vector2i(-1, -1), Vector2i(-1,  1), Vector2i( 1, -1), Vector2i( 1,  1),
		]:
			var other_cell: Vector2i = cell + other_dir
			if cells.get(other_cell, CELL_INVALID) <= 0:
				continue
			for neighbor_dir: Vector2i in NEIGHBOR_DIRS:
				var neighbor: Vector2i = cell + neighbor_dir
				if neighbor.distance_to(other_cell) != 1.0:
					continue
				if not should_deduce(neighbor):
					continue
				monster.add_pending_deduction(neighbor, CELL_WALL, ADJACENT_CLUES)
