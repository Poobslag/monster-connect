extends GutTest

var actor: GoapActorStub
var goap_agent: GoapAgent

func before_each() -> void:
	actor = GoapActorStub.new()
	actor.action_planner = GoapActionPlanner.new()
	actor.action_planner.set_actions([
		EatAction.new(),
		ForageAction.new(),
		PlayAction.new(),
	])
	var goals: Array[GoapGoal] = []
	goap_agent = GoapAgent.new(actor, goals)


func test_eat() -> void:
	actor.food = 4
	actor.hunger = 12
	actor.fun = 5
	
	goap_agent._process(0.1)
	assert_eq(["hmm"], actor.journal)


class GoapActorStub:
	var food: int
	var hunger: int
	var fun: int
	var journal: Array[String] = []
	
	var world_state: Dictionary[String, int]:
		get():
			world_state = {
				"food": food,
				"hunger": hunger,
				"fun": fun,
			}
			return world_state
	var action_planner: GoapActionPlanner

class EatAction extends GoapAction:
	func get_preconditions() -> Dictionary[String, GoapCondition]:
		return {
			"food": Goap.at_least(1),
			"hunger": Goap.at_least(1),
		}
	
	func get_effects() -> Dictionary[String, int]:
		return {
			"food": -1,
			"hunger": -2,
		}
	
	func perform(actor: Variant, _delta: float) -> bool:
		actor.food -= 1
		actor.hunger -= 2
		actor.journal.append("i ate")
		return true

class ForageAction extends GoapAction:
	func get_effects() -> Dictionary[String, int]:
		return {
			"food": 5,
		}
	
	func perform(actor: Variant, _delta: float) -> bool:
		actor.food += 5
		actor.journal.append("i foraged")
		return true

class PlayAction extends GoapAction:
	func get_preconditions() -> Dictionary[String, GoapCondition]:
		return {
			"hunger": Goap.at_most(10),
		}
	
	func get_effects() -> Dictionary[String, int]:
		return {
			"hunger": 1,
			"fun": 1,
		}
	
	func perform(actor: Variant, _delta: float) -> bool:
		actor.hunger += 1
		actor.fun += 1
		actor.journal.append("i played")
		return true
