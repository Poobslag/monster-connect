class_name TestMutationLibrary
extends GutTest
## Framework for testing the MutationLibrary.

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

var mutation_library: MutationLibrary = MutationLibrary.new()

func before_each() -> void:
	mutation_library.rng.seed = 0 # avoid randomness
