extends GutTest


func test_comma_sep_negative() -> void:
	assert_eq(StringUtils.comma_sep(-1), "-1")
	assert_eq(StringUtils.comma_sep(-999), "-999")
	assert_eq(StringUtils.comma_sep(-1000), "-1,000")
	assert_eq(StringUtils.comma_sep(-1002034), "-1,002,034")


func test_comma_sep_small() -> void:
	assert_eq(StringUtils.comma_sep(0), "0")
	assert_eq(StringUtils.comma_sep(1), "1")
	assert_eq(StringUtils.comma_sep(13), "13")
	assert_eq(StringUtils.comma_sep(133), "133")
	assert_eq(StringUtils.comma_sep(999), "999")


func test_comma_sep_big() -> void:
	assert_eq(StringUtils.comma_sep(1000), "1,000")
	assert_eq(StringUtils.comma_sep(1001), "1,001")
	assert_eq(StringUtils.comma_sep(999999), "999,999")
	assert_eq(StringUtils.comma_sep(1000000), "1,000,000")
	assert_eq(StringUtils.comma_sep(1001001), "1,001,001")
	assert_eq(StringUtils.comma_sep(999999999), "999,999,999")
	assert_eq(StringUtils.comma_sep(999999999999999999), "999,999,999,999,999,999")


func test_substring_after() -> void:
	assert_eq(StringUtils.substring_after("b", ""), "b")
	assert_eq(StringUtils.substring_after("", "b"), "")
	assert_eq(StringUtils.substring_after("abc", "a"), "bc")
	assert_eq(StringUtils.substring_after("abcba", "b"), "cba")
	assert_eq(StringUtils.substring_after("abc", "c"), "")
	assert_eq(StringUtils.substring_after("abc", "d"), "")


func test_substring_after_last() -> void:
	assert_eq(StringUtils.substring_after_last("b", ""), "b")
	assert_eq(StringUtils.substring_after_last("", "b"), "")
	assert_eq(StringUtils.substring_after_last("abc", "a"), "bc")
	assert_eq(StringUtils.substring_after_last("abcba", "b"), "a")
	assert_eq(StringUtils.substring_after_last("abc", "c"), "")
	assert_eq(StringUtils.substring_after_last("a", "a"), "")
	assert_eq(StringUtils.substring_after_last("a", "z"), "")


func test_substring_before() -> void:
	assert_eq(StringUtils.substring_before("b", ""), "b")
	assert_eq(StringUtils.substring_before("", "b"), "")
	assert_eq(StringUtils.substring_before("abc", "a"), "")
	assert_eq(StringUtils.substring_before("abcba", "b"), "a")
	assert_eq(StringUtils.substring_before("abc", "c"), "ab")
	assert_eq(StringUtils.substring_before("abc", "d"), "abc")


func test_substring_before_last() -> void:
	assert_eq(StringUtils.substring_before_last("b", ""), "b")
	assert_eq(StringUtils.substring_before_last("", "b"), "")
	assert_eq(StringUtils.substring_before_last("abcba", "b"), "abc")
	assert_eq(StringUtils.substring_before_last("abc", "c"), "ab")
	assert_eq(StringUtils.substring_before_last("a", "a"), "")
	assert_eq(StringUtils.substring_before_last("a", "z"), "a")
	assert_eq(StringUtils.substring_before_last("a", ""), "a")


func test_substring_between() -> void:
	assert_eq(StringUtils.substring_between("wx[b]yz", "[", "]"), "b")
	assert_eq(StringUtils.substring_between("", "[", "]"), "")
	assert_eq(StringUtils.substring_between("wx[b]yz", "", "]"), "")
	assert_eq(StringUtils.substring_between("wx[b]yz", "[", ""), "")
	assert_eq(StringUtils.substring_between("yabcz", "y", "z"), "abc")
	assert_eq(StringUtils.substring_between("yabczyabcz", "y", "z"), "abc")
