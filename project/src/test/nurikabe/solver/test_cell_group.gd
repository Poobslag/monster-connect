extends GutTest

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY
const CELL_MYSTERY_CLUE: int = NurikabeUtils.CELL_MYSTERY_CLUE

func test_merge_clue_values_valid() -> void:
	assert_eq(3, CellGroup.merge_clue_values(3, 0))


func test_merge_clue_values_mystery() -> void:
	assert_eq(CELL_MYSTERY_CLUE, CellGroup.merge_clue_values(CELL_MYSTERY_CLUE, 0))


func test_merge_clue_values_empty() -> void:
	assert_eq(0, CellGroup.merge_clue_values(0, 0))


func test_merge_clue_values_conflict() -> void:
	assert_eq(-1, CellGroup.merge_clue_values(3, 5))


func test_merge_clue_values_conflict_mystery() -> void:
	assert_eq(-1, CellGroup.merge_clue_values(3, CELL_MYSTERY_CLUE))
