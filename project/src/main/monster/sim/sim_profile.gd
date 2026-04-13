class_name SimProfile

var version: String

var name: String
var author: String
var description: String
var skin: SimMonster.MonsterSkin = SimMonster.MonsterSkin.NONE
var behavior: SimBehavior = SimBehavior.new()
var archetypes: Dictionary[String, float] = {}

func apply_archetypes() -> void:
	var total_weight: float = 0
	for archetype: String in archetypes:
		total_weight += archetypes[archetype]
	if total_weight == 0:
		for stat: String in SimBehavior.STATS_BY_ARCHETYPE["neutral"]:
			if behavior.stats.has(stat):
				continue
			
			behavior.stats[stat] = SimBehavior.STATS_BY_ARCHETYPE["neutral"][stat]
	else:
		for stat: String in SimBehavior.STATS_BY_ARCHETYPE["neutral"]:
			if behavior.stats.has(stat):
				continue
			
			var new_stat_value: float = 0.0
			for archetype: String in archetypes:
				var weight: float = archetypes[archetype]
				new_stat_value += SimBehavior.STATS_BY_ARCHETYPE[archetype][stat] * (weight / float(total_weight))
			behavior.stats[stat] = new_stat_value
