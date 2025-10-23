@tool
extends Node
## Globally accessible utilities.

## Game's main viewport size, as specified in the project settings.
var window_size: Vector2i = Vector2i(
	ProjectSettings.get_setting("display/window/size/viewport_width") as int,
	ProjectSettings.get_setting("display/window/size/viewport_height") as int)

## Stores all of the benchmarks which have been started
var _benchmark_start_times: Dictionary[String, int] = {}


## Sets the start time for a benchmark. Calling 'benchmark_start(foo)' and 'benchmark_finish(foo)' will display a
## message like 'foo took 123 milliseconds'.
func benchmark_start(key: String = "") -> void:
	_benchmark_start_times[key] = Time.get_ticks_usec()


## Prints the amount of time which has passed since a benchmark was started. Calling 'benchmark_start(foo)' and
## 'benchmark_finish(foo)' will display a message like 'foo took 123 milliseconds'.
func benchmark_end(key: String = "") -> void:
	if not _benchmark_start_times.has(key):
		print("Invalid benchmark: %s" % key)
		return
	print("Benchmark %s: %.3f msec" % [key, (Time.get_ticks_usec() - _benchmark_start_times[key]) / 1000.0])
