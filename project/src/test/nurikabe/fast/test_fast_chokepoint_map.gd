extends GutTest

const CELL_EMPTY: String = NurikabeUtils.CELL_EMPTY
const CELL_INVALID: String = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: String = NurikabeUtils.CELL_ISLAND
const CELL_WALL: String = NurikabeUtils.CELL_WALL

var grid: Array[String] = []

func test_chokepoints_1() -> void:
	grid = [
		" . 5##",
		"  ####",
		"      ",
		"      ",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_chokepoints(chokepoint_map, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)])


func test_unchoked_cell_count_1() -> void:
	grid = [
		" . 5##",
		"  ####",
		"      ",
		"      ",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 0), Vector2(1, 0)), 1)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 0), Vector2(0, 1)), 7)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 2), Vector2(0, 0)), 3)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 2), Vector2(2, 2)), 5)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(1, 3), Vector2(2, 2)), 8)


func test_unchoked_cell_count_2() -> void:
	grid = [
		"  ####  ",
		"   4    ",
		"       6",
		"        ",
		" 1  ##  ",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(3, 3), Vector2(3, 2)), 15)


func test_chokepoints_donut() -> void:
	grid = [
		"   5 .",
		"  ##  ",
		"      ",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_chokepoints(chokepoint_map, [])


func test_chokepoints_2() -> void:
	grid = [
		"   5##",
		"      ",
		"##  ##",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_chokepoints(chokepoint_map, [Vector2i(1, 1)])


func test_chokepoints_3() -> void:
	grid = [
		"##  ##",
		"   5  ",
		"##  ##",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_chokepoints(chokepoint_map, [Vector2i(1, 1)])


func test_chokepoints_two_clues() -> void:
	grid = [
		"  ## 3",
		"  ##  ",
		" 3##  ",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_chokepoints(chokepoint_map, [Vector2i(0, 1), Vector2(2, 1)])


func test_unchoked_cell_count_two_clues() -> void:
	grid = [
		"  ## 3",
		"  ##  ",
		" 3##  ",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 0), Vector2(0, 1)), 2)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 0), Vector2(2, 0)), 3)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 1), Vector2(0, 0)), 1)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 1), Vector2(2, 0)), 3)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 2), Vector2(0, 1)), 2)
	assert_eq(chokepoint_map.get_unchoked_cell_count(Vector2(0, 2), Vector2(2, 0)), 3)


func test_component_cell_count_two_clues() -> void:
	grid = [
		"  ## 2",
		"  ##  ",
		" 2####",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_eq(chokepoint_map.get_component_cell_count(Vector2(0, 0)), 3)
	assert_eq(chokepoint_map.get_component_cell_count(Vector2(0, 1)), 3)
	assert_eq(chokepoint_map.get_component_cell_count(Vector2(0, 2)), 3)
	assert_eq(chokepoint_map.get_component_cell_count(Vector2(2, 0)), 2)
	assert_eq(chokepoint_map.get_component_cell_count(Vector2(2, 1)), 2)


func test_component_cells_two_clues() -> void:
	grid = [
		"  ## 2",
		"  ##  ",
		" 2####",
	]
	var chokepoint_map: FastChokepointMap = _build_island_chokepoint_map()
	assert_component_cells(chokepoint_map, Vector2(0, 0), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)])
	assert_component_cells(chokepoint_map, Vector2(2, 0), [Vector2i(2, 0), Vector2i(2, 1)])


func _build_island_chokepoint_map() -> FastChokepointMap:
	var board: FastBoard = FastTestUtils.init_board(grid)
	return FastChokepointMap.new(board, func(value: String) -> bool:
		return value.is_valid_int() or value in [CELL_EMPTY, CELL_ISLAND])


func assert_chokepoints(chokepoint_map: FastChokepointMap,
		expected_chokepoints: Array[Vector2i]) -> void:
	expected_chokepoints.sort()
	var actual_chokepoints: Array[Vector2i] = chokepoint_map.chokepoints_by_cell.keys()
	actual_chokepoints.sort()
	assert_eq(actual_chokepoints, expected_chokepoints)


func assert_component_cells(chokepoint_map: FastChokepointMap, cell: Vector2i,
		expected_cells: Array[Vector2i]) -> void:
	expected_cells.sort()
	var actual_cells: Array[Vector2i] = chokepoint_map.get_component_cells(cell)
	actual_cells.sort()
	assert_eq(actual_cells, expected_cells)
