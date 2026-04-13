class_name StrategyIterator

var _strategy_index: int = -1
var _strategies: Array[Callable]

func _init(init_strategies: Array[Callable]) -> void:
	_strategies = init_strategies


func size() -> int:
	return _strategies.size()


func next() -> Callable:
	_strategy_index = (_strategy_index + 1) % _strategies.size()
	return _strategies[_strategy_index]
