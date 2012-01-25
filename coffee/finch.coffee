isObject = (object) -> ( typeof object is typeof {} );
isFunction = (object) -> Object::toString.call( object ) is "[object Function]"
isArray = (object) -> Object::toString.call( object ) is "[object Array]"
isString = (object) -> Object::toString.call( object ) is "[object String]"
isNumber = (object) -> Object::toString.call( object ) is "[object Number]"

trim = (str) -> str.replace(/^\s+/, '').replace(/\s+$/, '')
trimSlashes = (str) -> str.replace(/^\/+/, '').replace(/\/+$/, '')
startsWith = (haystack, needle) -> haystack.indexOf(needle) is 0
endsWith = (haystack, needle) ->  haystack.indexOf(needle, haystack.length - needle.length) isnt -1
contains = (haystack, needle) -> haystack.indexOf(needle) isnt -1

extend = (obj, extender) ->
	obj = {} unless isObject(obj)
	extender = {} unless isObject(extender)

	obj[key] = value for key, value of extender

	return obj

objectsEqual = (obj1, obj2) ->
	for key, value of obj1
		return false if obj2[key] isnt value
	for key, value of obj2
		return false if obj1[key] isnt value
	return true

arraysEqual = (arr1, arr2) ->
	return false if arr1.length isnt arr2.length
	for value, index in arr1
		return false if arr2[index] isnt value
	return true

NodeType = {
	Literal: 'Literal'
	Variable: 'Variable'
}

class RouteTreeNode
	constructor: ({name, nodeType}) ->
		# The name property is not used by code; it is included
		# for readability of the generated objects
		@name = name ? ""
		@nodeType = nodeType ? undefined
		@parentNode = undefined
		@route = undefined
		@childLiterals = {}
		@childVariable = undefined
		@bindings = []

class Route
	constructor: ({setup, load, teardown, context}) ->
		@setup = if isFunction(setup) then setup else (->)
		@load = if isFunction(load) then load else (->)
		@teardown = if isFunction(teardown) then teardown else (->)
		@context = if isObject(context) then context else {}

routeTreeRoot = new RouteTreeNode(name: "*")
currentRoute = {
	node: undefined
	boundValues: {}
	parameters: {}
}

###
# Method: parseQueryString
#	Used to parse and objectize a query string
#
# Arguments:
#	queryString - The query string to split up into an object
#
# Returns:
#	object - An object of the split apart query string
###
parseQueryString = (queryString) ->

	#Make sure the query string is valid
	queryString = if isString(queryString) then trim(queryString) else ""

	#setup the return parameters
	queryParameters = {}

	#iterate through the pieces of the query string
	if queryString != ""
		for piece in queryString.split("&")
			[key, value] = piece.split("=", 2)
			queryParameters[key] = value

	#return the result
	return queryParameters

#END parseQueryString


###
# Method: getParentRouteString
#	Gets the parent route sub-string of a route string
#
# Arguments:
#	routeString - The route string to parse
#
# Returns:
#	string - The parent route sub-string
###
getParentRouteString = (routeString) ->
	# Return empty string if there is no parent route
	return "" if not startsWith(routeString, "[")

	#Find the index of the closing bracket
	closingBracketIndex = routeString.indexOf("]")

	#Slice the string between the brackets
	return routeString[1..closingBracketIndex-1]

# END getParentRouteString


###
# Method: getChildRouteString
#	Gets the child route sub-string of a route string
#
# Arguments:
#	routeString - The route string to parse
#
# Returns:
#	string - The child route sub-string
###
getChildRouteString = (routeString) ->
	# Return entire string if there is no parent route
	return routeString if not startsWith(routeString, "[")

	#Find the index of the closing bracket
	closingBracketIndex = routeString.indexOf("]")

	#Slice the string after brackets
	return routeString[closingBracketIndex+1..]

# END getChildRouteString

###
# Method: splitRouteString
#	Splits a route string into its components.
#
# Arguments:
#	routeString - The route string to split up into an array
#
# Returns:
#	array - An array of the split apart route string
#
# Examples:
#	splitRouteString("")
#		-> []
#	splitRouteString("/")
#		-> []
#	splitRouteString("/foo")
#		-> ["foo"]
#	splitRouteString("/foo/bar/")
#		-> ["foo", "bar"]
###
splitRouteString = (routeString) ->
	# Remove trailing and leading '/'
	routeString = trimSlashes(routeString)

	# Split the route string by '/'
	return if routeString is "" then [] else routeString.split('/')

