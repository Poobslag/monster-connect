extends Node
## [b]Keys:[/b][br]
## 	[kbd][Escape][/kbd]: Erase all walls
## 	[kbd][Q,W,E,R,T,Y][/kbd]: Change wall count to 20/100/500/2000/10000/50000

func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_ESCAPE:
			refill_gridmap(0)
		KEY_Q:
			refill_gridmap(20)
		KEY_W:
			refill_gridmap(100)
		KEY_E:
			refill_gridmap(500)
		KEY_R:
			refill_gridmap(2000)
		KEY_T:
			refill_gridmap(10000)
		KEY_Y:
			refill_gridmap(50000)


func refill_gridmap(count: int) -> void:
	%GridMap.clear()
	
	var row_width: int = ceil(sqrt(count))
	for i in range(count):
		var x: int = i % row_width
		@warning_ignore("integer_division")
		var y: int = i / row_width
		%GridMap.set_cell_item(Vector3i(x, 0, y), 0)
