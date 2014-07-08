# -------------------------------------------------
# STRING FUNCTIONS
# -------------------------------------------------
if String::trim
	trim = (str) -> String::trim.call(str)
else
	trim = (str) -> str.replace(/^\s+/, '').replace(/\s+$/, '')
#END if
trimSlashes = (str) -> str.replace(/^[\\/\s]+/, '').replace(/[\\/\s]+$/, '')
startsWith = (haystack, needle) -> haystack.indexOf(needle) is 0
endsWith = (haystack, needle) -> haystack.lastIndexOf(needle) is haystack.length-1
countSubstrings = (str, substr) -> str.split(substr).length - 1