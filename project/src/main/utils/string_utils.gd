class_name StringUtils
## Utility class for string operations.
##
## Where possible, these functions mimic the style of org.apache.commons.lang3.StringUtils.

## Formats a number with commas like '1,234,567'.
static func comma_sep(n: int) -> String:
	var result := ""
	var i: int = abs(n)
	
	while i > 999:
		result = ",%03d%s" % [i % 1000, result]
		i /= 1000
	
	return "%s%s%s" % ["-" if n < 0 else "", i, result]


## Gets the substring after the first occurrence of a separator.
static func substring_after(s: String, sep: String) -> String:
	if not sep:
		return s
	var pos: int = s.find(sep)
	return "" if pos == -1 else s.substr(pos + sep.length())


## Gets the substring after the last occurrence of a separator.
static func substring_after_last(s: String, sep: String) -> String:
	if not sep:
		return s
	var pos: int = s.rfind(sep)
	return "" if pos == -1 else s.substr(pos + sep.length())


## Gets the substring before the first occurrence of a separator.
static func substring_before(s: String, sep: String) -> String:
	if not sep:
		return s
	var pos: int = s.find(sep)
	return s if pos == -1 else s.substr(0, pos)


## Gets the substring before the last occurrence of a separator.
static func substring_before_last(s: String, sep: String) -> String:
	if not sep:
		return s
	var pos: int = s.rfind(sep)
	return s if pos == -1 else s.substr(0, pos)


## Gets the String that is nested in between two Strings. Only the first match is returned.
static func substring_between(s: String, open: String, close: String) -> String:
	if not s or not open or not close:
		return ""
	
	var result := ""
	var start: int = s.find(open)
	if start != -1:
		var end: int = s.find(close, start + open.length())
		if end != -1:
			result = s.substr(start + open.length(), end - start - open.length())
	return result