# END splitRouteString

getComponentType = (routeStringComponent) ->
	return NodeType.Variable if startsWith(routeStringComponent, ":")
	return NodeType.Literal

getComponentName = (routeStringComponent) ->
	switch getComponentType(routeStringComponent)
		when NodeType.Literal then routeStringComponent
		when NodeType.Variable then routeStringComponent[1..]

###
# Method: addRoute
#	Adds a new route node to the route tree, given a route string.
#
# Arguments:
#	routeString - The route string to parse and add to the route tree.
#	settings - The settings for the new route
#
# Returns:
#	Route - The added route
###
addRoute = (routeString, settings) ->
	parentRouteComponents = splitRouteString( getParentRouteString( routeString ))
	childRouteComponents = splitRouteString( getChildRouteString( routeString ))
	parentNode = undefined
	bindings = []

	(recur = (currentNode, name) ->
		component = undefined
		onParentNode = false
		nextNode = undefined

		# Are we done traversing the route string?
		if parentRouteComponents.length <= 0 and childRouteComponents.length <= 0
			currentNode.parentNode = parentNode
			currentNode.bindings = bindings
			return currentNode.route = new Route(settings)

		# Are we still parsing through the parent route?
		if parentRouteComponents.length > 0
			component = parentRouteComponents.shift()

			# If this was the last component on the parent node list, then the next node
			# is the parent node.
			onParentNode = true if parentRouteComponents.length is 0
		else
			component = childRouteComponents.shift()

		componentType = getComponentType(component)
		componentName = getComponentName(component)
		name = "#{name}/#{component}"

		switch componentType
			when NodeType.Literal
				nextNode = currentNode.childLiterals[componentName] ?= new RouteTreeNode(name: name, nodeType: componentType)
			when NodeType.Variable
				nextNode = currentNode.childVariable ?= new RouteTreeNode(name: name, nodeType: componentType)
				# Push the variable name onto the end of the bindings list
				bindings.push(componentName)

		parentNode = nextNode if onParentNode
		recur(nextNode, name)
	)(routeTreeRoot, "")

# END addRoute

###
# Method: findRoute
#	Finds a route in the route tree, given a URI.
#
# Arguments:
#	uri - The uri to parse and match against the route tree.
#
# Returns:
#	{ node, boundValues }
#	node - The node that matches the URI
#	boundValues - An ordered list of values bound to each variable in the URI
###
findRoute = (uri) ->
	uriComponents = splitRouteString(uri)
	boundValues = []

	(recur = (currentNode) ->
		# Are we done traversing the uri?
		if uriComponents.length <= 0
			return { node: currentNode, boundValues: boundValues }

		component = uriComponents.shift()

		# Try to find a matching literal component
		if currentNode.childLiterals[component]?
			result = recur(currentNode.childLiterals[component])
			return result if result?

		# Try to find a matching variable component
		if currentNode.childVariable?
			boundValues.push(component)
			result = recur(currentNode.childVariable)
			return result if result?
			boundValues.pop()

		# No matching route found in this traversal branch
		return undefined
	)(routeTreeRoot)

# END findRoute

###
# Method: findNearestCommonAncestor
#	Finds the nearest common ancestor route node of two routes.
#
# Arguments:
#	route1, route2 - Objects representing the two routes to compare.
#	-- node - The route node
#	-- boundValues - An ordered list of values bound to the route bindings
#
# Returns:
#	RouteTreeNode - The nearest common ancestor node of the two routes, or
#	undefined if there is no common ancestor.
###
findNearestCommonAncestor = (route1, route2) ->
	[node1, boundValues1] = [route1.node, route1.boundValues]
	[node2, boundValues2] = [route2.node, route2.boundValues]

	# Enumerate all ancestors of node1 in order
	ancestors = []
	currentNode = node1
	while currentNode?
		ancestors.push {node: currentNode, boundValues: boundValues1}
		if currentNode.nodeType is NodeType.Variable
			boundValues1 = boundValues1.slice(0, boundValues1.length-1)
		currentNode = currentNode.parentNode

	# Find the first ancestor of node2 that is also an ancestor of node1
	currentNode = node2
	while currentNode?
		for ancestor in ancestors
			return currentNode if ancestor.node is currentNode and arraysEqual(ancestor.boundValues, boundValues2)
		if currentNode.nodeType is NodeType.Variable
			boundValues2 = boundValues2.slice(0, boundValues2.length-1)
		currentNode = currentNode.parentNode

	# No common ancestors
	return undefined

