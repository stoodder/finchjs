(function() {
  var Finch, NodeType, Route, RouteTreeNode, addRoute, arraysEqual, contains, currentRoute, endsWith, extend, findNearestCommonAncestor, findRoute, getChildRouteString, getComponentName, getComponentType, getParentRouteString, isArray, isFunction, isNumber, isObject, isString, loadRoute, objectsEqual, parseQueryString, routeTreeRoot, setupRoute, splitRouteString, startsWith, teardownRoute, trim, trimSlashes;

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

  contains = function(haystack, needle) {
    return haystack.indexOf(needle) !== -1;
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

  arraysEqual = function(arr1, arr2) {
    var index, value, _len;
    if (arr1.length !== arr2.length) return false;
    for (index = 0, _len = arr1.length; index < _len; index++) {
      value = arr1[index];
      if (arr2[index] !== value) return false;
    }
    return true;
  };

  NodeType = {
    Literal: 'Literal',
    Variable: 'Variable'
  };

  RouteTreeNode = (function() {

    function RouteTreeNode(_arg) {
      var name, nodeType;
      name = _arg.name, nodeType = _arg.nodeType;
      this.name = name != null ? name : "";
      this.nodeType = nodeType != null ? nodeType : void 0;
      this.parentNode = void 0;
      this.route = void 0;
      this.childLiterals = {};
      this.childVariable = void 0;
      this.bindings = [];
    }

    return RouteTreeNode;

  })();

  Route = (function() {

    function Route(_arg) {
      var context, load, setup, teardown;
      setup = _arg.setup, load = _arg.load, teardown = _arg.teardown, context = _arg.context;
      this.setup = isFunction(setup) ? setup : (function() {});
      this.load = isFunction(load) ? load : (function() {});
      this.teardown = isFunction(teardown) ? teardown : (function() {});
      this.context = isObject(context) ? context : {};
    }

    return Route;

  })();

  routeTreeRoot = new RouteTreeNode({
    name: "*"
  });

  currentRoute = {
    node: void 0,
    boundValues: {},
    parameters: {}
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
    var key, piece, queryParameters, value, _i, _len, _ref, _ref2;
    queryString = isString(queryString) ? trim(queryString) : "";
    queryParameters = {};
    if (queryString !== "") {
      _ref = queryString.split("&");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        piece = _ref[_i];
        _ref2 = piece.split("=", 2), key = _ref2[0], value = _ref2[1];
        queryParameters[key] = value;
      }
    }
    return queryParameters;
  };

  /*
  # Method: getParentRouteString
  #	Gets the parent route sub-string of a route string
  #
  # Arguments:
  #	routeString - The route string to parse
  #
  # Returns:
  #	string - The parent route sub-string
  */

  getParentRouteString = function(routeString) {
    var closingBracketIndex;
    if (!startsWith(routeString, "[")) return "";
    closingBracketIndex = routeString.indexOf("]");
    return routeString.slice(1, (closingBracketIndex - 1) + 1 || 9e9);
  };

  /*
  # Method: getChildRouteString
  #	Gets the child route sub-string of a route string
  #
  # Arguments:
  #	routeString - The route string to parse
  #
  # Returns:
  #	string - The child route sub-string
  */

  getChildRouteString = function(routeString) {
    var closingBracketIndex;
    if (!startsWith(routeString, "[")) return routeString;
    closingBracketIndex = routeString.indexOf("]");
    return routeString.slice(closingBracketIndex + 1);
  };

  /*
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
  */

  splitRouteString = function(routeString) {
    routeString = trimSlashes(routeString);
    if (routeString === "") {
      return [];
    } else {
      return routeString.split('/');
    }
  };

  getComponentType = function(routeStringComponent) {
    if (startsWith(routeStringComponent, ":")) return NodeType.Variable;
    return NodeType.Literal;
  };

  getComponentName = function(routeStringComponent) {
    switch (getComponentType(routeStringComponent)) {
      case NodeType.Literal:
        return routeStringComponent;
      case NodeType.Variable:
        return routeStringComponent.slice(1);
    }
  };

  /*
  # Method: addRoute
  #	Adds a new route node to the route tree, given a route string.
  #
  # Arguments:
  #	routeString - The route string to parse and add to the route tree.
  #	settings - The settings for the new route
  #
  # Returns:
  #	Route - The added route
  */

  addRoute = function(routeString, settings) {
    var bindings, childRouteComponents, parentNode, parentRouteComponents, recur;
    parentRouteComponents = splitRouteString(getParentRouteString(routeString));
    childRouteComponents = splitRouteString(getChildRouteString(routeString));
    parentNode = void 0;
    bindings = [];
    return (recur = function(currentNode, name) {
      var component, componentName, componentType, nextNode, onParentNode, _base, _ref, _ref2;
      component = void 0;
      onParentNode = false;
      nextNode = void 0;
      if (parentRouteComponents.length <= 0 && childRouteComponents.length <= 0) {
        currentNode.parentNode = parentNode;
        currentNode.bindings = bindings;
        return currentNode.route = new Route(settings);
      }
      if (parentRouteComponents.length > 0) {
        component = parentRouteComponents.shift();
        if (parentRouteComponents.length === 0) onParentNode = true;
      } else {
        component = childRouteComponents.shift();
      }
      componentType = getComponentType(component);
      componentName = getComponentName(component);
      name = "" + name + "/" + component;
      switch (componentType) {
        case NodeType.Literal:
          nextNode = (_ref = (_base = currentNode.childLiterals)[componentName]) != null ? _ref : _base[componentName] = new RouteTreeNode({
            name: name,
            nodeType: componentType
          });
          break;
        case NodeType.Variable:
          nextNode = (_ref2 = currentNode.childVariable) != null ? _ref2 : currentNode.childVariable = new RouteTreeNode({
            name: name,
            nodeType: componentType
          });
          bindings.push(componentName);
      }
      if (onParentNode) parentNode = nextNode;
      return recur(nextNode, name);
    })(routeTreeRoot, "");
  };

  /*
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
  */

  findRoute = function(uri) {
    var boundValues, recur, uriComponents;
    uriComponents = splitRouteString(uri);
    boundValues = [];
    return (recur = function(currentNode) {
      var component, result;
      if (uriComponents.length <= 0) {
        return {
          node: currentNode,
          boundValues: boundValues
        };
      }
      component = uriComponents.shift();
      if (currentNode.childLiterals[component] != null) {
        result = recur(currentNode.childLiterals[component]);
        if (result != null) return result;
      }
      if (currentNode.childVariable != null) {
        boundValues.push(component);
        result = recur(currentNode.childVariable);
        if (result != null) return result;
        boundValues.pop();
      }
    })(routeTreeRoot);
  };

  /*
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
  */

  findNearestCommonAncestor = function(route1, route2) {
    var ancestor, ancestors, boundValues1, boundValues2, currentNode, node1, node2, _i, _len, _ref, _ref2;
    _ref = [route1.node, route1.boundValues], node1 = _ref[0], boundValues1 = _ref[1];
    _ref2 = [route2.node, route2.boundValues], node2 = _ref2[0], boundValues2 = _ref2[1];
    ancestors = [];
    currentNode = node1;
    while (currentNode != null) {
      ancestors.push({
        node: currentNode,
        boundValues: boundValues1
      });
      if (currentNode.nodeType === NodeType.Variable) {
        boundValues1 = boundValues1.slice(0, boundValues1.length - 1);
      }
      currentNode = currentNode.parentNode;
    }
    currentNode = node2;
    while (currentNode != null) {
      for (_i = 0, _len = ancestors.length; _i < _len; _i++) {
        ancestor = ancestors[_i];
        if (ancestor.node === currentNode && arraysEqual(ancestor.boundValues, boundValues2)) {
          return currentNode;
        }
      }
      if (currentNode.nodeType === NodeType.Variable) {
        boundValues2 = boundValues2.slice(0, boundValues2.length - 1);
      }
      currentNode = currentNode.parentNode;
    }
  };

  /*
  # Method: setupRoute
  #	Recursively sets up a new route given an ancestor from which to start the setup.
  #
  # Arguments:
  #	ancestor - The ancestor node of the new route that represents the current state
  #	newRouteNode - The route node to set up to
  #	parameters - The parameters for the new route
  */

  setupRoute = function(ancestor, newRouteNode, parameters) {
    var recur;
    return (recur = function(currentNode, continuation) {
      if (currentNode === ancestor) {
        return continuation(parameters);
      } else {
        return recur(currentNode.parentNode, function(parameters) {
          var context, setup, _ref;
          _ref = currentNode.route, context = _ref.context, setup = _ref.setup;
          if (setup.length === 2) {
            return setup.call(context, parameters, function(addedParameters) {
              if (!isObject(addedParameters)) addedParameters = {};
              parameters = extend({}, parameters);
              extend(parameters, addedParameters);
              return continuation(parameters);
            });
          } else {
            setup.call(context, parameters);
            return continuation(parameters);
          }
        });
      }
    })(newRouteNode, function(parameters) {
      var load, setup, _ref;
      _ref = newRouteNode.route, setup = _ref.setup, load = _ref.load;
      if (setup !== load) return loadRoute(newRouteNode, parameters);
    });
  };

  /*
  # Method: loadRoute
  #	Loads a route with the given parameters.
  #
  # Arguments:
  #	routeNode- The route node to load
  #	parameters - The parameters for the route
  */

  loadRoute = function(routeNode, parameters) {
    var context, load, _ref;
    _ref = routeNode.route, context = _ref.context, load = _ref.load;
    return load.call(context, parameters);
  };

  /*
  # Method: teardownRoute
  #	Recursively tears down the current route given an ancestor to tear down to.
  #
  # Arguments:
  #	ancestor - The ancestor node to tear down to
  */

  teardownRoute = function(ancestor) {
    var recur;
    return (recur = function(currentNode) {
      var context;
      if (currentNode !== ancestor) {
        context = currentNode.route.context;
        currentNode.route.teardown.call(context);
        return recur(currentNode.parentNode);
      }
    })(currentRoute.node);
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
      if (isFunction(settings)) {
        settings = {
          setup: settings,
          load: settings
        };
      }
      if (!isObject(settings)) settings = {};
      if (!isString(pattern)) pattern = "";
      return addRoute(pattern, settings);
    },
    /*
    	# Method: Finch.call
    	#
    	# Arguments:
    	#	route - The route to try and call
    	#	parameters (optional) - The initial prameters to send
    */
    call: function(uri, parameters) {
      var ancestor, binding, index, newRoute, queryParameters, queryString, _len, _ref, _ref2;
      if (!isString(uri)) uri = "";
      if (!isObject(parameters)) parameters = {};
      _ref = uri.split("?", 2), uri = _ref[0], queryString = _ref[1];
      queryParameters = parseQueryString(queryString);
      newRoute = findRoute(uri);
      if (!(newRoute != null)) return false;
      newRoute.parameters = extend(parameters, queryParameters);
      _ref2 = newRoute.node.bindings;
      for (index = 0, _len = _ref2.length; index < _len; index++) {
        binding = _ref2[index];
        newRoute.parameters[binding] = newRoute.boundValues[index];
      }
      if (newRoute.node === currentRoute.node && arraysEqual(newRoute.boundValues, currentRoute.boundValues)) {
        if (!objectsEqual(currentRoute.parameters, newRoute.parameters)) {
          loadRoute(newRoute.node, newRoute.parameters);
        }
      } else {
        ancestor = findNearestCommonAncestor({
          node: currentRoute.node,
          boundValues: currentRoute.boundValues
        }, newRoute);
        teardownRoute(ancestor);
        setupRoute(ancestor, newRoute.node, newRoute.parameters);
      }
      currentRoute = newRoute;
      return true;
    },
    /*
    	# Method: Finch.reset
    	#   Tears down the current stack and resets the routes
    	#
    	# Arguments:
    	#	none
    */
    reset: function() {
      teardownRoute(void 0);
      routeTreeRoot = new RouteTreeNode({
        name: "*"
      });
    }
  };

  this.Finch = Finch;

}).call(this);
