isObject = (object) -> ( typeof object == typeof {} );
isFunction = (object) -> Object::toString.call( object ) is "[object Function]"
isArray = (object) -> Object::toString.call( object ) is "[object Array]"
isString = (object) -> Object::toString.call( object ) is "[object String]"

trim = (str) -> str.replace(/^\s\s*/, '').replace(/\s\s*$/, '')
leftTrim = (str) -> str.replace(/^\s+/,'')
rightTrim = (str) -> str.replace(/\s+$/,'')
startsWith = (haystack, needle) -> haystack.indexOf(needle) is 0
endsWith = (haystack, needle) ->  haystack.indexOf(needle, haystack.length - needle.length) isnt -1

extend = (obj, extender) ->
	obj = {} unless isObject(obj)
	extender = {} unless isObject(extender)

	obj[key] = value for key, value of extender
		
	return obj

#
assignedRoutes = {}

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
	route = route.slice(1) if startsWith(route, "/")
	route = route.slice(0, route.length-1) if endsWith(route, "/")

	return route

###
# Method used to extract the parent route out of a 
###
getParentRoute = (route) ->

	#Initialzie the parameters
	route = if isString(route) then trim(route) else ""
	parentRoute = null

	#Check if we're starting with a bracket
	if startsWith(route, "[")

		#find the closing bracket
		closingBracketIndex = route.indexOf("]")

		#If we found one with a route inside, get the parentRoute
		if closingBracketIndex > 1
			parentRoute = route.slice(1, closingBracketIndex)
	
	return parentRoute

###
# Method used to extract the parameters out of a route
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

###
# Method: runCallStack
#	Used to execute a callstack from a route starting at it's top most parent
#
# Arguments:
#	pattern - The route pattern to try and call
#	parameters - The parameters to extend onto the list of parameters to send onward
###
runCallStack = (pattern, parameters) ->

	#First setup the variables
	pattern = standardizeRoute(pattern)
	parameters = {} unless isObject(parameters)
	stack = []

	#Next build the callstack
	(stackAdd = (route) ->
		route = assignedRoutes[route]

		if isObject(route)
			stack.unshift(route.setup) if isFunction(route.setup)
			stackAdd(route.parentRoute) if route.parentRoute? and route.parentRoute isnt ""
	)(pattern)

	#TODO: Eliminate steps in the call stack that have already been run

	#Lastly execute the callstack, taking into account methods that request for the child callback
	(callItem = (stack, parameters) ->
		return if stack.length <= 0

		item = stack.shift()
		item = (->) unless isFunction(item)

		if item.length == 2
			item( parameters, (p) -> 
				p = {} unless isObject(p)
				extend(parameters, p)
				callItem.call( callItem, stack, parameters )
			)
		else
			item(parameters)
			callItem(stack, parameters)
	)(stack, parameters)

	return


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
	route: (pattern, callback) ->

		#Make sure we have valid inputs
		pattern = "" unless isString(pattern)
		callback = (->) unless isFunction(callback)

		#initialize the parent route to call
		parentRoute = getParentRoute(pattern)

		#Standardize the rotues
		pattern = standardizeRoute(pattern)
		parentRoute = standardizeRoute(parentRoute)

		#Store the action for later
		assignedRoutes[pattern] = {
			parentRoute: parentRoute
			setup: callback
			teardown: (->)
		}
		
		#END assignedRoutes[route]
	
	#END Finch.route

	###
	# Method: Finch.call
	#
	# Arguments:
	#	route - The route to try and call
	#	parameters (optional) - The initial prameters to send
	###
	call: (route, parameters) ->

		#Make sure we have valid arguments
		route = standardizeRoute(route)
		parameters = {} unless isObject(parameters)

		# Check if the user is just trying to call on a pattern
		# If so just call it's callback and return
		return assignedRoutes[route](parameters) if isFunction(assignedRoutes[route])

		# Iterate over each of the assigned routes and try to find a match
		for pattern, config of assignedRoutes
			
			#Check if this route matches the input routpatterne
			if Finch.match(route, pattern)
				
				#Get the parameters of the route
				extend(parameters, getParameters(pattern, route))

				#Lastly, since we found a route, run its callstack with the starting parameters
				runCallStack(pattern, parameters)

				#return true
				return true
			
			#END if match
		
		#END for pattern in assignedRoutes
		
		#return false, we coudln't find a route
		return false
	
	#END Finch.call()
	
	###
	# Method: Finch.match
	#	Method used to determine if a route matches a pattern
	#
	# Arguments:
	#	route - The route to check
	#	pattern - The pattern to compare the route against
	#
	# Returns:
	#	boolean - Did the route match the pattern?
	###
	match: (route, pattern) ->
		route = standardizeRoute(route)
		pattern = standardizeRoute(pattern)

		routeSplit = route.split("/")
		patternSplit = pattern.split("/")

		#if the lengths aren't the same, this isn't valid
		return false if routeSplit.length isnt patternSplit.length

		for index, patternPiece of patternSplit
			return false unless patternPiece is routeSplit[index] or startsWith(patternPiece, ":")

		return true
	
	#END Finch.match()

	log: () ->
		console.log(assignedRoutes)

}

#Expose Finch to the window
@Finch = Finch