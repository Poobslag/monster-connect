@tool
class_name Utils
## Contains global utilities.

const NUM_SCANCODES := {
	KEY_0: 0, KEY_1: 1, KEY_2: 2, KEY_3: 3, KEY_4: 4,
	KEY_5: 5, KEY_6: 6, KEY_7: 7, KEY_8: 8, KEY_9: 9,
}

## Recursively finds all files with the given extension starting at [param path].
static func find_files(path: String, file_extension: String) -> Array[String]:
	var found_files: Array[String] = []
	var dir_queue: Array[String] = [path]
	
	var dir: DirAccess = DirAccess.open("res://")
	var file: String
	
	while true:
		if file and file.begins_with("."):
			# ignore .gitkeep and other hidden files
			pass
		elif file:
			var resource_path: String = "%s/%s" % [dir.get_current_dir(), file.get_file()]
			if dir.current_is_dir():
				dir_queue.append(resource_path)
			elif file.ends_with(".%s.import" % [file_extension]):
				found_files.append(resource_path.trim_suffix(".import"))
		else:
			if dir:
				dir.list_dir_end()
			if dir_queue.is_empty():
				break
			# open the next directory from the queue
			dir = DirAccess.open(dir_queue.pop_front())
			dir.list_dir_begin()
		file = dir.get_next()
	
	return found_files


## Returns [0-9] for a number key event, or -1 if the event is not a number key event.
static func key_num(event: InputEvent) -> int:
	return NUM_SCANCODES.get(key_press(event), -1)


## Returns the [member InputEventKey.keycode] for a key press event, or -1 if the event is not a key press event.
static func key_press(event: InputEvent) -> int:
	var keycode := -1
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		keycode = event.keycode
	return keycode


## Invalidates a tween if it is already active.[br]
## [br]
## Killing a tween requires a null check, but this makes it a one-liner.
static func kill_tween(tween: Tween) -> Tween:
	if tween:
		tween.kill()
	return null


## Associates [param key] with [param value] if the key does not already exist.
static func put_if_absent(dict: Dictionary[Variant, Variant], key: Variant, value: Variant) -> void:
	dict[key] = dict.get(key, value)


## Creates/recreates a tween, invalidating it if it is already active.[br]
## [br]
## Tweens should be created and discarded, but tweening the same property with multiple tweens causes unpredictable
## behavior. This ensures only one tween modifies a given property at a time.[br]
## [br]
## The new tween is bound to [param node] and respects its lifecycle (e.g., pausing when the game is paused.)
static func recreate_tween(node: Node, tween: Tween) -> Tween:
	kill_tween(tween)
	return node.create_tween()


## Returns a new array containing the intersection of the given arrays.
static func intersection(a: Array[Variant], b: Array[Variant]) -> Array[Variant]:
	var result: Array[Variant] = []
	var bag: Dictionary[Variant, int] = {}
	for item: Variant in b:
		put_if_absent(bag, item, 0)
		bag[item] += 1
	for item: Variant in a:
		if bag.has(item):
			bag[item] -= 1
			if bag[item] == 0:
				bag.erase(item)
			result.append(item)
	return result


## Returns a new array containing [param a] - [param b].
static func subtract(a: Array[Variant], b: Array[Variant]) -> Array[Variant]:
	var result: Array[Variant] = []
	var bag: Dictionary[Variant, int] = {}
	for item: Variant in b:
		put_if_absent(bag, item, 0)
		bag[item] += 1
	for item: Variant in a:
		if bag.has(item):
			bag[item] -= 1
			if bag[item] == 0:
				bag.erase(item)
		else:
			result.append(item)
	return result
