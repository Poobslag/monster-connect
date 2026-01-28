class_name NaiveSolver
extends Node

const BUDGET_USEC: int = 4167 # 1/240 of a second

@export var verbose: bool = false

var monster_index: int = -1
var monsters: Array[SimMonster] = []
var scanners_by_monster: Dictionary[SimMonster, Array] = {}
var scanner_boards_by_monster: Dictionary[SimMonster, ScannerBoard] = {}

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
		
		var scanner_board: ScannerBoard = scanner_boards_by_monster.get(monster)
		if scanner_board == null:
			scanner_board = create_scanner_board(monster)
		
		if not scanner_board.is_prepared():
			scanner_board.prepare(start_time)
			if Time.get_ticks_usec() - start_time >= BUDGET_USEC:
				break
		
		var finished: bool = scanner.update(start_time)
		if finished:
			scanners.pop_front()
		if scanners.is_empty():
			cancel_request(monster)
		
		if Time.get_ticks_usec() - start_time >= BUDGET_USEC:
			break
	
	# increment to the next monster for the next frame
	monster_index = wrapi(monster_index + 1, 0, monsters.size())
	
	if verbose:
		_frames_active += 1
		_budget_available += BUDGET_USEC
		_budget_used += Time.get_ticks_usec() - start_time


func create_scanner_board(monster: SimMonster) -> ScannerBoard:
	var scanner_board: ScannerBoard = ScannerBoard.new(monster)
	scanner_boards_by_monster[monster] = scanner_board
	for next_scanner: NaiveScanner in scanners_by_monster[monster]:
		next_scanner.scanner_board = scanner_board
	return scanner_board


func is_move_requested(monster: SimMonster) -> bool:
	return scanners_by_monster.has(monster)


func request_move(monster: SimMonster) -> void:
	var scanners: Array[NaiveScanner] = [
		NaiveScanners.IslandMoatScanner.new(),
		NaiveScanners.AdjacentIslandScanner.new(),
	]
	
	for scanner: NaiveScanner in scanners:
		scanner.monster = monster
	
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
	scanner_boards_by_monster.erase(monster)
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
