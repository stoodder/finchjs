(function() {
  var Finch, assignedPatterns, buildCallStack, buildRouteStack, currentCall, currentCallStack, currentQueryParams, currentRouteStack, endsWith, extend, findStackDiffIndex, getParameters, getParentPattern, isArray, isFunction, isNumber, isObject, isString, matchPattern, objectsEqual, parseQueryString, runSetupCallStack, runTeardownCallStack, standardizeRoute, startsWith, trim, trimSlashes;

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

  isNumber = function(object) {
    return Object.prototype.toString.call(object) === "[object Number]";
  };

  trim = function(str) {
    return str.replace(/^\s+/, '').replace(/\s+$/, '');
  };

  trimSlashes = function(str) {
    return str.replace(/^\/+/, '').replace(/\/+$/, '');
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

  objectsEqual = function(obj1, obj2) {
    var key, value;
    for (key in obj1) {
      value = obj1[key];
      if (obj2[key] !== value) return false;
    }
    for (key in obj2) {
      value = obj2[key];
      if (obj1[key] !== value) return false;
    }
    return true;
  };

  assignedPatterns = {};

  currentRouteStack = [];

  currentCallStack = [];

  currentCall = null;

  currentQueryParams = "";

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
    route = trimSlashes(route);
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
  #	parseQueryString
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
    if (queryString !== "") {
      _ref = queryString.split("&");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        piece = _ref[_i];
        _ref2 = piece.split("=", 2), key = _ref2[0], value = _ref2[1];
        queryParams[key] = value;
      }
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
      var assignedPattern;
      assignedPattern = assignedPatterns[pattern];
      if (isObject(assignedPattern)) {
        if (isFunction(assignedPattern.setup)) callStack.unshift(assignedPattern);
        if ((assignedPattern.parentPattern != null) && assignedPattern.parentPattern !== "") {
          return stackAdd(assignedPattern.parentPattern);
        }
      }
    })(pattern);
    return callStack;
  };

  /*
  # Method: runSetupCallStack
  #	Used to execute a callstack from a route starting at it's top most parent
  #
  # Arguments:
  #	callStack - The stack to iterate through (calls each item's setup method)
  #	routeStack - The route stack that is similar to the call stack
  #	staffDiffIndex - The point where the stack should start calling from
  #	parameters - The parameters to extend onto the list of parameters to send onward
  */

  runSetupCallStack = function(callStack, routeStack, stackDiffIndex, parameters) {
    var callSetup, callback, lastItem;
    if (!isArray(callStack)) callStack = [];
    if (!isArray(routeStack)) routeStack = [];
    stackDiffIndex = isNumber(stackDiffIndex) && stackDiffIndex > 0 ? parseInt(stackDiffIndex) : 0;
    if (!isObject(parameters)) parameters = {};
    if (callStack.length <= 0) return;
    lastItem = callStack[callStack.length - 1];
    callback = isFunction(lastItem.load) ? lastItem.load : (function() {});
    currentCall = {
      aborted: false,
      abortedCallback: (function() {}),
      abort: function(cb) {
        if (!isFunction(cb)) cb = (function() {});
        this.aborted = true;
        return this.abortedCallback = function() {
          currentCall = null;
          return cb();
        };
      }
    };
    callStack = callStack.slice(stackDiffIndex);
    routeStack = routeStack.slice(stackDiffIndex);
    (callSetup = function(callStack, routeStack, parameters) {
      var callItem, routeItem;
      if (currentCall.aborted) return currentCall.abortedCallback();
      if (callStack.length <= 0) {
        currentCall = null;
        return callback.call(lastItem.context, parameters, (function() {}));
      }
      callItem = callStack.shift();
      routeItem = routeStack.shift();
      if (!isObject(callItem)) callItem = {};
      if (!isString(routeItem)) routeItem = "";
      if (!isFunction(callItem.setup)) callItem.setup = (function() {});
      if (callback === callItem.setup) callback = (function() {});
      if (callItem.setup.length === 2) {
        return callItem.setup.call(callItem.context, parameters, function(p) {
          currentCallStack.push(callItem);
          currentRouteStack.push(routeItem);
          if (!isObject(p)) p = {};
          extend(parameters, p);
          return callSetup.call(callSetup, callStack, routeStack, parameters);
        });
      } else {
        callItem.setup.call(callItem.context, parameters);
        currentCallStack.push(callItem);
        currentRouteStack.push(routeItem);
        return callSetup(callStack, routeStack, parameters);
      }
    })(callStack, routeStack, parameters);
  };

  /*
  # Method: runTeardownCallStack
  #
  # Arguments:
  #	callStack
  #	routeStack
  #	stackDiffIndex
  */

  runTeardownCallStack = function(callStack, routeStack, stackDiffIndex) {
    var callTeardown;
    if (!isArray(callStack)) callStack = [];
    if (!isArray(routeStack)) routeStack = [];
    stackDiffIndex = isNumber(stackDiffIndex) && stackDiffIndex > 0 ? parseInt(stackDiffIndex) : 0;
    if (callStack.length <= stackDiffIndex) return;
    (callTeardown = function(callStack, routeStack) {
      var callItem, routeItem;
      if (callStack.length <= stackDiffIndex) return;
      callItem = callStack.pop();
      routeItem = routeStack.pop();
      if (!isObject(callItem)) callItem = {};
      if (!isString(routeItem)) routeItem = "";
      if (!isFunction(callItem.teardown)) callItem.teardown = (function() {});
      callItem.teardown.call(callItem.context);
      return callTeardown(callStack, routeStack);
    })(callStack, routeStack);
  };

  /*
  # Method: findStackDiffIndex
  #	Used to find the index between two stacks where they first differentiate
  #
  # Arguments:
  #	oldRouteStack - The old route stack to compate against
  #	newRouteStack - The new route stack to compare with
  #
  # Returns:
  #	int - The first index where the two stacks aren't equal
  */

  findStackDiffIndex = function(oldRouteStack, newRouteStack) {
    var stackIndex;
    if (!isArray(oldRouteStack)) oldRouteStack = [];
    if (!isArray(newRouteStack)) newRouteStack = [];
    stackIndex = 0;
    while (oldRouteStack.length > stackIndex && newRouteStack.length > stackIndex) {
      if (oldRouteStack[stackIndex] !== newRouteStack[stackIndex]) break;
      stackIndex++;
    }
    return stackIndex;
  };

  /*
  # Method: buildRouteStack
  #	Used to build a stack of routes that will
  #	be called with the given route (full routes, not patterns)
  #
  # Arguments:
  #	pattern - The pattern to reference
  #	route - The route to extrpolate from
  */

  buildRouteStack = function(pattern, route) {
    var buildRoute, routeSplit, routeStack;
    pattern = standardizeRoute(pattern);
    route = standardizeRoute(route);
    routeSplit = route.split("/");
    routeStack = [];
    if (routeSplit.length <= 0) return routeStack;
    (buildRoute = function(pattern) {
      var assignedPattern, builtRoute, matches, patternPiece, patternSplit, routePiece, splitIndex;
      patternSplit = pattern.split("/");
      builtRoute = "";
      matches = true;
      splitIndex = 0;
      while (matches && patternSplit.length > splitIndex && routeSplit.length > splitIndex) {
        patternPiece = patternSplit[splitIndex];
        routePiece = routeSplit[splitIndex];
        if (startsWith(patternPiece, ":") || patternPiece === routePiece) {
          builtRoute += "" + routePiece + "/";
        } else {
          matches = false;
        }
        splitIndex++;
      }
      if (endsWith(builtRoute, "/")) builtRoute = builtRoute.slice(0, -1);
      assignedPattern = assignedPatterns[pattern];
      routeStack.unshift(builtRoute);
      if (((assignedPattern != null ? assignedPattern.parentPattern : void 0) != null) && assignedPattern.parentPattern !== "") {
        return buildRoute(assignedPattern.parentPattern, route);
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
    route: function(pattern, settings) {
      var parentPattern;
      if (isFunction(settings)) {
        settings = {
          setup: settings,
          load: settings
        };
      }
      if (!isString(pattern)) pattern = "";
      if (!isObject(settings)) settings = {};
      if (!isObject(settings.context)) settings.context = {};
      if (!isFunction(settings.setup)) settings.setup = (function() {});
      if (!isFunction(settings.load)) settings.load = (function() {});
      if (!isFunction(settings.teardown)) settings.teardown = (function() {});
      parentPattern = getParentPattern(pattern);
      settings.pattern = standardizeRoute(pattern);
      settings.parentPattern = standardizeRoute(parentPattern);
      return assignedPatterns[settings.pattern] = settings;
    },
    /*
    	# Method: Finch.call
    	#
    	# Arguments:
    	#	route - The route to try and call
    	#	parameters (optional) - The initial prameters to send
    */
    call: function(uri, parameters) {
      var assignedPattern, callStack, config, lastItem, pattern, queryParams, queryString, route, routeStack, stackDiffIndex, _ref, _ref2;
      if (!isString(uri)) uri = "";
      if (!isObject(parameters)) parameters = {};
      _ref = uri.split("?", 2), route = _ref[0], queryString = _ref[1];
      route = standardizeRoute(route);
      queryParams = parseQueryString(queryString);
      extend(parameters, queryParams);
      for (pattern in assignedPatterns) {
        config = assignedPatterns[pattern];
        if (matchPattern(route, pattern)) {
          if (currentCall != null) {
            return currentCall.abort(function() {
              return Finch.call(uri, parameters);
            });
          }
          extend(parameters, getParameters(pattern, route));
          assignedPattern = assignedPatterns[pattern];
          callStack = buildCallStack(pattern);
          routeStack = buildRouteStack(pattern, route);
          stackDiffIndex = findStackDiffIndex(currentRouteStack, routeStack);
          if ((currentCallStack.length === (_ref2 = callStack.length) && _ref2 === stackDiffIndex)) {
            if (!objectsEqual(queryParams, currentQueryParams)) {
              lastItem = currentCallStack[currentCallStack.length - 1];
              if (lastItem != null) {
                lastItem.load.call(lastItem.context, parameters);
              }
            }
          } else {
            runTeardownCallStack(currentCallStack, currentRouteStack, stackDiffIndex);
            runSetupCallStack(callStack, routeStack, stackDiffIndex, parameters);
          }
          currentQueryParams = queryParams;
          return true;
        }
      }
      return false;
    },
    /*
    	# Method: Finch.reset
    	#   Tears down the current stack and resets the routes
    	#
    	# Arguments:
    	#	none
    */
    reset: function() {
      runTeardownCallStack(currentCallStack, currentRouteStack, 0);
      assignedPatterns = {};
      currentRouteStack = [];
      currentCallStack = [];
      currentCall = null;
    }
  };

  (function() {
    var hashChange, interval, listening;
    interval = null;
    listening = false;
    hashChange = (function() {
      var currentHash;
      currentHash = null;
      return function(event) {
        var hash, url, urlSplit;
        hash = "";
        if ("hash" in window.location) {
          hash = window.location.hash;
          if (startsWith(hash, "#")) hash = hash.slice(1);
        } else {
          url = window.location.href;
          urlSplit = url.split("#", 2);
          hash = (urlSplit.length === 2 ? urlSplit[1] : "");
        }
        if (hash !== currentHash) {
          Finch.call(hash);
          return currentHash = hash;
        }
      };
    })();
    Finch.listen = function() {
      if (!listening) {
        if ("onhashchange" in window) {
          if (isFunction(window.addEventListener)) {
            window.addEventListener("hashchange", hashChange, true);
            listening = true;
          } else if (isFunction(window.attachEvent)) {
            window.attachEvent("hashchange", hashChange);
            listening = true;
          }
        }
        console.log("listening " + listening);
        if (!listening) {
          interval = setInterval(hashChange, 33);
          listening = true;
        }
        hashChange();
      }
      return listening;
    };
    return Finch.ignore = function() {
      if (listening) {
        if (interval !== null) {
          clearInterval(interval);
          interval = null;
          listening = false;
        }
        if (listening && "onhashchange" in window) {
          if (isFunction(window.removeEventListener)) {
            window.removeEventListener("hashchange", hashChange, true);
            listening = false;
          }
          if (listening && isFunction(window.detachEvent)) {
            window.detachEvent("hashchange", hashChange);
            listening = false;
          }
        }
      }
      return !listening;
    };
  })();

  this.Finch = Finch;

}).call(this);
