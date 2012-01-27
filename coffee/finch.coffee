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

#------------------
# Classes
#------------------

class RouteNode
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
	constructor: ({setup, teardown, context} = {}) ->
		@setup = if isFunction(setup) then setup else (->)
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

	isEqual: (path) -> path? and @node is path.node and arraysEqual(@boundValues, path.boundValues)

	isRoot: -> not @node.parent?

	getParent: ->
		return null unless @node?
		bindingCount = @node.parent?.bindings.length ? 0
		boundValues = @boundValues.slice(0, bindingCount)
		return new RoutePath(node: @node.parent, boundValues: boundValues)

	getChild: (targetPath) ->
		while targetPath? and not @.isEqual(parent = targetPath.getParent())
			targetPath = parent
		return targetPath

#------------------
# Constants
#------------------

NullPath = new RoutePath(node: null)
NodeType = {
	Literal: 'Literal'
	Variable: 'Variable'
}

#------------------
# Globals
#------------------

rootNode = currentPath = currentParameters = currentTargetPath = null
do resetGlobals = ->
	rootNode = new RouteNode(name: "*")
	currentPath = NullPath
	currentParameters = {}
	currentTargetPath = null

#------------------
# Functions
#------------------

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
addRoute = (rootNode, routeString, settings) ->
	parentRouteComponents = splitRouteString( getParentRouteString( routeString ))
	childRouteComponents = splitRouteString( getChildRouteString( routeString ))
	parentNode = rootNode
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
				nextNode = currentNode.childLiterals[componentName] ?= new RouteNode(name: name, nodeType: componentType, parent: rootNode)
			when NodeType.Variable
				nextNode = currentNode.childVariable ?= new RouteNode(name: name, nodeType: componentType)
				# Push the variable name onto the end of the bindings list
				bindings.push(componentName)

		parentNode = nextNode if onParentNode
		recur(nextNode, name)
	)(rootNode, "")

# END addRoute

###
# Method: findPath
#	Finds a route in the route tree, given a URI.
#
# Arguments:
#	rootNode - The root node of the route tree.
#	uri - The uri to parse and match against the route tree.
#
# Returns:
#	RoutePath
#	node - The node that matches the URI
#	boundValues - An ordered list of values bound to each variable in the URI
###
findPath = (rootNode, uri) ->
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
	)(rootNode)

# END findPath

###
# Method: findNearestCommonAncestor
#	Finds the nearest common ancestor route node of two routes.
#
# Arguments:
#	path1, path2 - The two paths to compare.
#
# Returns:
#	RoutePath - The nearest common ancestor path of the two paths, or
#	null if there is no common ancestor.
###
findNearestCommonAncestor = (path1, path2) ->
	# Enumerate all ancestors of path2 in order
	ancestors = []
	currentRoute = path2
	while currentRoute?
		ancestors.push currentRoute
		currentRoute = currentRoute.getParent()

	# Find the first ancestor of path1 that is also an ancestor of path2
	currentRoute = path1
	while currentRoute?
		for ancestor in ancestors
			return currentRoute if currentRoute.isEqual(ancestor)
		currentRoute = currentRoute.getParent()

	# No common ancestors. (Do these nodes belong to different trees?)
	return null

# END findNearestCommonAncestor

###
# Method: step
###
step = ->
	if currentTargetPath.isEqual(currentPath)
		# Run observables
		console.log "RUN OBSERVABLES"

		# End the step process
		currentTargetPath = null

	else
		# Find the nearest common ancestor of the current and new path
		ancestorPath = findNearestCommonAncestor(currentPath, currentTargetPath)

		# If the current path is an ancestor of the new path, then setup towards the new path
		nextPath = context = stepFunction = bindings = null
		if currentPath.isEqual(ancestorPath)
			nextPath = currentPath.getChild(currentTargetPath)
			{context, setup:stepFunction} = nextPath.node.routeSettings ? {}
			bindings = nextPath.getBindings()

		# Otherwise, teardown towards the common ancestor
		else
			nextPath = currentPath.getParent()
			{context, teardown:stepFunction} = currentPath.node.routeSettings ? {}
			bindings = currentPath.getBindings()

		context ?= {}
		stepFunction ?= (->)
		recur = ->
			currentPath = nextPath
			step()

		# If the setup/teardown takes two parameters, then it is an asynchronous call
		if stepFunction.length is 2
			stepFunction.call(context, bindings, recur)

		# Otherwise it is a synchronous call
		else
			stepFunction.call(context, bindings)
			recur()
# END step

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
		settings = {setup: settings} if isFunction(settings)
		settings = {} unless isObject(settings)

		#Make sure we have valid inputs
		pattern = "" unless isString(pattern)

		# Add the new route to the route tree
		addRoute(rootNode, pattern, settings)

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
		newPath = findPath(rootNode, uri)

		# Return false if there was no matching route
		return false unless newPath?

		queryParameters = parseQueryString(queryString)
		bindings = newPath.getBindings()
		currentParameters = extend(queryParameters, bindings)

		previousTargetPath = currentTargetPath
		currentTargetPath = newPath

		# Start the process of teardowns/setups if we were not already doing so
		step() unless previousTargetPath?

		return true;

	#END Finch.call()

	###
	# Method: Finch.reset
	#   Tears down the current stack and resets the routes
	#
	# Arguments:
	#	none
	###
	reset: ->
		# Tear down the entire route
		currentTargetPath = NullPath
		step()
		resetGlobals()
		return

	#END Finch.reset()
}

# Add the listen and ignore methods
( ->
	interval = null
	listening = false
	hashChange = ( ->
		currentHash = null
		return (event) ->
			hash = ""
			if "hash" of window.location
				hash = window.location.hash
				hash = hash.slice(1) if  startsWith(hash, "#")
			else
				url = window.location.href
				urlSplit = url.split("#", 2)
				hash = (if urlSplit.length is 2 then urlSplit[1] else "")

			if hash isnt currentHash
				Finch.call(hash)
				currentHash = hash
	)()

	Finch.listen = () ->
		if not listening
			if "onhashchange" of window
				if isFunction(window.addEventListener)
					window.addEventListener("hashchange", hashChange, true)
					listening = true

				else if isFunction(window.attachEvent)
					window.attachEvent("hashchange", hashChange)
					listening = true
			
			console.log( "listening #{listening}" )
			if not listening
				interval = setInterval(hashChange, 33)
				listening = true

			hashChange()
		
		return listening

	#END Finch.listen

	Finch.ignore = () ->
		if listening

			if interval isnt null
				clearInterval(interval)
				interval = null
				listening = false

			if listening and "onhashchange" of window
				if isFunction(window.removeEventListener)
					window.removeEventListener("hashchange", hashChange, true)
					listening = false

				if listening and isFunction(window.detachEvent)
					window.detachEvent("hashchange", hashChange)
					listening = false
		
		return not listening
		
	#END Finch.ignore
)()

###
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

		# constants
		NullPath
		NodeType

		# classes
		RouteSettings
		RoutePath
		RouteNode

		#functions
		parseQueryString
		getParentRouteString
		getChildRouteString
		splitRouteString
		getComponentType
		getComponentName
		addRoute
		findPath
		findNearestCommonAncestor

		globals: -> return {
			rootNode
			currentPath
			currentParameters
		}
	}
###

#Expose Finch to the window
@Finch = Finch