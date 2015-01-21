class Finch.UriManager
	@is_listening = false

	@getHash = ->
		hash = window.location.hash
		hash = hash[1..] if hash.charAt(0) is '#'
		return hash
	#END getHash

	@setHash = (hash) ->
		hash = "" unless isString(hash)
		hash = trim(hash)
		hash = hash[1..] if hash.charAt(0) is '#'
		window.location.hash = hash
		return @
	#END setHash

	@parseQueryString = (query_string) ->
		return {} unless isString(query_string)

		params = {}
		for param in query_string.split("&")
			[key,value] = param.split("=", 2)
			params[key] = value
		#END for

		return params
	#END parseQueryString

	@extractRouteString = (route_string) ->
		return "" unless isString(route_string)
		return trim( route_string.split("?")[0] ? "" )
	#END extractRouteString

	@extractQueryParameters = (route_string) ->
		return @parseQueryString(route_string.split("?", 2)[1])
	#END extractQueryParameters

	@navigate = (uri, params, do_update) ->
		#Setup the input arguments properly
		[params, do_update, uri] = [uri, params, null] if isObject(uri)
		[do_update, params] = [params, null] if isBoolean(params)

		#Get the current state
		[current_uri, current_query_string] = @getHash().split("?", 2)
		current_params = @parseQueryString(current_query_string)

		#Make sure we have the correct types
		uri = current_uri unless isString(uri)
		params = {} unless isObject(params)
		do_update = false unless isBoolean(do_update)

		#Make sure the uri is formatted properly
		uri = trim(uri)
		uri = uri[1..] if uri.charAt(0) is "#"

		#Account for relative routes
		if startsWith(uri, "./") or startsWith(uri, "../")
			built_uri = current_uri

			while startsWith(uri, "./") or startsWith(uri, "../")
				slash_index = uri.indexOf("/")
				piece = uri.slice(0, slash_index)
				uri = uri.slice(slash_index+1)
				built_uri = built_uri.slice(0, built_uri.lastIndexOf("/")) if piece is ".."
			#END while

			uri = if uri.length > 0 then "#{built_uri}/#{uri}" else built_uri
		#END if

		#Extract any query string form the uri and soft-write it to the params object
		[uri, uri_query_string] = uri.split("?", 2)
		uri_params = @parseQueryString(uri_query_string)
		uri_params[key] = value for key, value of params
		params = uri_params

		#If we're trying to update, then also add the previous query params
		if do_update
			for key, value of current_params when not (key of params)
				params[key] = value
			#END for
		#END if

		#Remove any null values
		for key, value of params when not value?
			delete params[key]
		#END for

		#Update the uri
		uri += "?" + ("#{key}=#{value}" for key, value of params).join("&")
		@setHash(uri)

		return @
	#END navigate

	@listen_callback = null
	@listen_interval = null
	@listen = ->
		return true if @is_listening

		_current_hash = null
		@listen_callback = =>
			hash = @getHash()
			return if hash is _current_hash
			Finch.call(_current_hash = hash)
		#END listen_callback

		#Check if the window has an onhashcnage event
		if "onhashchange" of window
			if isFunction(window.addEventListener)
				window.addEventListener("hashchange", @listen_callback, true)
				@is_listening = true
			else if isFunction(window.attachEvent)
				window.attachEvent("hashchange", @listen_callback)
				@is_listening = true
			#END if
		#END if

		# if we're still not listening fallback to a set interval
		unless @is_listening
			@listen_interval = setInterval(@listen_callback, 33)
			@is_listening = true
		#END unless

		#Perform an initial hash change
		@listen_callback()

		return @is_listening
	#END listen

	@ignore = ->
		return true unless @is_listening

		# Are we using an interval?
		if @listen_interval isnt null
			clearInterval(@listen_interval)
			@listen_interval = null
			@is_listening = false

		#Otherwise if the window has onhashchange, try to remove the event listener
		else if "onhashchange" of window
			if isFunction(window.removeEventListener)
				window.removeEventListener("hashchange", @listen_callback, true)
				@is_listening = false
				@listen_callback = null
			else if isFunction(window.detachEvent)
				window.detachEvent("hashchange", @listen_callback)
				@is_listening = false
				@listen_callback = null
			#END if
		#END if

		return not @is_listening
	#END ignore
#END Finch.UriManager