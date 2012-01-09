(function() {
  var Finch, assignedRoutes, endsWith, extend, getParentRoute, isArray, isFunction, isObject, isString, leftTrim, rightTrim, standardizeRoute, startsWith, stripBrackets, trim;

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
  #
  */

  standardizeRoute = function(route) {
    if (!isString(route)) return "";
    route = trim(route);
    if (startsWith(route, "/")) route = route.slice(1);
    if (endsWith(route, "/")) route = route.slice(0, route.length - 1);
    return route;
  };

  /*
  #
  */

  stripBrackets = function(route) {
    var closingBracketIndex;
    if (!isString(route)) route = "";
    route = trim(route);
    if (startsWith(route, "[")) {
      closingBracketIndex = route.indexOf("]");
      if (closingBracketIndex > 1) {
        route = route.slice(1, closingBracketIndex) + route.slice(closingBracketIndex + 1);
      } else {
        route = route.slice(Math.max(1, closingBracketIndex + 1));
      }
    }
    return route;
  };

  /*
  #
  */

  getParentRoute = function(route) {
    var closingBracketIndex, parentRoute;
    if (!isString(route)) route = "";
    parentRoute = null;
    route = trim(route);
    if (startsWith(route, "[")) {
      closingBracketIndex = route.indexOf("]");
      if (closingBracketIndex > 1) {
        parentRoute = route.slice(1, closingBracketIndex);
      }
    }
    return parentRoute;
  };

  /*
  #
  */

  Finch = {
    /*
    	#
    */
    route: function(route, callback) {
      var parentRoute;
      if (!isString(route)) route = "";
      if (!isFunction(callback)) callback = (function() {});
      route = trim(route);
      parentRoute = getParentRoute(route);
      route = stripBrackets(route);
      route = standardizeRoute(route);
      parentRoute = standardizeRoute(parentRoute);
      return assignedRoutes[route] = function(params) {
        Finch.call(parentRoute, params);
        return callback(params);
      };
    },
    /*
    	#
    */
    call: function(route, parameters) {
      var callback, pattern;
      if (!isString(route)) route = "";
      if (!isObject(parameters)) parameters = {};
      route = standardizeRoute(route);
      if (assignedRoutes[route]) {
        callback = assignedRoutes[route];
        extend(parameters, Finch.getParameters(pattern, route));
        if (isFunction(callback)) callback(parameters);
        return true;
      }
      for (pattern in assignedRoutes) {
        callback = assignedRoutes[pattern];
        if (Finch.match(pattern, route)) {
          extend(parameters, Finch.getParameters(pattern, route));
          if (isFunction(callback)) callback(parameters);
          return true;
        }
      }
      return false;
    },
    /*
    	#
    */
    match: function(pattern, route) {
      var index, patternPiece, patternSplit, routeSplit;
      if (!isString(route)) route = "";
      if (!isString(pattern)) pattern = "";
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
    /*
    	#
    */
    getParameters: function(pattern, route) {
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
    }
  };

  this.Finch = Finch;

}).call(this);
