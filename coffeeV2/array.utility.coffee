# -------------------------------------------------
# ARRAY FUNCTIONS
# -------------------------------------------------
arrayUnique = (arr) ->
	obj = {}
	obj[key] = true for key in arr
	return (key for key, value of obj)

arrayRemove = (arr, items) ->
	return [] unless isArray(arr)
	items = [items] unless isArray(items)
	for item in items
		arr = (_item for _item in arr when _item isnt item)
	return arr
#END arrayRemove