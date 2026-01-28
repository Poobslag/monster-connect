class_name NaiveScanner

const CELL_INVALID: int = NurikabeUtils.CELL_INVALID
const CELL_ISLAND: int = NurikabeUtils.CELL_ISLAND
const CELL_WALL: int = NurikabeUtils.CELL_WALL
const CELL_EMPTY: int = NurikabeUtils.CELL_EMPTY

var monster: SimMonster
var board: ScannerBoard

func update(_start_time: int) -> bool:
	return true


func out_of_time(start_time: int) -> bool:
	return Time.get_ticks_usec() - start_time >= NaiveSolver.BUDGET_USEC


func should_deduce(cell: Vector2i) -> bool:
	return board.cells.get(cell, CELL_INVALID) == CELL_EMPTY \
			and not monster.pending_deductions.has(cell)
