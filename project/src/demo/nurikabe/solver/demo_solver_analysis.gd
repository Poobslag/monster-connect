extends Node

@export_global_file("*.log") var log_path: String

var raw_metrics: Dictionary[String, Dictionary] = {}

func _ready() -> void:
	parse()


func parse() -> void:
	var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
	while file.get_position() < file.get_length():
		var line: String = file.get_line()
		var line_split: PackedStringArray = line.split("|")
		for i in line_split.size():
			line_split[i] = line_split[i].strip_edges()
		if line_split.size() < 3:
			continue
		
		var technique_string: String = line_split[1]
		if technique_string.find("(") != -1:
			technique_string = StringUtils.substring_before(technique_string, "(")
		
		if not raw_metrics.has(technique_string):
			raw_metrics[technique_string] = {
				"duration": 0,
				"attempt_count": 0,
				"success_count": 0,
				"cells": 0,
			} as Dictionary[String, Variant]
		
		raw_metrics[technique_string]["duration"] += int(line_split[2])
		raw_metrics[technique_string]["attempt_count"] += 1
		raw_metrics[technique_string]["cells"] += int(line_split[3])
		if int(line_split[3]) > 0:
			raw_metrics[technique_string]["success_count"] += 1
	
	# convert raw_metrics to dict
	var solver_metrics: Dictionary[String, Variant] = {}
	for technique: String in raw_metrics:
		var raw_metric: Dictionary[String, Variant] = raw_metrics[technique]
		var success: float = float(raw_metric["success_count"]) / raw_metric["attempt_count"]
		var cost: float = float(raw_metric["duration"]) / maxi(1, raw_metric["attempt_count"])
		var impact: float = float(raw_metric["cells"]) / maxi(1, raw_metric["success_count"])
		
		solver_metrics[technique] = {
			"success": success,
			"cost": cost,
			"impact": impact,
		} as Dictionary[String, Variant]
	
	# normalize dict
	var max_solver_metric: Dictionary[String, Variant] = {}
	for technique: String in solver_metrics:
		var solver_metric: Dictionary[String, Variant] = solver_metrics[technique]
		max_solver_metric["success"] = max(max_solver_metric.get("success", 0), solver_metric["success"])
		max_solver_metric["cost"] = max(max_solver_metric.get("cost", 0), solver_metric["cost"])
		max_solver_metric["impact"] = max(max_solver_metric.get("impact", 0), solver_metric["impact"])
	
	for technique: String in solver_metrics:
		var solver_metric: Dictionary[String, Variant] = solver_metrics[technique]
		for metric_name: String in ["success", "cost", "impact"]:
			solver_metric[metric_name] = \
					clamp(float(solver_metric[metric_name]) / max_solver_metric[metric_name], 0.00001, 1.0)
			solver_metric[metric_name] = \
					snappedf(solver_metric[metric_name], 0.00001)
	
	%Output.clear()
	%Output.text = JSON.stringify(solver_metrics, "  ")
