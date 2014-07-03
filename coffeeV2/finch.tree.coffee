class Finch.Tree
	root_node: null
	active_node: null
	active_operation_queue: null
	load_path: null

	constructor: ->
		@root_node = new Finch.Node("!")
		@load_path = new Finch.LoadPath()
	#END constructor

	parseRouteString: (route_string) ->
		unless isString(route_string)
			throw new Finch.Error("route_string must be a String")
		#END unless

		route_string = trim(route_string)
		parent_route_string = null

		open_bracket_index = route_string.indexOf("[")
		close_bracket_index = route_string.indexOf("]")
		has_parent = (open_bracket_index + close_bracket_index) isnt -2

		if has_parent
			# Check if they're looking for a parent route_string without
			# including the open bracket as the first character
			if open_bracket_index > 0
				throw new Finch.Error("Parsing failed on \"#{route_string}\": [ not at beginning")
			else if open_bracket_index is -1
				throw new Finch.Error("Parsing failed on \"#{route_string}\": Missing [")
			else if countSubstrings(route_string, "[") > 1
				throw new Finch.Error("Parsing failed on \"#{route_string}\": Too many [")
			#END if

			if open_bracket_index is -1
				throw new Finch.Error("Parsing failed on \"#{route_string}\": Missing ]")
			else if countSubstrings(route_string, "]") > 1
				throw new Finch.Error("Parsing failed on \"#{route_string}\": Too many ]")
			#END if

			parent_route_string = route_string.slice(open_bracket_index+1, close_bracket_index)
			route_string = route_string.replace(/[\[\]]+/gi, "")
		else
			parent_route_string = "!"
		#END if

		route_string = @extractRouteString(route_string)
		route_components = @splitRouteString(route_string)

		parent_route_string = @extractRouteString(parent_route_string)
		parent_route_components = @splitRouteString(parent_route_string)

		return new Finch.ParsedRouteString(route_components, parent_route_components)
	#END parseRouteString

	extractRouteString: (route_string) ->
		return "!" unless route_string?

		route_string = route_string.split("?")[0]
		route_string = trim( route_string.toString() )
		route_string = trimSlashes( route_string )
		route_string = "" if route_string.length is 0
		route_string = "!/#{route_string}" unless startsWith(route_string, "!")

		return route_string
	#END extractRouteString

	extractQueryParameters: (route_string) ->
		return {} unless isString(route_string)

		query_params_string = route_string.split("?", 2)[1]

		return {} unless isString(query_params_string)

		query_params = {}
		for piece in query_params_string.split("&")
			[key, value] = piece.split("=", 2)
			query_params[key] = value
		#END for

		return query_params
	#END extractQueryParameters

	splitRouteString: (route_string) ->
		return [] unless isString(route_string)

		pieces = route_string.split("/")
		pieces = (trim(piece) for piece in pieces)

		return pieces
	#END splitRouteString

	addRoute: (route_string) ->
		parsed_route_string = @parseRouteString(route_string)

		route_components = parsed_route_string.components
		parent_route_components = parsed_route_string.parent_components

		unless route_components[0] is "!"
			throw new Finch.Error("Routes must start with the root '!' node")
		#END unless

		unless parent_route_components[0] is "!"
			throw new Finch.Error("Parent routes must start with the root '!' node")
		#END unless

		current_node = @root_node
		parent_node = null
		current_index = 1

		#Find or add new routes, can probably search for parent node here
		while current_index < route_components.length
			route_component = route_components[current_index]
			parent_node = current_node if current_index is parent_route_components.length
			child_node = current_node.findChildNode(route_component)


			if child_node instanceof Finch.Node
				current_node = child_node
			else
				child_node = new Finch.Node(route_component)
				current_node.addChildNode(child_node)
				current_node = child_node
			#END if

			current_index++
		#END while

		current_node.setParentNode(parent_node)

		return current_node
	#END addRoute

	#TODO: Consider moving this directly in to the Finch class
	callRoute: (route_string) ->
		unless isString(route_string)
			throw new Finch.Error("route_string must be a String")
		#END unless

		params = @extractQueryParameters(route_string)
		route_string = @extractRouteString(route_string)
		route_components = @splitRouteString(route_string)

		target_load_path = @createLoadPath(route_components)
		@load_path.traverseTo(target_load_path)

		return @
	#END callRoute

	createLoadPath: (route_components) ->
		unless isArray(route_components)
			throw new Finch.Error("route_components must be an Array")
		#END unless

		unless route_components[0] is "!"
			throw new Finch.Error("Routes must start with the root '!' node")
		#END unless

		current_node = null
		nodes = []

		for route_component in route_components
			unless current_node instanceof Finch.Node
				current_node = @root_node
			else
				current_node = current_node.findMatchingChildNode(route_component)
			#END if

			unless current_node instanceof Finch.Node
				throw new Finch.NotFoundError("Could not resolve the route '#{route_components.join('/')}' at '#{route_component}'")
			#END unless

			nodes.push(current_node)
		#END while

		return new Finch.LoadPath(nodes, route_components)
	#END createLoadPath
#END Tree