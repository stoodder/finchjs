isObject = (object) -> ( typeof object is typeof {} );
isFunction = (object) -> Object::toString.call( object ) is "[object Function]"
isArray = (object) -> Object::toString.call( object ) is "[object Array]"
isString = (object) -> Object::toString.call( object ) is "[object String]"
isNumber = (object) -> Object::toString.call( object ) is "[object Number]"

trim = (str) -> str.replace(/^\s+/, '').replace(/\s+$/, '')
trimSlashes = (str) -> str.replace(/^\/+/, '').replace(/\/+$/, '')
startsWith = (haystack, needle) -> haystack.indexOf(needle) is 0
endsWith = (haystack, needle) ->  haystack.indexOf(needle, haystack.length - needle.length) isnt -1

extend = (obj, extender) ->
	obj = {} unless isObject(obj)
	extender = {} unless isObject(extender)

	obj[key] = value for key, value of extender

	return obj

##################################################
#
# Declare some private, state variables for Finch
#
##################################################
assignedPatterns = {}
currentRouteStack = []
currentCallStack = []

currentCall = null

###
# Method used to standardize a route so we can better parse through it
###
standardizeRoute = (route) ->

	#Get a valid rotue
	route = if isString(route) then trim(route) else ""

	#Check for a leading bracket
	if startsWith(route, "[")

		#Find the index of the closing bracket
		closingBracketIndex = route.indexOf("]")

		# if the closing bracket is in a spot where it would have other chacters (a parent route)
		# remove the bracket and pin the two route pieces together
		if closingBracketIndex > 1
			route = route.slice(1, closingBracketIndex) + route.slice(closingBracketIndex+1)

		#Otherwise just strip of anything before (including) the closing bracket
		else
			route = route.slice( Math.max(1, closingBracketIndex+1) )

	#Remove any leading or trailing '/'
	route = trimSlashes(route)

	return route

###
# Method: getParentPattern
# 	Used to extract the parent pattern out of a given pattern
#	- A parent pattern is specified within brackets, ex: [/home]/news
#		'/home' would be the parent pattern
#	- Useful for identifying and calling the parent pattern's callback
#
# Arguments:
#	pattern - The pattern to dig into and find a parent pattern, if one exisst
#
# Returns
#	string - The idenfitfied parent pattern
###
getParentPattern = (pattern) ->
	#Initialzie the parameters
	pattern = if isString(pattern) then trim(pattern) else ""
	parentPattern = null

	#Check if we're starting with a bracket if startsWith(pattern, "[")
	if startsWith(pattern, "[")

		#find the closing bracket
		closingBracketIndex = pattern.indexOf("]")

		#If we found one with a route inside, get the parentPattern
		if closingBracketIndex > 1
			parentPattern = pattern.slice(1, closingBracketIndex)

	return parentPattern

#END getParentPattern

###
# Method: getParameters
# 	Used to extract the parameters out of a route (from within the route's path, not query string)
#
# Arguments:
#	pattern - The pattern to use as a reference for finding parameters
#	route - The given route to extract parameters from
#
# Returns:
#	object - An object of the route's parameters
#
# See Also:
#	parseQueryString
###
getParameters = (pattern, route) ->
	route = "" unless isString(route)
	pattern = "" unless isString(pattern)

	route = standardizeRoute(route)
	pattern = standardizeRoute(pattern)

	routeSplit = route.split("/")
	patternSplit = pattern.split("/")

	return {} if routeSplit.length isnt patternSplit.length

	parameters = {}

	for index, patternPiece of patternSplit
		if startsWith(patternPiece, ":")
			parameters[patternPiece.slice(1)] = routeSplit[index]

	return parameters

#END getParameters

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

	#setup the return params
	queryParams = {}

	#iterate through the pieces of the query string
	if queryString != ""
		for piece in queryString.split("&")
			[key, value] = piece.split("=", 2)
			queryParams[key] = value

	#return the result
	return queryParams

#END parseQueryString

###
# Method: matchPattern
#	Method used to determine if a route matches a pattern
#
# Arguments:
#	route - The route to check
#	pattern - The pattern to compare the route against
#
# Returns:
#	boolean - Did the route match the pattern?
###
matchPattern = (route, pattern) ->
	route = standardizeRoute(route)
	pattern = standardizeRoute(pattern)

	routeSplit = route.split("/")
	patternSplit = pattern.split("/")

	#if the lengths aren't the same, this isn't valid
	return false if routeSplit.length isnt patternSplit.length

	for index, patternPiece of patternSplit
		return false unless patternPiece is routeSplit[index] or startsWith(patternPiece, ":")

	return true

#END matchPattern

