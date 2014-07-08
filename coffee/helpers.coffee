Helpers = new class
	#---------------------------------------------------
	# Method: Helpers.getHash
	#	Used to get the hash of a url in a standard way (that performs the same in all browsers)
	#
	# Returns:
	#	string - the string of the current hash, including the '#'
	#---------------------------------------------------
	getHash: -> "#" + ( window.location.href.split("#", 2)[1] ? "" )

	#---------------------------------------------------
	# Method: Helpers.setHash
	#	Used to set the current hash in a standard way
	#---------------------------------------------------
	setHash: (hash) ->
		hash = "" unless isString(hash)
		hash = trim(hash)
		hash = hash[1..] if hash[0..0] is '#'
		window.location.hash = hash
		return @
	#END setHash