# END findNearestCommonAncestor

###
# Method: setupRoute
#	Recursively sets up a new route given an ancestor from which to start the setup.
#
# Arguments:
#	ancestor - The ancestor node of the new route that represents the current state
#	newRouteNode - The route node to set up to
#	parameters - The parameters for the new route
###
setupRoute = (ancestor, newRouteNode, parameters) ->
	(recur = (currentNode, continuation) ->
		if currentNode is ancestor
			continuation(parameters)
		else recur(currentNode.parentNode, (parameters) ->
			{context, setup} = currentNode.route

			# If the setup takes two parameters, then it is an asynchronous call
			if setup.length is 2
				setup.call(context, parameters, (addedParameters) ->
					addedParameters = {} unless isObject(addedParameters)
					parameters = extend({}, parameters)
					extend(parameters, addedParameters)
					continuation(parameters)
				)
			# Synchronous call
			else
				setup.call(context, parameters)
				continuation(parameters)
		)
	)(newRouteNode, (parameters) ->
		{setup, load} = newRouteNode.route
		loadRoute(newRouteNode, parameters) if setup isnt load
	)

# END setupRoute

###
# Method: loadRoute
#	Loads a route with the given parameters.
#
# Arguments:
#	routeNode- The route node to load
#	parameters - The parameters for the route
###
loadRoute = (routeNode, parameters) ->
	{context, load} = routeNode.route
	load.call(context, parameters)

# END loadRoute

###
# Method: teardownRoute
#	Recursively tears down the current route given an ancestor to tear down to.
#
# Arguments:
#	ancestor - The ancestor node to tear down to
###
teardownRoute = (ancestor) ->
	(recur = (currentNode) ->
		if currentNode isnt ancestor
			context = currentNode.route.context
			currentNode.route.teardown.call(context)
			recur(currentNode.parentNode)
	)(currentRoute.node)

# END teardownRoute

###
# Class: Finch
###
Finch = {

	###
	# Mathod: Finch.route
	#	Used to setup a new route
	#
	# Arguments:
	#	pattern - The pattern to add
	#	callback - The callback to assign to the pattern
	###
	route: (pattern, settings) ->

		#Check if the input parameter was a function, assign it to the setup method
		#if it was
		settings = {setup: settings, load: settings} if isFunction(settings)
		settings = {} unless isObject(settings)

		#Make sure we have valid inputs
		pattern = "" unless isString(pattern)

		# Add the new route to the route tree
		addRoute(pattern, settings)

	#END Finch.route

	###
	# Method: Finch.call
	#
	# Arguments:
	#	route - The route to try and call
	#	parameters (optional) - The initial prameters to send
	###
	call: (uri, parameters) ->

		#Make sure we have valid arguments
		uri = "" unless isString(uri)
		parameters = {} unless isObject(parameters)

		#Extract the route and query parameters from the uri
		[uri, queryString] = uri.split("?", 2)
		queryParameters = parseQueryString(queryString)

		# Find matching route in route tree
		newRoute = findRoute(uri)

		# Return false if there was no matching route
		return false if not newRoute?

		#Extend the parameters with those found in the query string
		newRoute.parameters = extend(parameters, queryParameters)

		# Bind values against the bindings on the found node
		for binding, index in newRoute.node.bindings
			newRoute.parameters[binding] = newRoute.boundValues[index]

		# If we are still using the same route, call load if the query string parameters have changed
		if newRoute.node is currentRoute.node and arraysEqual(newRoute.boundValues, currentRoute.boundValues)
			loadRoute(newRoute.node, newRoute.parameters) if not objectsEqual(currentRoute.parameters, newRoute.parameters)
		else
			# Find the nearest common ancestor of the current and new route nodes
			ancestor = findNearestCommonAncestor(
				{node: currentRoute.node, boundValues: currentRoute.boundValues}
				newRoute
			)

			# Tear down old route up to the common ancestor
			teardownRoute(ancestor)

			# Build up new route from the common ancestor
			setupRoute(ancestor, newRoute.node, newRoute.parameters)

		currentRoute = newRoute

		return true;

	#END Finch.call()

	###
	# Method: Finch.reset
	#   Tears down the current stack and resets the routes
	#
	# Arguments:
	#	none
	###
	reset: () ->
		# Tear down the entire route
		teardownRoute(undefined)

		# Reset the route tree
		routeTreeRoot = new RouteTreeNode(name: "*")
		return

	#END Finch.reset()
}

#Expose Finch to the window
@Finch = Finch
