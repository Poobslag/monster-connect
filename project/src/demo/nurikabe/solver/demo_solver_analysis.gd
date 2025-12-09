extends Node
## Shows a replacement `probe_metrics.json` populated from the specified log.[br]
## [br]
## This json file estimates the speed and impact of different probes, so that the solver can prioritize probes which
## are faster and more effective.[br]
## [br]
## I populate the `probe_metrics.json` file with the following process:
## 	1. Launch DemoSolver.
## 	2. Press [kbd]S[/kbd] then [kbd]Shift + W[/kbd] for a seeded random performance test.
## 	3. Press [kbd]Shift + S[/kbd] then [kbd]Shift + W[/kbd] for a second seeded random performance test.
## 	4. Launch DemoSolverAnalysis, copying the result into `probe_metrics.json`.

@export_global_file("*.log") var log_path: String

var raw_metrics: Dictionary[String, Dictionary] = {}
var spawned_probes_by_parent: Dictionary[String, Dictionary] = {}
var last_probe_key: String

func _ready() -> void:
	parse()


func parse() -> void:
	var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
	while file.get_position() < file.get_length():
		var line: String = file.get_line()
		if line.begins_with("|"):
			parse_table_line(line)
		elif line.begins_with("+"):
			parse_child_line(line)
		else:
			pass
	
	# convert raw_metrics to dict
	var solver_metrics: Dictionary[String, Variant] = {}
	for technique: String in raw_metrics:
		var raw_metric: Dictionary[String, Variant] = raw_metrics[technique]
		var cost: float = float(raw_metric["duration"]) / maxi(1, raw_metric["attempt_count"])
		var impact: float = float(raw_metric["cells"]) / maxi(1, raw_metric["attempt_count"])
		
		solver_metrics[technique] = {
			"cost": cost,
			"impact": impact,
			"spawn_cost": 0,
			"spawn_impact": 0,
		} as Dictionary[String, Variant]
	
	for technique: String in raw_metrics:
		if not spawned_probes_by_parent.has(technique):
			continue
		
		var raw_metric: Dictionary[String, Variant] = raw_metrics[technique]
		var total_spawn_cost: float = 0.0
		var total_spawn_impact: float = 0.0
		var probe_bag: Dictionary[String, int] = spawned_probes_by_parent.get(technique)
		for child_key: String in probe_bag:
			var spawn_count: int = probe_bag[child_key]
			total_spawn_cost += solver_metrics[child_key]["cost"] * spawn_count
			total_spawn_impact += solver_metrics[child_key]["impact"] * spawn_count
		solver_metrics[technique]["spawn_cost"] = total_spawn_cost / raw_metric["attempt_count"]
		solver_metrics[technique]["spawn_impact"] = total_spawn_impact / raw_metric["attempt_count"]
	
	# normalize dict
	var max_solver_metric: Dictionary[String, Variant] = {}
	for technique: String in solver_metrics:
		var solver_metric: Dictionary[String, Variant] = solver_metrics[technique]
		max_solver_metric["cost"] = max(max_solver_metric.get("cost", 0), \
				solver_metric["cost"], solver_metric["spawn_cost"])
		max_solver_metric["impact"] = max(max_solver_metric.get("impact", 0), \
				solver_metric["impact"], solver_metric["spawn_impact"])
	max_solver_metric["spawn_cost"] = max_solver_metric["cost"]
	max_solver_metric["spawn_impact"] = max_solver_metric["impact"]
	
	for technique: String in solver_metrics:
		var solver_metric: Dictionary[String, Variant] = solver_metrics[technique]
		for metric_name: String in ["cost", "impact", "spawn_cost", "spawn_impact"]:
			solver_metric[metric_name] = \
					clamp(float(solver_metric[metric_name]) / max_solver_metric[metric_name], 0.0, 1.0)
			solver_metric[metric_name] = \
					snappedf(solver_metric[metric_name], 0.00001)
		if solver_metric["cost"] == 0.0 and solver_metric["spawn_cost"] == 0.0:
			solver_metric["cost"] = 0.00001
		if solver_metric["impact"] == 0.0 and solver_metric["spawn_impact"] == 0.0:
			solver_metric["impact"] = 0.00001
	
	for technique: String in solver_metrics:
		var solver_metric: Dictionary[String, Variant] = solver_metrics[technique]
		for metric_name: String in ["cost", "impact", "spawn_cost", "spawn_impact"]:
			if solver_metric.has(metric_name) and solver_metric[metric_name] == 0.0:
				solver_metric.erase(metric_name)
	
	%Output.clear()
	%Output.text = JSON.stringify(solver_metrics, "  ")


func parse_table_line(line: String) -> void:
	var line_split: PackedStringArray = line.split("|")
	if line_split.size() < 3:
		return
	
	for i in line_split.size():
		line_split[i] = line_split[i].strip_edges()
	
	var probe_key: String = line_split[1]
	if probe_key.find("(") != -1:
		probe_key = StringUtils.substring_before(probe_key, "(")
	last_probe_key = probe_key
	
	if not raw_metrics.has(probe_key):
		raw_metrics[probe_key] = {
			"duration": 0,
			"attempt_count": 0,
			"cells": 0,
		} as Dictionary[String, Variant]
	
	raw_metrics[probe_key]["duration"] += int(line_split[3])
	raw_metrics[probe_key]["attempt_count"] += 1
	raw_metrics[probe_key]["cells"] += int(line_split[2])


func parse_child_line(line: String) -> void:
	if not last_probe_key:
		return
	var child_key: String = line.trim_prefix("+ ")
	if child_key.begins_with("add_bifurcation_scenario"):
		child_key = child_key.trim_prefix("add_bifurcation_scenario:[\"")
		child_key = StringUtils.substring_before(child_key, "\"")
	if child_key.contains(":"):
		child_key = StringUtils.substring_before(child_key, ":")
	if not spawned_probes_by_parent.has(last_probe_key):
		spawned_probes_by_parent[last_probe_key] = {} as Dictionary[String, int]
	var probe_bag: Dictionary[String, int] = spawned_probes_by_parent[last_probe_key]
	if not probe_bag.has(child_key):
		probe_bag[child_key] = 0
	probe_bag[child_key] += 1
