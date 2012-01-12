(function() {
  var Finch, assignedRoutes, endsWith, extend, getParameters, getParentRoute, isArray, isFunction, isObject, isString, leftTrim, rightTrim, runCallStack, standardizeRoute, startsWith, trim;

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

  leftTrim = function(str) {
    return str.replace(/^\s+/, '');
  };

  rightTrim = function(str) {
    return str.replace(/\s+$/, '');
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

  assignedRoutes = {};

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
  # Method used to extract the parent route out of a
  */

  getParentRoute = function(route) {
    var closingBracketIndex, parentRoute;
    route = isString(route) ? trim(route) : "";
    parentRoute = null;
    if (startsWith(route, "[")) {
      closingBracketIndex = route.indexOf("]");
      if (closingBracketIndex > 1) {
        parentRoute = route.slice(1, closingBracketIndex);
      }
    }
    return parentRoute;
  };

  /*
  # Method used to extract the parameters out of a route
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
  # Method: runCallStack
  #	Used to execute a callstack from a route starting at it's top most parent
  #
  # Arguments:
  #	pattern - The route pattern to try and call
  #	parameters - The parameters to extend onto the list of parameters to send onward
  */

  runCallStack = function(pattern, parameters) {
    var callItem, stack, stackAdd;
    pattern = standardizeRoute(pattern);
    if (!isObject(parameters)) parameters = {};
    stack = [];
    (stackAdd = function(route) {
      route = assignedRoutes[route];
      if (isObject(route)) {
        if (isFunction(route.setup)) stack.unshift(route.setup);
        if ((route.parentRoute != null) && route.parentRoute !== "") {
          return stackAdd(route.parentRoute);
        }
      }
    })(pattern);
    (callItem = function(stack, parameters) {
      var item;
      if (stack.length <= 0) return;
      item = stack.shift();
      if (!isFunction(item)) item = (function() {});
      if (item.length === 2) {
        return item(parameters, function(p) {
          if (!isObject(p)) p = {};
          extend(parameters, p);
          return callItem.call(callItem, stack, parameters);
        });
      } else {
        item(parameters);
        return callItem(stack, parameters);
      }
    })(stack, parameters);
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
      var parentRoute;
      if (!isString(pattern)) pattern = "";
      if (!isFunction(callback)) callback = (function() {});
      parentRoute = getParentRoute(pattern);
      pattern = standardizeRoute(pattern);
      parentRoute = standardizeRoute(parentRoute);
      return assignedRoutes[pattern] = {
        parentRoute: parentRoute,
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
    call: function(route, parameters) {
      var config, pattern;
      route = standardizeRoute(route);
      if (!isObject(parameters)) parameters = {};
      if (isFunction(assignedRoutes[route])) {
        return assignedRoutes[route](parameters);
      }
      for (pattern in assignedRoutes) {
        config = assignedRoutes[pattern];
        if (Finch.match(route, pattern)) {
          extend(parameters, getParameters(pattern, route));
          runCallStack(pattern, parameters);
          return true;
        }
      }
      return false;
    },
    /*
    	# Method: Finch.match
    	#	Method used to determine if a route matches a pattern
    	#
    	# Arguments:
    	#	route - The route to check
    	#	pattern - The pattern to compare the route against
    	#
    	# Returns:
    	#	boolean - Did the route match the pattern?
    */
    match: function(route, pattern) {
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
    },
    log: function() {
      return console.log(assignedRoutes);
    }
  };

  this.Finch = Finch;

}).call(this);
