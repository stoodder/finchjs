Finch = new class
	tree: null

	route: (route_string, callbacks) ->
		@tree ?= new Finch.Tree
		node = @tree.addRoute(route_string)
		node.setCallbacks(callbacks)
		return @
	#END route

	call: (route_string) ->
		@tree ?= new Finch.Tree
		@tree.callRoute(route_string)
		return @
	#END call

	reload: ->
		@tree ?= new Finch.Tree
		@tree.load_path.reload()
		return @
	#END reload

	peek: ->
		return ""
	#END peek

	# Has dispose method
	observe: (args...) ->
		observer = new Finch.Observer.create(args...)
		@tree ?= new Finch.Tree
		@tree.load_path.addObserver(observer)
		return observer
	#END observe

	abort: ->
		@tree ?= new Finch.Tree
		@tree.load_path.abort()
		return @
	#END abort

	listen: -> Finch.UriManager.listen()
	ignore: -> Finch.UriManager.ignore()

	navigate: (uri, params, do_update) ->
		Finch.UriManager.navigate(uri, params, do_update)
		return @
	#END navigate

	reset: ->
		@tree ?= new Finch.Tree
		@tree.load_path.abort()
		@tree = new Finch.Tree()
		return @
	#END reset

	options: (key, value) ->
		if isObject(key)
			@options(k, v) for k, v of key
			return @
		#END if

		switch key
			when 'coerce_types', 'CoerceParameterTypes'
				@tree ?= new Finch.Tree
				@tree.load_path.coerce_types = value
			#END when
		#END switch

		return @
	#END options

	# error, (status, message) ->
	# not_found, ->
	# load, (route)
	# unload, (route)
	# setup, (route)
	# teardown, (route)
	on: ->
	off: ->
	trigger: ->
#END Finch