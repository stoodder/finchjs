(function() {
  var Finch, NodeType, RoutePath, RouteSettings, RouteTreeNode, addRoute, arraysEqual, contains, currentParameters, currentPath, endsWith, extend, findNearestCommonAncestor, findRoutePath, getChildRouteString, getComponentName, getComponentType, getParentRouteString, isArray, isFunction, isNumber, isObject, isString, loadRoute, objectsEqual, parseQueryString, routeTreeRoot, setupRoute, splitRouteString, startsWith, teardownRoute, trim, trimSlashes;

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
      var name, nodeType, parent, _ref;
      _ref = _arg != null ? _arg : {}, name = _ref.name, nodeType = _ref.nodeType, parent = _ref.parent;
      this.name = name != null ? name : "";
      this.nodeType = nodeType != null ? nodeType : null;
      this.parent = parent != null ? parent : null;
      this.routeSettings = null;
      this.childLiterals = {};
      this.childVariable = null;
      this.bindings = [];
    }

    return RouteTreeNode;

  })();

  RouteSettings = (function() {

    function RouteSettings(_arg) {
      var context, load, setup, teardown, _ref;
      _ref = _arg != null ? _arg : {}, setup = _ref.setup, load = _ref.load, teardown = _ref.teardown, context = _ref.context;
      this.setup = isFunction(setup) ? setup : (function() {});
      this.load = isFunction(load) ? load : (function() {});
      this.teardown = isFunction(teardown) ? teardown : (function() {});
      this.context = isObject(context) ? context : {};
    }

    return RouteSettings;

  })();

  RoutePath = (function() {

    function RoutePath(_arg) {
      var boundValues, node, _ref;
      _ref = _arg != null ? _arg : {}, node = _ref.node, boundValues = _ref.boundValues;
      this.node = node != null ? node : null;
      this.boundValues = boundValues != null ? boundValues : [];
    }

    RoutePath.prototype.getBindings = function() {
      var binding, bindings, index, _len, _ref;
      bindings = {};
      _ref = this.node.bindings;
      for (index = 0, _len = _ref.length; index < _len; index++) {
        binding = _ref[index];
        bindings[binding] = this.boundValues[index];
      }
      return bindings;
    };

    RoutePath.prototype.isEqual = function(routePath) {
      return (routePath != null) && this.node === routePath.node && arraysEqual(this.boundValues, routePath.boundValues);
    };

    RoutePath.prototype.isRoot = function() {
      return !(this.node.parent != null);
    };

    RoutePath.prototype.getParent = function() {
      var bindingCount, boundValues, _ref, _ref2;
      if (this.node == null) return null;
      bindingCount = (_ref = (_ref2 = this.node.parent) != null ? _ref2.bindings.length : void 0) != null ? _ref : 0;
      boundValues = this.boundValues.slice(0, bindingCount);
      return new RoutePath({
        node: this.node.parent,
        boundValues: boundValues
      });
    };

    RoutePath.prototype.getChild = function(targetRoutePath) {
      var boundvalues, targetNode;
      targetNode = targetRoutePath != null ? targetRoutePath.node : void 0;
      while ((targetNode != null) && targetNode.parent !== this.node) {
        targetNode = targetNode.parent;
      }
      if (targetNode == null) return null;
      if (!arraysEqual(this.boundValues, targetNode.boundValues.slice(0, this.boundValues.length + 1 || 9e9))) {
        return null;
      }
      boundvalues = this.boundValues.slice(0);
      if (targetNode.nodeType === NodeType.Variable) {
        boundValues.push(targetNode.boundValues[this.boundValues.length]);
      }
      return new RoutePath({
        node: targetNode,
        boundValues: boundValues
      });
    };

    return RoutePath;

  })();

  /*
  # Globals
  */

  routeTreeRoot = new RouteTreeNode({
    name: "*"
  });

  currentPath = new RoutePath({
    node: null
  });

  currentParameters = {};

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
    if (routeString === "") return [];
    routeString = trimSlashes(routeString);
    return routeString.split('/');
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

  addRoute = function(routeTreeRoot, routeString, settings) {
    var bindings, childRouteComponents, parentNode, parentRouteComponents, recur;
    parentRouteComponents = splitRouteString(getParentRouteString(routeString));
    childRouteComponents = splitRouteString(getChildRouteString(routeString));
    parentNode = routeTreeRoot;
    bindings = [];
    return (recur = function(currentNode, name) {
      var component, componentName, componentType, nextNode, onParentNode, _base, _ref, _ref2;
      component = null;
      onParentNode = false;
      nextNode = null;
      if (parentRouteComponents.length <= 0 && childRouteComponents.length <= 0) {
        currentNode.parent = parentNode;
        currentNode.bindings = bindings;
        return currentNode.routeSettings = new RouteSettings(settings);
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
            nodeType: componentType,
            parent: routeTreeRoot
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
  */

  findRoutePath = function(uri) {
    var boundValues, recur, uriComponents;
    uriComponents = splitRouteString(uri);
    boundValues = [];
    return (recur = function(currentNode) {
      var component, result;
      if (uriComponents.length <= 0) {
        return new RoutePath({
          node: currentNode,
          boundValues: boundValues
        });
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
      return null;
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
  #	null if there is no common ancestor.
  */

  findNearestCommonAncestor = function(routePath1, routePath2) {
    var ancestor, ancestors, currentRoute, _i, _len;
    ancestors = [];
    currentRoute = routePath2;
    while (currentRoute != null) {
      ancestors.push(currentRoute);
      currentRoute = currentRoute.getParent();
    }
    currentRoute = routePath1;
    while (currentRoute != null) {
      for (_i = 0, _len = ancestors.length; _i < _len; _i++) {
        ancestor = ancestors[_i];
        if (currentRoute.isEqual(ancestor)) return currentRoute;
      }
      currentRoute = currentRoute.getParent();
    }
    return null;
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

  setupRoute = function(ancestorPath, newPath) {
    var recur;
    return (recur = function(currentPath, continuation) {
      if (currentPath.isEqual(ancestorPath)) {
        return continuation();
      } else {
        return recur(currentPath.getParent(), function() {
          var bindings, context, setup, _ref;
          if (currentPath.node.routeSettings == null) return continuation();
          bindings = currentPath.getBindings();
          _ref = currentPath.node.routeSettings, context = _ref.context, setup = _ref.setup;
          if (setup.length === 2) {
            return setup.call(context, bindings, function() {
              return continuation();
            });
          } else {
            setup.call(context, bindings);
            return continuation();
          }
        });
      }
    })(newPath, function() {
      var load, setup, _ref;
      _ref = newPath.node.routeSettings, setup = _ref.setup, load = _ref.load;
      if (setup !== load) return loadRoute(newPath);
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

  loadRoute = function(routePath) {
    var context, load, _ref;
    _ref = routePath.node.routeSettings, context = _ref.context, load = _ref.load;
    return load.call(context, currentParameters);
  };

  /*
  # Method: teardownRoute
  #	Recursively tears down the current route given an ancestor to tear down to.
  #
  # Arguments:
  #	ancestor - The ancestor node to tear down to
  */

  teardownRoute = function(ancestorPath) {
    var recur;
    return (recur = function(currentPath) {
      var bindings, context, teardown, _ref;
      if (!currentPath.isEqual(ancestorPath)) {
        if (currentPath.node.routeSettings == null) {
          return recur(currentPath.getParent());
        }
        bindings = currentPath.getBindings();
        _ref = currentPath.node.routeSettings, context = _ref.context, teardown = _ref.teardown;
        if (teardown.length === 2) {
          return teardown.call(context, bindings, function() {
            return recur(currentPath.getParent());
          });
        } else {
          teardown.call(context, bindings);
          return recur(currentPath.getParent());
        }
      }
    })(currentPath);
  };

  /*
  # Class: Finch
  */

  Finch = {
    debug: true,
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
      return addRoute(routeTreeRoot, pattern, settings);
    },
    /*
    	# Method: Finch.call
    	#
    	# Arguments:
    	#	route - The route to try and call
    */
    call: function(uri) {
      var ancestorPath, bindings, newPath, queryParameters, queryString, _ref;
      if (!isString(uri)) uri = "";
      _ref = uri.split("?", 2), uri = _ref[0], queryString = _ref[1];
      newPath = findRoutePath(uri);
      if (newPath == null) return false;
      queryParameters = parseQueryString(queryString);
      bindings = newPath.getBindings();
      currentParameters = extend(queryParameters, bindings);
      if (newPath.isEqual(currentPath)) {
        loadRoute(currentPath);
      } else {
        ancestorPath = findNearestCommonAncestor(currentPath, newPath);
        teardownRoute(ancestorPath);
        setupRoute(ancestorPath, newPath);
      }
      currentPath = newPath;
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
      teardownRoute(null);
      routeTreeRoot = new RouteTreeNode({
        name: "*"
      });
      currentPath = new RoutePath({
        node: null
      });
      currentParameters = {};
    }
  };

  if (Finch.debug) {
    Finch.private = {
      isObject: isObject,
      isFunction: isFunction,
      isArray: isArray,
      isString: isString,
      isNumber: isNumber,
      trim: trim,
      trimSlashes: trimSlashes,
      startsWith: startsWith,
      endsWith: endsWith,
      contains: contains,
      extend: extend,
      objectsEqual: objectsEqual,
      arraysEqual: arraysEqual,
      NodeType: NodeType,
      RouteSettings: RouteSettings,
      RoutePath: RoutePath,
      RouteTreeNode: RouteTreeNode,
      parseQueryString: parseQueryString,
      getParentRouteString: getParentRouteString,
      getChildRouteString: getChildRouteString,
      splitRouteString: splitRouteString,
      getComponentType: getComponentType,
      getComponentName: getComponentName,
      addRoute: addRoute,
      findRoutePath: findRoutePath,
      findNearestCommonAncestor: findNearestCommonAncestor,
      setupRoute: setupRoute,
      loadRoute: loadRoute,
      teardownRoute: teardownRoute,
      getRouteTreeRoot: function() {
        return routeTreeRoot;
      },
      setupTest: function() {
        Finch.route("foo", (function() {}));
        Finch.route("[foo]/bar", (function() {}));
        Finch.route("[foo/bar]/:id", (function() {}));
        Finch.route("[foo/bar/:id1]/:id2", (function() {}));
        Finch.route("quux", (function() {}));
        window.rp1 = findRoutePath("/foo");
        window.rp2 = findRoutePath("/foo/bar");
        window.rp3a = findRoutePath("/foo/bar/123");
        window.rp4aa = findRoutePath("/foo/bar/123/456");
        window.rp4ab = findRoutePath("/foo/bar/123/789");
        window.rp3b = findRoutePath("/foo/bar/abc");
        window.rp4ba = findRoutePath("/foo/bar/abc/def");
        window.rp4bb = findRoutePath("/foo/bar/abc/ghi");
        return window.rp1x = findRoutePath("/quux");
      }
    };
  }

  this.Finch = Finch;

}).call(this);
