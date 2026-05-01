class_name FindPuzzleActionState
extends State
## Abstract state for FindPuzzleActions.

var action: FindPuzzleAction:
	get: return object

var monster: SimMonster:
	get: return action.monster
