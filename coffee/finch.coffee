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
	constructor: ({name, nodeType, parent} = {}) ->
		# The name property is not used by code; it is included
		# for readability of the generated objects
		@name = name ? ""
		@nodeType = nodeType ? null
		@parent = parent ? null
		@routeSettings = null
		@childLiterals = {}
		@childVariable = null
		@bindings = []

class RouteSettings
	constructor: ({setup, load, teardown, context} = {}) ->
		@setup = if isFunction(setup) then setup else (->)
		@load = if isFunction(load) then load else (->)
		@teardown = if isFunction(teardown) then teardown else (->)
		@context = if isObject(context) then context else {}

class RoutePath
	constructor: ({node, boundValues} = {}) ->
		@node = node ? null
		@boundValues = boundValues ? []

	getBindings: ->
		bindings = {}
		for binding, index in @node.bindings
			bindings[binding] = @boundValues[index]
		return bindings

	isEqual: (routePath) -> routePath? and @node is routePath.node and arraysEqual(@boundValues, routePath.boundValues)

	isRoot: -> not @node.parent?

	getParent: ->
		return null unless @node?
		bindingCount = @node.parent?.bindings.length ? 0
		boundValues = @boundValues.slice(0, bindingCount)
		return new RoutePath(node: @node.parent, boundValues: boundValues)

	getChild: (targetRoutePath) ->
		# Find the immediate child of this route path towards the target route path
		targetNode = targetRoutePath?.node
		targetNode = targetNode.parent while targetNode? and targetNode.parent isnt @node

		# Return null if this route path node was not an ancestor of the target route path node
		return null unless targetNode?

		# Return null if this route path's bound values do not match the target route path's
		return null unless arraysEqual(@boundValues, targetNode.boundValues[0..@boundValues.length])

		boundvalues = @boundValues.slice(0)
		boundValues.push(targetNode.boundValues[@boundValues.length]) if targetNode.nodeType is NodeType.Variable
		return new RoutePath(node: targetNode, boundValues: boundValues)

###
# Globals
###

NullPath = new RoutePath(node: null)
routeTreeRoot = new RouteTreeNode(name: "*")
currentPath = NullPath
currentParameters = {}

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
	return "" unless startsWith(routeString, "[")

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
	return routeString unless startsWith(routeString, "[")

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
#		-> [""]
#	splitRouteString("/foo")
#		-> ["foo"]
#	splitRouteString("/foo/bar/")
#		-> ["foo", "bar"]
###
splitRouteString = (routeString) ->
	return [] if routeString is ""

	# Remove trailing and leading '/'
	routeString = trimSlashes(routeString)

	# Split the route string by '/'
	return routeString.split('/')

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
addRoute = (routeTreeRoot, routeString, settings) ->
	parentRouteComponents = splitRouteString( getParentRouteString( routeString ))
	childRouteComponents = splitRouteString( getChildRouteString( routeString ))
	parentNode = routeTreeRoot
	bindings = []

	(recur = (currentNode, name) ->
		component = null
		onParentNode = false
		nextNode = null

		# Are we done traversing the route string?
		if parentRouteComponents.length <= 0 and childRouteComponents.length <= 0
			currentNode.parent = parentNode
			currentNode.bindings = bindings
			return currentNode.routeSettings = new RouteSettings(settings)

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
				nextNode = currentNode.childLiterals[componentName] ?= new RouteTreeNode(name: name, nodeType: componentType, parent: routeTreeRoot)
			when NodeType.Variable
				nextNode = currentNode.childVariable ?= new RouteTreeNode(name: name, nodeType: componentType)
				# Push the variable name onto the end of the bindings list
				bindings.push(componentName)

		parentNode = nextNode if onParentNode
		recur(nextNode, name)
	)(routeTreeRoot, "")

# END addRoute

###
# Method: findRoutePath
#	Finds a route in the route tree, given a URI.
#
# Arguments:
#	uri - The uri to parse and match against the route tree.
#
# Returns:
#	RoutePath
#	node - The node that matches the URI
#	boundValues - An ordered list of values bound to each variable in the URI
###
findRoutePath = (uri) ->
	uriComponents = splitRouteString(uri)
	boundValues = []

	(recur = (currentNode) ->
		# Are we done traversing the uri?
		if uriComponents.length <= 0
			return new RoutePath( node: currentNode, boundValues: boundValues )

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
		return null
	)(routeTreeRoot)

