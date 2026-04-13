class_name PuzzleArchive
extends Node

enum Source {
	DEFAULT,
	GENERATED,
	JANKO,
	NIKOLI,
	POOBSLAG,
}

const DEFAULT: Source = Source.DEFAULT
const GENERATED: Source = Source.GENERATED
const JANKO: Source = Source.JANKO
const NIKOLI: Source = Source.NIKOLI
const POOBSLAG: Source = Source.POOBSLAG

const PATTERN_BY_SOURCE: Dictionary[Source, String] = {
	JANKO: "res://assets/demo/nurikabe/puzzles/janko/%s.janko",
	GENERATED: "res://assets/main/nurikabe/official/generated/%s.txt",
	NIKOLI: "res://assets/demo/nurikabe/puzzles/nikoli/%s.txt",
	POOBSLAG: "res://assets/demo/nurikabe/puzzles/poobslag/%s.txt",
	DEFAULT: "res://assets/demo/nurikabe/puzzles/%s.txt",
}

var _puzzle_paths: Array[String] = []

func _ready() -> void:
	_load_puzzle_paths()


func find(path: String) -> int:
	return _puzzle_paths.find(path)


func from_source(source: Source, basename: String) -> String:
	return PATTERN_BY_SOURCE[source] % [basename]


func puzzle_path_at(index: int) -> String:
	return _puzzle_paths[index]


func size() -> int:
	return _puzzle_paths.size()


func _load_puzzle_paths() -> void:
	for dir_path: String in [
			"res://assets/demo/nurikabe/puzzles/janko",
			"res://assets/demo/nurikabe/puzzles/nikoli",
			"res://assets/demo/nurikabe/puzzles/poobslag",
			]:
		for file: String in DirAccess.get_files_at(dir_path):
			_puzzle_paths.append(dir_path.path_join(file))
	_puzzle_paths.sort_custom(func(a: String, b: String) -> bool:
		if a.get_base_dir() != b.get_base_dir():
			return a.get_base_dir() < b.get_base_dir()
		return int(a.get_basename()) < int(b.get_basename())
	)
