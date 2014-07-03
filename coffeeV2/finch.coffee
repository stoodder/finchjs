@Finch = new class
	tree: null

	route: (route_string, callbacks) ->
		@tree ?= new Finch.Tree()
		node = @tree.addRoute(route_string)
		node.updateCallbacks(callbacks)
		return @
	#END route

	call: (route_string) ->
		return @ unless @tree instanceof Finch.Tree
		@tree.callRoute(route_string)
		return @
	#END call

	#Re-runs the current load method
	reload: ->
	#END reload

	peek: ->
	#END peek

	# Has dispose method
	observe: ->
	#END observe

	abort: ->
	#END abort

	listen: ->
	#END listen

	ignore: ->
	#END ignore

	navigate: ->
	#END navigate

	reset: ->
	#END reset

	# error, (status, message) ->
	# 404, ->
	# load, (route)
	# unload, (route)
	# setup, (route)
	# teardown, (route)
	on: ->
	off: ->
	trigger: ->
#END Finch