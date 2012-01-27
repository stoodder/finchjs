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
peek = (arr) -> arr[arr.length - 1]

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

toArray = (obj) ->
	arr = []
	arr[arr.length] = value for key, value of obj ? {}
	return arr

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
	constructor: ({node, boundValues, parameterObservables} = {}) ->
		@node = node ? null
		@boundValues = boundValues ? []
		@parameterObservables = parameterObservables ? []

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
		parameterObservables = @parameterObservables.slice(0,-1)
		return new RoutePath(node: @node.parent, boundValues: boundValues, parameterObservables: parameterObservables)

	getChild: (targetPath) ->
		while targetPath? and not @.isEqual(parent = targetPath.getParent())
			targetPath = parent
		targetPath.parameterObservables = @parameterObservables.slice(0)
		targetPath.parameterObservables.push([])
		return targetPath

class ParameterObservable
	constructor: (callback) ->
		@callback = callback
		@callback = (->) unless isFunction(@callback)
		@dependencies = []
		@parameterAccessor = (key) =>
			@dependencies.push(key) unless contains(@dependencies, key)
			return CurrentParameters[key]

	resetDependencies: ->
		@dependencies = []

	trigger: ->
		@.resetDependencies()
		@callback(@parameterAccessor)

#------------------
# Constants
#------------------

NullPath = new RoutePath(node: null)
NodeType = {
	Literal: 'Literal'
	Variable: 'Variable'
}

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
# Globals
###
RootNode = CurrentPath = CurrentParameters = CurrentTargetPath = null
HashInterval = CurrentHash = null
HashListening = false
do resetGlobals = ->
	RootNode = new RouteNode(name: "*")
	CurrentPath = NullPath
	CurrentParameters = {}
	CurrentTargetPath = null

# END Globals

###
# Method: step
###
step = ->
	if CurrentTargetPath.isEqual(CurrentPath)

		# Run observables
		# TODO: Only trigger on change
		for observableList in CurrentPath.parameterObservables
			for observable in observableList
				observable.trigger()

		# End the step process
		CurrentTargetPath = null

	else
		# Find the nearest common ancestor of the current and new path
		ancestorPath = findNearestCommonAncestor(CurrentPath, CurrentTargetPath)

		# If the current path is an ancestor of the new path, then setup towards the new path;
		# otherwise, teardown towards the common ancestor
		if CurrentPath.isEqual(ancestorPath) then stepSetup() else stepTeardown()

# END step

stepSetup = ->
	# During setup and teardown, CurrentPath should always be the path to the
	# node getting setup or torn down.
	# In the setup case: CurrentPath must be set before the setup function is called.
	CurrentPath = CurrentPath.getChild(CurrentTargetPath)

	{context, setup} = CurrentPath.node.routeSettings ? {}
	context ?= {}
	setup ?= (->)
	bindings = CurrentPath.getBindings()
	recur = -> step()

	# If the setup/teardown takes two parameters, then it is an asynchronous call
	if setup.length is 2
		setup.call(context, bindings, recur)

	# Otherwise it is a synchronous call
	else
		setup.call(context, bindings)
		recur()

stepTeardown = ->
	{context, teardown} = CurrentPath.node.routeSettings ? {}
	context ?= {}
	teardown ?= (->)
	bindings = CurrentPath.getBindings()
	recur = ->
		# During setup and teardown, CurrentPath should always be the path to the
		# node getting setup or torn down.
		# In the setup case: CurrentPath must be set after the teardown function is called.
		CurrentPath = CurrentPath.getParent()
		step()

	# If the setup/teardown takes two parameters, then it is an asynchronous call
	if teardown.length is 2
		teardown.call(context, bindings, recur)

	# Otherwise it is a synchronous call
	else
		teardown.call(context, bindings)
		recur()


