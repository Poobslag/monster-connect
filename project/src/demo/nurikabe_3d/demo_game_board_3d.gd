extends Node
## [b]Keys:[/b][br]
## 	[kbd][Q,W,E,R][/kbd]: Change puzzle count to 5/15/50/150.
## 	[kbd][A,S,D,F][/kbd]: Change puzzle size to 5x5/10x10/20x20/30x30.

const GAME_BOARD_SCENE: PackedScene = preload("res://src/main/nurikabe_3d/game_board_3d.tscn")

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var board_count: int = 5
var board_grid_size: Vector2i = Vector2i(2, 2)
var board_grid_tile_size: Vector2 = Vector2(100, 100)
var puzzle_size: Vector2i = Vector2i(5, 5)
var puzzle_tile_size: Vector2i = Vector2(1, 1)

func _ready() -> void:
	refresh_game_boards()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_Q:
			board_count = 5
			refresh_game_boards()
		KEY_W:
			board_count = 15
			refresh_game_boards()
		KEY_E:
			board_count = 50
			refresh_game_boards()
		KEY_R:
			board_count = 150
			refresh_game_boards()
		KEY_A:
			puzzle_size = Vector2i(5, 5)
			refresh_game_boards()
		KEY_S:
			puzzle_size = Vector2i(10, 10)
			refresh_game_boards()
		KEY_D:
			puzzle_size = Vector2i(20, 20)
			refresh_game_boards()
		KEY_F:
			puzzle_size = Vector2i(30, 30)
			refresh_game_boards()


func refresh_game_boards() -> void:
	# remove all children
	for child: Node in %GameBoards.get_children():
		child.queue_free()
	
	board_grid_tile_size = (puzzle_size + Vector2i(4, 4)) * puzzle_tile_size
	board_grid_size = Vector2i(ceil(sqrt(board_count)), ceil(sqrt(board_count)))
	
	# add new children
	for i in range(board_count):
		@warning_ignore("integer_division")
		var board_grid_cell: Vector2i = Vector2i(
				i % board_grid_size.x,
				floor(i / board_grid_size.x))
		add_board(board_grid_cell)
	
	# move the camera
	%Camera3D.position = Vector3(0, 9, 4) * board_grid_size.x


func add_board(board_grid_cell: Vector2i) -> void:
	var board: NurikabeGameBoard3D = GAME_BOARD_SCENE.instantiate()
	%GameBoards.add_child(board)
	
	var cells: Dictionary[Vector2i, int] = {}
	for x in puzzle_size.x:
		for y in puzzle_size.y:
			var cell: Vector2i = Vector2i(x, y)
			var cell_value: int
			if randf() < 0.3:
				cell_value = CELL_EMPTY
			elif randf() < 0.6:
				cell_value = CELL_WALL
			elif randf() < 0.6:
				cell_value = CELL_ISLAND
			elif randf() < 0.6:
				cell_value = randi_range(1, 6)
			else:
				cell_value = randi_range(1, 20)
			cells[cell] = cell_value
	
	board.grid_string = NurikabeUtils.grid_string_from_cells(cells)
	board.import_grid()
	board.position = Vector3(
		(board_grid_cell.x - board_grid_size.x * 0.5) * board_grid_tile_size.x,
		0,
		(board_grid_cell.y - board_grid_size.y * 0.5) * board_grid_tile_size.y,
	)
