extends TestGenerator

func test_fix_tiny_split_wall() -> void:
	grid = [
		"## . . 3########## 5",
		"######## ?## 6 .## .",
		"## . 2## . .## .## .",
		"###### 1## .## .## .",
		" ?## 2#### .## .## .",
		" .## .## . .## .####",
		" .###### .###### ?##",
		" .## ?  ## ?## . .##",
		" .##    ## .########",
		"## ?## ?###### . . ?",
	]
	var expected: Array[String] = [
		"(0, 9)-> fix_tiny_split_wall (0, 9)",
		"(1, 8)-> fix_tiny_split_wall (0, 9)",
		"(1, 9)-> fix_tiny_split_wall (0, 9)",
		"(2, 9)-> fix_tiny_split_wall (0, 9)",
	]
	assert_placements(generator.fix_tiny_split_wall, expected)


func test_fix_unclued_island() -> void:
	grid = [
		"###### . 2## 2## 2 .",
		"## . 3###### .######",
		"## .## 5## 4## 6## 6",
		"###### .## .## .## .",
		" . 3## .## .## .## .",
		" .#### .## .## .## .",
		"## 4## .###### .## .",
		"## .#### 2 .## .## .",
		"## . .##############",
		"######## 3 . .## . .",
	]
	var expected: Array[String] = [
		"(9, 9)->2 fix_unclued_island",
	]
	assert_placements(generator.fix_all_unclued_islands, expected)