###
# Method: hashChange
#	Used to respond to hash changes
###
hashChange = (event) ->
	hash = ""
	if "hash" of window.location
		hash = window.location.hash
		hash = hash.slice(1) if  startsWith(hash, "#")
	else
		url = window.location.href
		urlSplit = url.split("#", 2)
		hash = (if urlSplit.length is 2 then urlSplit[1] else "")

	if hash isnt CurrentHash
		Finch.call(hash)
		CurrentHash = hash

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
		addRoute(RootNode, pattern, settings)

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
		newPath = findPath(RootNode, uri)

		# Return false if there was no matching route
		return false unless newPath?

		queryParameters = parseQueryString(queryString)
		bindings = newPath.getBindings()
		CurrentParameters = extend(queryParameters, bindings)

		previousTargetPath = CurrentTargetPath
		CurrentTargetPath = newPath

		# Start the process of teardowns/setups if we were not already doing so
		step() unless previousTargetPath?

		return true;

	#END Finch.call()

	###
	# Method: Finch.observe
	#	Used to set up observers on the query string.
	#
	# Form 1:
	# Arguments:
	#	keys... - A List of keys to listen to
	#	callback(keys...) - A callback function to execute with the values bound to each key in order.
	#
	# Form 2:
	# Arguments:
	#	keys[] - An array of param keys
	#	callback(keys...) - A callback function to execute with the values bound to each key in order.
	#
	# Form 3:
	# Arguments:
	#	callback(params) - A callback function to execute with a params accessor.
	###
	observe: (args...) ->
		# Handle argument form 1
		if args.length > 2
			callback = args.pop() 
			return Finch.observe( toArray(args), callback )
		
		#Handle form 2
		else if args.length is 2
			[keys, callback] = args
			keys = [keys] if isString(keys)
			keys = [] unless isArray(keys)
			callback = (->) unless isFunction(callback)

			return Finch.observe (params) ->
				values = (params(key) for key in keys)
				callback(values...)
		#Handle form 3
		else 
			callback = if isFunction(args[0]) then args[0] else (->)
			observable = new ParameterObservable(callback)
			peek(CurrentPath.parameterObservables).push(observable)


	#END Finch.observe()

	###
	# Method: Finch.listen
	#	Used to listen to changes in the window hash, will respond with Finch.call
	#
	# Returns:
	#	boolean - Is Finch listening?
	###
	listen: () ->
		#Only do this if we're currently not listening
		if not HashListening
			#Check if the window has an onhashcnage event
			if "onhashchange" of window
				if isFunction(window.addEventListener)
					window.addEventListener("hashchange", hashChange, true)
					HashListening = true

				else if isFunction(window.attachEvent)
					window.attachEvent("hashchange", hashChange)
					HashListening = true
			
			# if we're still nto listening fallback to a set interval
			if not HashListening
				HashInterval = setInterval(hashChange, 33)
				HashListening = true
			#Perform an initial hash change
			hashChange()

		return HashListening

	#END Finch.listen

	###
	# Method: Finch.ignore
	#	Used to stop listening to changes in the hash
	#
	# Returns:
	#	boolean - Is Finch done listening?
	###
	ignore: () ->
		#Only continue if we're listening
		if HashListening

			#Are we suing set interval? if so, clear it
			if HashInterval isnt null
				clearInterval(HashInterval)
				HashInterval = null
				HashListening = false

			#Otherwise if the window has onhashchange, try to remove the event listener
			else if "onhashchange" of window

				if isFunction(window.removeEventListener)
					window.removeEventListener("hashchange", hashChange, true)
					HashListening = false

				else if isFunction(window.detachEvent)
					window.detachEvent("hashchange", hashChange)
					HashListening = false

		return not HashListening

	#END Finch.ignore

	###
	# Method: Finch.reset
	#   Tears down the current stack and resets the routes
	#
	# Arguments:
	#	none
	###
	reset: ->
		# Tear down the entire route
		CurrentTargetPath = NullPath
		step()
		resetGlobals()
		return

	#END Finch.reset()
}

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
			RootNode
			CurrentPath
			CurrentParameters
		}
	}
###

#Expose Finch to the window
@Finch = Finch