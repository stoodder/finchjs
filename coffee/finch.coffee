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
#
###
standardizeRoute = (route) ->
	return "" unless isString route

	route = trim(route)
	route = route.slice(1) if startsWith(route, "/")
	route = route.slice(0, route.length-1) if endsWith(route, "/")

	return route

###
#
###
stripBrackets = (route) ->
	route = "" unless isString(route)
	route = trim(route)

	if startsWith(route, "[")
		closingBracketIndex = route.indexOf("]")

		if closingBracketIndex > 1
			route = route.slice(1, closingBracketIndex) + route.slice(closingBracketIndex+1)
		else
			route = route.slice( Math.max(1, closingBracketIndex+1) )

	return route

###
#
###
getParentRoute = (route) ->
	route = "" unless isString(route)

	parentRoute = null
	route = trim(route)

	if startsWith(route, "[")
		closingBracketIndex = route.indexOf("]")

		if closingBracketIndex > 1
			parentRoute = route.slice(1, closingBracketIndex)
	
	return parentRoute

###
#
###
Finch = {

	###
	#
	###
	route: (route, callback) ->

		#Make sure we have valid inputs
		route = "" unless isString(route)
		callback = (->) unless isFunction(callback)

		#trim the route
		route = trim(route)

		#initialize the parent route to call
		parentRoute = getParentRoute(route)

		#Strip the brackets
		route = stripBrackets(route)

		#Standardize the route
		route = standardizeRoute(route)
		parentRoute = standardizeRoute(parentRoute)

		#Store the action for later
		assignedRoutes[route] = (params) -> 

			#Try to call the parent route first if assigned
			Finch.call(parentRoute, params)

			#Call this routes callback
			callback(params)
		
		#END assignedRoutes[route]
	
	#END Finch.route

	###
	#
	###
	call: (route, parameters) ->

		#Make sure we have valid arguments
		route = "" unless isString(route)
		parameters = {} unless isObject(parameters)

		#Standardize the route
		route = standardizeRoute(route)

		if assignedRoutes[route]
			callback = assignedRoutes[route]
			extend(parameters, Finch.getParameters(pattern, route))
			callback(parameters) if isFunction(callback)
			return true

		#Iterate over each of the assigned routes
		for pattern, callback of assignedRoutes
			
			#Check if this route matches the input route
			if Finch.match(pattern, route)
				extend(parameters, Finch.getParameters(pattern, route))
			
				#Call the route's method if it is a set
				callback(parameters) if isFunction(callback)

				#return true
				return true
			
			#END if match
		
		#END for pattern in assignedRoutes
		
		#return false, we coudln't find a route
		return false
	
	###
	#
	###
	match: (pattern, route) ->
		route = "" unless isString(route)
		pattern = "" unless isString(pattern)

		route = standardizeRoute(route)
		pattern = standardizeRoute(pattern)

		routeSplit = route.split("/")
		patternSplit = pattern.split("/")

		return false if routeSplit.length isnt patternSplit.length

		for index, patternPiece of patternSplit
			return false unless patternPiece is routeSplit[index] or startsWith(patternPiece, ":")

		return true
	
	###
	#
	###
	getParameters: (pattern, route) ->
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
}

#EXpose finch to the window
@Finch = Finch

# /home
# {/home}/news
# {/home/news}/:id