###
# Method: buildCallStack
#	Used to build up a callstack for a given patterrn
#
# Arguments:
#	pattern - The route pattern to try and call
###
buildCallStack = (pattern) ->

	pattern = standardizeRoute(pattern)
	callStack = []

	#Next build the callstack
	(stackAdd = (pattern) ->
		assignedPattern = assignedPatterns[pattern]

		if isObject(assignedPattern)
			callStack.unshift(assignedPattern) if isFunction(assignedPattern.setup)
			stackAdd(assignedPattern.parentPattern) if assignedPattern.parentPattern? and assignedPattern.parentPattern isnt ""
	)(pattern)

	return callStack
#END buildCallStack



###
# Method: runSetupCallStack
#	Used to execute a callstack from a route starting at it's top most parent
#
# Arguments:
#	callStack - The stack to iterate through (calls each item's setup method)
#	routeStack - The route stack that is similar to the call stack
#	staffDiffIndex - The point where the stack should start calling from
#	parameters - The parameters to extend onto the list of parameters to send onward
#	callback - The callback method to run when the stack is complete
###
runSetupCallStack = (callStack, routeStack, stackDiffIndex, parameters, callback) ->
	#First setup the variables
	callStack = [] unless isArray(callStack)
	routeStack = [] unless isArray(routeStack)
	stackDiffIndex = if isNumber(stackDiffIndex) and stackDiffIndex > 0 then parseInt(stackDiffIndex) else 0
	parameters = {} unless isObject(parameters)
	callback = (->) unless isFunction(callback)

	#Setup the current call object, this is a bit messy,
	#but is used for aborting calls and keeping everything in sync
	currentCall = {
		aborted: false
		abortedCallback: (->)
		abort: (cb) ->
			cb = (->) unless isFunction(cb)
			this.aborted = true
			this.abortedCallback = () ->
				currentCall = null
				cb()
		#END abort()
	}

	#Slice the stack to only call after the given stackDiffIndex
	callStack = callStack.slice(stackDiffIndex)
	routeStack = routeStack.slice(stackDiffIndex)

	#Lastly execute the callstack, taking into account methods that request for the child callback
	(callSetup = (callStack, routeStack, parameters) ->
		return currentCall.abortedCallback() if currentCall.aborted
		if callStack.length <= 0
			currentCall = null
			return callback(parameters, (->))

		#Get the next pieces off the stacks
		callItem = callStack.shift()
		routeItem = routeStack.shift()

		#validate the items
		callItem = {} unless isObject(callItem)
		routeItem = "" unless isString(routeItem)

		#Make sure we have a setup method
		callItem.setup = (->) unless isFunction(callItem.setup)

		#Clear the callback if it's part of the stack
		callback = (->) if callback is callItem.setup

		#If the length is 2, then this is an asynchronous call
		if callItem.setup.length is 2

			#Call the method asynchronously
			callItem.setup( parameters, (p) ->

				#push the internal stacks
				currentCallStack.push(callItem)
				currentRouteStack.push(routeItem)

				#Extend the parameters if they gave us any aditional
				p = {} unless isObject(p)
				extend(parameters, p)

				#Call the next method in the chain
				callSetup.call( callSetup, callStack, routeStack, parameters )
			)

		#Synchronous call
		else
			#Execute this item's setup method
			callItem.setup(parameters)

			#push the internal stacks
			currentCallStack.push(callItem)
			currentRouteStack.push(routeItem)

			#recurse to the next call
			callSetup(callStack, routeStack, parameters)

	)(callStack, routeStack, parameters)

	#Reutrn nothing
	return
#END runSetupCallStack



###
# Method: runTeardownCallStack
###
# TODO: we really do not need the first and second arguments
runTeardownCallStack = (callStack, routeStack, stackDiffIndex) ->
	#First setup the variables
	callStack = [] unless isArray(callStack)
	routeStack = [] unless isArray(routeStack)
	stackDiffIndex = if isNumber(stackDiffIndex) and stackDiffIndex > 0 then parseInt(stackDiffIndex) else 0

	#Don't execute anything if the diff index is larger than any index in the callStack
	return if callStack.length <= stackDiffIndex

	#Use a recursive loop (for now) to iterate over the teardown methods
	#in reverse order
	(callTeardown = (callStack, routeStack) ->
		return if callStack.length <= stackDiffIndex

		#Get the last most piece off the stacks
		callItem = callStack.pop()
		routeItem = routeStack.pop()

		#Make sure they're valid
		callItem = {} unless isObject(callItem)
		routeItem = "" unless isString(routeItem)

		#get the associated tear down method
		callItem.teardown = (->) unless isFunction(callItem.teardown)

		#Call the teardown method
		callItem.teardown()

		#execute the next step
		callTeardown(callStack, routeStack)

	)(callStack, routeStack)

	#Reutrn nothing
	return

#END runSetupCallStack



