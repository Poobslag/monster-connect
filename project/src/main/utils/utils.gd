@tool
class_name Utils
## Contains global utilities.


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
