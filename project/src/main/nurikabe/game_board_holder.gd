extends Node3D


func clear_game_boards() -> void:
	for game_board: NurikabeGameBoard3D in %GameBoards.get_game_boards():
		remove_game_board(game_board)


func remove_game_board(game_board: NurikabeGameBoard3D) -> void:
	game_board.queue_free()


func get_game_boards() -> Array[NurikabeGameBoard3D]:
	var result: Array[NurikabeGameBoard3D] = []
	result.assign(%GameBoards.get_children().filter(
		func(node: Node) -> bool:
			return node is NurikabeGameBoard3D and not node.is_queued_for_deletion()))
	return result