###
# Method: findStackDiffIndex
#	Used to find the index between two stacks where they first differentiate
#
# Arguments:
#	oldRouteStack - The old route stack to compate against
#	newRouteStack - The new route stack to compare with
#
# Returns:
#	int - The first index where the two stacks aren't equal
###
findStackDiffIndex = (oldRouteStack, newRouteStack) ->
	#Make sure we have valid parameters
	oldRouteStack = [] unless isArray(oldRouteStack)
	newRouteStack = [] unless isArray(newRouteStack)
	stackIndex = 0

	#Iterate over each of the stacks while in their rnages and check the values
	while oldRouteStack.length > stackIndex and newRouteStack.length > stackIndex

		#Stop looping if we found our first different value
		break if oldRouteStack[stackIndex] isnt newRouteStack[stackIndex]

		#increment the index
		stackIndex++
	#END while

	#Return the differentiation point
	return stackIndex
#END findStackDiffIndex



###
# Method: buildRouteStack
#	Used to build a stack of routes that will
#	be called with the given route (full routes, not patterns)
#
# Arguments:
#	pattern - The pattern to reference
#	route - The route to extrpolate from
###
buildRouteStack = (pattern, route) ->
	#Setup the parameters
	pattern = standardizeRoute(pattern)
	route = standardizeRoute(route)
	routeSplit = route.split("/")
	routeStack = []

	#return the blank stack if no route was given
	return routeStack if routeSplit.length <= 0

	#Recursive callback to build up the route stack
	(buildRoute = (pattern) ->

		#split up the pattern
		patternSplit = pattern.split("/")
		builtRoute = ""
		matches = true
		splitIndex = 0

		#Iterate over the pieces to build the extrpolated route
		while matches and patternSplit.length > splitIndex and routeSplit.length > splitIndex

			#Get the two pieces
			patternPiece = patternSplit[splitIndex]
			routePiece = routeSplit[splitIndex]

			#Should we add the route to the extrpolated route
			if startsWith(patternPiece, ":") or patternPiece is routePiece
				builtRoute += "#{routePiece}/"
			else
				matches = false

			#Increment the counter
			splitIndex++
		#END while

		#Remove the last '/'
		builtRoute = builtRoute.slice(0,-1) if endsWith(builtRoute, "/")

		#Get the assigned pattern
		assignedPattern = assignedPatterns[pattern]

		#call to extrpolate the parent route, if we extrpolated something in he child route
		if builtRoute isnt ""
			routeStack.unshift(builtRoute)
			buildRoute(assignedPattern.parentPattern, route) if assignedPattern?.parentPattern? and assignedPattern.parentPattern isnt ""

	)(pattern)

	return routeStack
#END buildRouteStack



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

		#Make sure we have valid inputs
		pattern = "" unless isString(pattern)
		settings = {} unless isObject(settings)
		settings.context = {} unless isObject(settings.context)
		settings.setup = (->) unless isFunction(settings.setup)
		settings.load = (->) unless isFunction(settings.load)
		settings.teardown = (->) unless isFunction(settings.teardown)

		#initialize the parent route to call
		parentPattern = getParentPattern(pattern)

		#Standardize the rotues
		settings.pattern = standardizeRoute(pattern)
		settings.parentPattern = standardizeRoute(parentPattern)

		#Store the action for later
		assignedPatterns[settings.pattern] = settings

		#END assignedPatterns[route]

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

		#Extract the route and query string from the uri
		[route, queryString] = uri.split("?", 2)
		route = standardizeRoute(route)
		queryParams = parseQueryString(queryString)

		#Extend the parameters with those found in the query string
		extend(parameters, queryParams)

		# Iterate over each of the assigned routes and try to find a match
		for pattern, config of assignedPatterns

			#Check if this route matches the input routpatterne
			if matchPattern(route, pattern)

				#Abort the current call if one exists
				return currentCall.abort( -> Finch.call(uri, parameters) ) if currentCall?

				#Get the parameters of the route
				extend(parameters, getParameters(pattern, route))

				#Get the assigned pattern
				assignedPattern = assignedPatterns[pattern]
				loadMethod = if isFunction(assignedPattern.load) then assignedPattern.load else (->)

				#Create the necessary callstacks
				callStack = buildCallStack(pattern)
				routeStack = buildRouteStack(pattern, route)

				#Get the differentiating index between the previous route stack
				#and the new route stack
				stackDiffIndex = findStackDiffIndex(currentRouteStack, routeStack)

				#Execute the teardown callstack from the given index
				runTeardownCallStack(currentCallStack, currentRouteStack, stackDiffIndex)

				#Execute the setup callstack from the given index
				runSetupCallStack(callStack, routeStack, stackDiffIndex, parameters, loadMethod)

				#return true
				return true

			#END if match

		#END for pattern in assignedPatterns

		#return false, we coudln't find a route
		return false

	#END Finch.call()

	###
	# Method: Finch.reset
	#   Tears down the current stack and resets the routes
	#
	# Arguments:
	#	none
	###
	reset: () ->
		runTeardownCallStack(currentCallStack, currentRouteStack, 0)
		assignedPatterns = {}
		currentRouteStack = []
		currentCallStack = []
		currentCall = null
		return

	#END Finch.reset()
}

#Expose Finch to the window
@Finch = Finch