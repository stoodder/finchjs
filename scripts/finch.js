(function() {
  var Finch, assignedPatterns, buildCallStack, endsWith, extend, extrapolateRouteStack, getParameters, getParentPattern, isArray, isFunction, isObject, isString, matchPattern, parseQueryString, runCallStack, standardizeRoute, startsWith, trim;

  isObject = function(object) {
    return typeof object === typeof {};
  };

  isFunction = function(object) {
    return Object.prototype.toString.call(object) === "[object Function]";
  };

  isArray = function(object) {
    return Object.prototype.toString.call(object) === "[object Array]";
  };

  isString = function(object) {
    return Object.prototype.toString.call(object) === "[object String]";
  };

  trim = function(str) {
    return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
  };

  startsWith = function(haystack, needle) {
    return haystack.indexOf(needle) === 0;
  };

  endsWith = function(haystack, needle) {
    return haystack.indexOf(needle, haystack.length - needle.length) !== -1;
  };

  extend = function(obj, extender) {
    var key, value;
    if (!isObject(obj)) obj = {};
    if (!isObject(extender)) extender = {};
    for (key in extender) {
      value = extender[key];
      obj[key] = value;
    }
    return obj;
  };

  assignedPatterns = {};

  /*
  # Method used to standardize a route so we can better parse through it
  */

  standardizeRoute = function(route) {
    var closingBracketIndex;
    route = isString(route) ? trim(route) : "";
    if (startsWith(route, "[")) {
      closingBracketIndex = route.indexOf("]");
      if (closingBracketIndex > 1) {
        route = route.slice(1, closingBracketIndex) + route.slice(closingBracketIndex + 1);
      } else {
        route = route.slice(Math.max(1, closingBracketIndex + 1));
      }
    }
    if (startsWith(route, "/")) route = route.slice(1);
    if (endsWith(route, "/")) route = route.slice(0, route.length - 1);
    return route;
  };

  /*
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
  */

  getParentPattern = function(pattern) {
    var closingBracketIndex, parentPattern;
    pattern = isString(pattern) ? trim(pattern) : "";
    parentPattern = null;
    if (startsWith(pattern, "[")) {
      closingBracketIndex = pattern.indexOf("]");
      if (closingBracketIndex > 1) {
        parentPattern = pattern.slice(1, closingBracketIndex);
      }
    }
    return parentPattern;
  };

  /*
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
  #	parseQuryString
  */

  getParameters = function(pattern, route) {
    var index, parameters, patternPiece, patternSplit, routeSplit;
    if (!isString(route)) route = "";
    if (!isString(pattern)) pattern = "";
    route = standardizeRoute(route);
    pattern = standardizeRoute(pattern);
    routeSplit = route.split("/");
    patternSplit = pattern.split("/");
    if (routeSplit.length !== patternSplit.length) return {};
    parameters = {};
    for (index in patternSplit) {
      patternPiece = patternSplit[index];
      if (startsWith(patternPiece, ":")) {
        parameters[patternPiece.slice(1)] = routeSplit[index];
      }
    }
    return parameters;
  };

  /*
  # Method: parseQueryString
  #	Used to parse and objectize a query string
  #
  # Arguments: 
  #	queryString - The query string to split up into an object
  #
  # Returns:
  #	object - An object of the split apart query string
  */

  parseQueryString = function(queryString) {
    var key, piece, queryParams, value, _i, _len, _ref, _ref2;
    queryString = isString(queryString) ? trim(queryString) : "";
    queryParams = {};
    _ref = queryString.split("&");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      piece = _ref[_i];
      _ref2 = piece.split("=", 2), key = _ref2[0], value = _ref2[1];
      queryParams[key] = value;
    }
    return queryParams;
  };

  /*
  # Method: matchPattern
  #	Method used to determine if a route matches a pattern
  #
  # Arguments:
  #	route - The route to check
  #	pattern - The pattern to compare the route against
  #
  # Returns:
  #	boolean - Did the route match the pattern?
  */

  matchPattern = function(route, pattern) {
    var index, patternPiece, patternSplit, routeSplit;
    route = standardizeRoute(route);
    pattern = standardizeRoute(pattern);
    routeSplit = route.split("/");
    patternSplit = pattern.split("/");
    if (routeSplit.length !== patternSplit.length) return false;
    for (index in patternSplit) {
      patternPiece = patternSplit[index];
      if (!(patternPiece === routeSplit[index] || startsWith(patternPiece, ":"))) {
        return false;
      }
    }
    return true;
  };

  /*
  # Method: buildCallStack
  #	Used to build up a callstack for a given patterrn
  #
  # Arguments:
  #	pattern - The route pattern to try and call
  */

  buildCallStack = function(pattern) {
    var callStack, stackAdd;
    pattern = standardizeRoute(pattern);
    callStack = [];
    (stackAdd = function(pattern) {
      pattern = assignedPatterns[pattern];
      if (isObject(pattern)) {
        if (isFunction(pattern.setup)) callStack.push(pattern);
        if ((pattern.parentPattern != null) && pattern.parentPattern !== "") {
          return stackAdd(pattern.parentPattern);
        }
      }
    })(pattern);
    return callStack;
  };

  /*
  # Method: runCallStack
  #	Used to execute a callstack from a route starting at it's top most parent
  #
  # Arguments:
  #	stack - The stack to iterate through
  #	parameters - The parameters to extend onto the list of parameters to send onward
  */

  runCallStack = function(callStack, parameters) {
    var callItem;
    if (!isArray(callStack)) callStack = [];
    if (!isObject(parameters)) parameters = {};
    (callItem = function(stack, parameters) {
      var item, setup;
      if (stack.length <= 0) return;
      item = stack.pop();
      if (!isObject(item)) item = {};
      if (!isFunction(item.setup)) setup = (function() {});
      if (item.setup.length === 2) {
        return item.setup(parameters, function(p) {
          if (!isObject(p)) p = {};
          extend(parameters, p);
          return callItem.call(callItem, stack, parameters);
        });
      } else {
        item.setup(parameters);
        return callItem(stack, parameters);
      }
    })(callStack, parameters);
  };

  /*
  # Method: extrapolateRouteStack
  #	Used to extrpolate a stack of routes that will
  #	be called with the given route (full routes, not patterns)
  #
  # Arguments:
  #	pattern - The pattern to reference
  #	route - The route to extrpolate from
  */

  extrapolateRouteStack = function(pattern, route) {
    var extrapolate, routeSplit, routeStack;
    pattern = standardizeRoute(pattern);
    route = standardizeRoute(route);
    routeSplit = route.split("/");
    routeStack = [];
    if (routeSplit.length <= 0) return routeStack;
    (extrapolate = function(pattern) {
      var assignedPattern, extrapolatedRoute, matches, patternPiece, patternSplit, routePiece, splitIndex;
      patternSplit = pattern.split("/");
      extrapolatedRoute = "";
      matches = true;
      splitIndex = 0;
      while (matches && patternSplit.length > splitIndex && routeSplit.length > splitIndex) {
        patternPiece = patternSplit[splitIndex];
        routePiece = routeSplit[splitIndex];
        if (startsWith(patternPiece, ":") || patternPiece === routePiece) {
          extrapolatedRoute += "" + routePiece + "/";
        } else {
          matches = false;
        }
        splitIndex++;
      }
      if (endsWith(extrapolatedRoute, "/")) {
        extrapolatedRoute = extrapolatedRoute.slice(0, -1);
      }
      assignedPattern = assignedPatterns[pattern];
      if (extrapolatedRoute !== "") {
        routeStack.push(extrapolatedRoute);
        if ((assignedPattern.parentPattern != null) && assignedPattern.parentPattern !== "") {
          return extrapolate(assignedPattern.parentPattern, route);
        }
      }
    })(pattern);
    return routeStack;
  };

  /*
  # Class: Finch
  */

  Finch = {
    /*
    	# Mathod: Finch.route
    	#	Used to setup a new route
    	#
    	# Arguments:
    	#	pattern - The pattern to add
    	#	callback - The callback to assign to the pattern
    */
    route: function(pattern, callback) {
      var parentPattern;
      if (!isString(pattern)) pattern = "";
      if (!isFunction(callback)) callback = (function() {});
      parentPattern = getParentPattern(pattern);
      pattern = standardizeRoute(pattern);
      parentPattern = standardizeRoute(parentPattern);
      return assignedPatterns[pattern] = {
        context: {},
        pattern: pattern,
        parentPattern: parentPattern,
        setup: callback,
        teardown: (function() {})
      };
    },
    /*
    	# Method: Finch.call
    	#
    	# Arguments:
    	#	route - The route to try and call
    	#	parameters (optional) - The initial prameters to send
    */
    call: function(uri, parameters) {
      var callStack, config, pattern, queryParams, queryString, route, _ref;
      if (!isString(uri)) uri = "";
      if (!isObject(parameters)) parameters = {};
      _ref = uri.split("?", 2), route = _ref[0], queryString = _ref[1];
      route = standardizeRoute(route);
      queryParams = parseQueryString(queryString);
      extend(parameters, queryParams);
      if (isFunction(assignedPatterns[route])) {
        return assignedPatterns[route](parameters);
      }
      for (pattern in assignedPatterns) {
        config = assignedPatterns[pattern];
        if (matchPattern(route, pattern)) {
          extend(parameters, getParameters(pattern, route));
          callStack = buildCallStack(pattern);
          runCallStack(callStack, parameters);
          return true;
        }
      }
      return false;
    }
  };

  this.Finch = Finch;

}).call(this);
