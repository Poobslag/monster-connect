extends Sprite2D

func update_cursor(game_board: NurikabeGameBoard, _player: Player, cell: Vector2i, tile_size: Vector2) -> void:
	position = (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size
	var cell_string: String = game_board.get_cell_string(cell)
	scale.y = 2.0 if cell_string == NurikabeUtils.WALL else 1.0
