isObject = (object) -> (typeof object) is (typeof {}) and object isnt null
isFunction = (object) -> Object::toString.call( object ) is "[object Function]"
isBoolean = (object) -> Object::toString.call( object ) is "[object Boolean]"
isArray = (object) -> Object::toString.call( object ) is "[object Array]"
isString = (object) -> Object::toString.call( object ) is "[object String]"
isNumber = (object) -> Object::toString.call( object ) is "[object Number]"

trim = do ->
	if isFunction(String::trim)
		return (str) -> String::trim.apply(str, arguments)
	else
		return (str) -> str.replace(/^\s+/, '').replace(/\s+$/, '')
	#END if
#END trim
trimSlashes = (str) -> str.replace(/^\//, '').replace(/\/$/, '')
startsWith = (haystack, needle) -> haystack.indexOf(needle) is 0
endsWith = (haystack, needle) ->  haystack.indexOf(needle, haystack.length - needle.length) isnt -1

class RouteNode
	@LITERAL = "LITERAL"
	@VARIABLE = "VARIABLE"
	@SPLAT = "SPLAT" #TODO: Implement this

	@resolveNodeType = (name) ->
		name = trim( (name ? "").toString() )
		return RouteNode.VARIABLE if name[0] is ":"
		return RouteNode.LITERAL
	#END resolveNodeType

	name: ""
	node_type: ""

	#The previous node in the route chain
	parent_node: null

	#The previous node who's settings will be execute when entering/leaving this node
	parent_route_node: null

	literal_children: null
	variable_child: null
	splat_child: null

	setup: (->)
	load: (->)
	unload: (->)
	teardowm: (->)
	context: null

	constructor: (name, parent_node, settings) ->
		@name = name ? ""

		@literal_children = []
		@variable_child = null
		@parent_node = parent_node if parent_node instanceof RouteNode

		@updateSettings(settings) if settings?
		@node_type = RouteNode.resolveNodeType(@name)
	#END constructor

	updateSettings: ({node_type, setup, load, unload, teardown, context} = {}) ->
		@setup = setup if isFunction( setup )
		@load = load if isFunction( load )
		@unload = unload if isFunction( unload )
		@teardown = teardown if isFunction( teardown )
		@context = context ? @

		return @
	#END updateSettings

	trigger: (routine) ->
		return @ unless routine in ['setup','load','unload','teardown']
		routine = @[routine]
		return @
	#END execute

	findOrCreateNode: (route_pieces, settings) ->
		if route_pieces.length is 0
			@updateSettings(settings) if settings?
			return @
		#END if
		
		current_route_piece = route_pieces.shift()
		node_type = RouteNode.resolveNodeType( current_route_piece )

		switch node_type
			when RouteNode.LITERAL
				node = null
				for n in @literal_children when (node is null and n.name is current_route_piece)
					node = n
				#END for

				unless node? 
					node = new RouteNode(current_route_piece, @)
					@literal_children.push( node )
				#END unless
			#END when

			when RouteNode.VARIABLE
				node = @variable_child ?= new RouteNode(current_route_piece, @)
			#END when
		#END switch

		return node.findOrCreateNode(route_pieces, settings)
	#END findOrcreateNode

	traverse: ->
	#END traverse

	toString: ->
		if @parent_node
			return @parent_node.toString() + "/" + @name
		else
			return @name
		#END if
	#END toString
#END RouteNode

class RouteTree
	@_standardizeRouteString = (route_string) ->
		parent_route_string = null
		route_string = "" unless isString( route_string )
		route_string = trim( route_string )
		return {parent_route_string, route_string} if route_string is "!"
		
		route_string = trimSlashes( route_string )

		#Check if this route has a parent specified
		if route_string[0] is "["
			end_bracket_index = route_string.indexOf("]")
			
			parent_route_string = route_string.slice(1,end_bracket_index)
			route_string = route_string.slice(end_bracket_index+1)

			parent_route_string = trimSlashes( trim(parent_route_string) )
			route_string = trimSlashes( trim(route_string) )

			
			parent_route_string = "!/#{parent_route_string}" unless parent_route_string[0] is "!"
			route_string = "#{parent_route_string}/#{route_string}"
		else
			route_string = "!/#{route_string}" unless route_string[0] is "!"
		#END if

		route_string = trimSlashes( trim(route_string) ) + "/"

		return {parent_route_string, route_string}
	#END _standardizeRouteString

	@_splitRoute = (route_string) ->
		route_string = "" unless isString( route_string )
		route_string = trim( route_string )
		return [] if route_string.length <= 0
		return route_string.split("/")
	#END _splitRoute

	root_node: null
	current_node: null

	constructor: ->
		@root_node = new RouteNode("!")
	#END constructor

	addRoute: (route_string, settings) ->
		{parent_route_string, route_string} = RouteTree._standardizeRouteString( route_string )

		#Check if they're setting the root node, should be the only exception case
		if route_string is "!"
			@root_node.updateSettings(settings)
			return @root_node
		#END if

		parent_node = @root_node

		if parent_route_string?
			#Get the parent route pieces without the "!" node
			parent_route_pieces = RouteTree._splitRoute( parent_route_string ).slice(1)

			unless parent_route_pieces.length is 0
				parent_node = @root_node.findOrCreateNode( parent_route_pieces.slice(1) )
				parent_node.parent_route_node ?= @root_node
			#END unless
		#END if
		
		route_pieces = RouteTree._splitRoute( route_string ).slice(1)
		node = @root_node.findOrCreateNode( route_pieces )
		
		node.parent_route_node = parent_node

		return node
	#END addRoute
#END RouteTree


class @Finch
	@RouteNode = RouteNode
	@RouteTree = RouteTree

	route: (route, settings) ->
		return new RouteNode(route, settings)
	#END route
#END Finch