# END findRoutePath

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
#	null if there is no common ancestor.
###
findNearestCommonAncestor = (routePath1, routePath2) ->
	# Enumerate all ancestors of routePath2 in order
	ancestors = []
	currentRoute = routePath2
	while currentRoute?
		ancestors.push currentRoute
		currentRoute = currentRoute.getParent()

	# Find the first ancestor of routePath1 that is also an ancestor of routePath2
	currentRoute = routePath1
	while currentRoute?
		for ancestor in ancestors
			return currentRoute if currentRoute.isEqual(ancestor)
		currentRoute = currentRoute.getParent()

	# No common ancestors. (Do these nodes belong to different trees?)
	return null

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
setupRoute = (ancestorPath, newPath) ->
	(recur = (currentPath, continuation) ->
		if currentPath.isEqual(ancestorPath)
			return continuation()

		else recur(currentPath.getParent(), ->
			return continuation() unless currentPath.node.routeSettings?

			bindings = currentPath.getBindings()
			{context, setup} = currentPath.node.routeSettings

			# If the setup takes two parameters, then it is an asynchronous call
			if setup.length is 2
				return setup.call(context, bindings, ->
					return continuation()
				)

			# Synchronous call
			else
				setup.call(context, bindings)
				return continuation()

		) #END else recur
	)(newPath, ->
		{setup, load} = newPath.node.routeSettings
		loadRoute(newPath) if setup isnt load
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
loadRoute = (routePath) ->
	{context, load} = routePath.node.routeSettings
	load.call(context, currentParameters)

# END loadRoute

###
# Method: teardownRoute
#	Recursively tears down the current route given an ancestor to tear down to.
#
# Arguments:
#	ancestor - The ancestor node to tear down to
###
teardownRoute = (ancestorPath) ->
	(recur = (currentPath) ->
		unless currentPath.isEqual(ancestorPath)

			return recur(currentPath.getParent()) unless currentPath.node.routeSettings?

			bindings = currentPath.getBindings()
			{context, teardown} = currentPath.node.routeSettings

			# If the setup takes two parameters, then it is an asynchronous call
			if teardown.length is 2
				teardown.call(context, bindings, ->
					return recur(currentPath.getParent())
				)

			# Synchronous call
			else
				teardown.call(context, bindings)
				return recur(currentPath.getParent())
	)(currentPath)

# END teardownRoute

###
# Class: Finch
###
Finch = {

	debug: true

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
		addRoute(routeTreeRoot, pattern, settings)

	#END Finch.route

	###
	# Method: Finch.call
	#
	# Arguments:
	#	route - The route to try and call
	###
	call: (uri) ->

		#Make sure we have valid arguments
		uri = "/" unless isString(uri)
		uri = "/" if uri is ""

		#Extract the route and query parameters from the uri
		[uri, queryString] = uri.split("?", 2)

		# Find matching route in route tree
		newPath = findRoutePath(uri)

		# Return false if there was no matching route
		return false unless newPath?

		queryParameters = parseQueryString(queryString)
		bindings = newPath.getBindings()
		currentParameters = extend(queryParameters, bindings)

		# If we are still using the same route, call load
		if newPath.isEqual(currentPath)
			loadRoute(currentPath)
		else
			# Find the nearest common ancestor of the current and new route nodes
			ancestorPath = findNearestCommonAncestor(currentPath, newPath)

			# Tear down old route up to the common ancestor
			teardownRoute(ancestorPath)

			# Build up new route from the common ancestor
			setupRoute(ancestorPath, newPath)

		currentPath = newPath

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
		teardownRoute(NullPath)

		# Reset the route tree
		routeTreeRoot = new RouteTreeNode(name: "*")
		currentPath = new RoutePath(node: null)
		currentParameters = {}
		return

	#END Finch.reset()
}

if Finch.debug
	Finch.private = {
		# utility
		isObject
		isFunction
		isArray
		isString
		isNumber
		trim
		trimSlashes
		startsWith
		endsWith
		contains
		extend
		objectsEqual
		arraysEqual

		# enums
		NodeType

		# classes
		RouteSettings
		RoutePath
		RouteTreeNode

		#functions
		parseQueryString
		getParentRouteString
		getChildRouteString
		splitRouteString
		getComponentType
		getComponentName
		addRoute
		findRoutePath
		findNearestCommonAncestor
		setupRoute
		loadRoute
		teardownRoute

		globals: -> return {
			routeTreeRoot
			currentPath
			currentParameters
		}
	}

#Expose Finch to the window
@Finch = Finch