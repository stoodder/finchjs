/*
	Finch.js - Hierarchical Javascript Routing
	by Rick Allen (stoodder) and Greg Smith (smrq)

	Version 1.0.0
	Full source at https://github.com/stoodder/finchjs
	Copyright (c) 2014 RokkinCat, http://www.rokkincat.com

	MIT License, https://github.com/stoodder/finchjs/blob/master/LICENSE.md
*/
(function() {
  var Finch, arrayRemove, arrayUnique, countSubstrings, endsWith, isArray, isBoolean, isEmpty, isFunction, isNaN, isNumber, isObject, isString, startsWith, trim, trimSlashes,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  arrayUnique = function(arr) {
    var key, obj, value, _i, _len;
    obj = {};
    for (_i = 0, _len = arr.length; _i < _len; _i++) {
      key = arr[_i];
      obj[key] = true;
    }
    return (function() {
      var _results;
      _results = [];
      for (key in obj) {
        value = obj[key];
        _results.push(key);
      }
      return _results;
    })();
  };

  arrayRemove = function(arr, items) {
    var item, _i, _item, _len;
    if (!isArray(arr)) {
      return [];
    }
    if (!isArray(items)) {
      items = [items];
    }
    for (_i = 0, _len = items.length; _i < _len; _i++) {
      item = items[_i];
      arr = (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = arr.length; _j < _len1; _j++) {
          _item = arr[_j];
          if (_item !== item) {
            _results.push(_item);
          }
        }
        return _results;
      })();
    }
    return arr;
  };

  isObject = function(object) {
    return (object != null) && Object.prototype.toString.call(object) === "[object Object]";
  };

  isFunction = function(object) {
    return (object != null) && Object.prototype.toString.call(object) === "[object Function]";
  };

  isBoolean = function(object) {
    return (object != null) && Object.prototype.toString.call(object) === "[object Boolean]";
  };

  isArray = function(object) {
    return (object != null) && Object.prototype.toString.call(object) === "[object Array]";
  };

  isString = function(object) {
    return (object != null) && Object.prototype.toString.call(object) === "[object String]";
  };

  isNumber = function(object) {
    return (object != null) && Object.prototype.toString.call(object) === "[object Number]";
  };

  isNaN = function(object) {
    return isNumber(object) && object !== object;
  };

  isEmpty = function(object) {
    var key, value;
    if (object == null) {
      return true;
    } else if (isString(object)) {
      return trim(object).length === 0;
    } else if (isArray(object)) {
      return object.length === 0;
    } else if (isObject(object)) {
      for (key in object) {
        value = object[key];
        return false;
      }
      return true;
    }
    return false;
  };

  if (String.prototype.trim) {
    trim = function(str) {
      return String.prototype.trim.call(str);
    };
  } else {
    trim = function(str) {
      return str.replace(/^\s+/, '').replace(/\s+$/, '');
    };
  }

  trimSlashes = function(str) {
    return str.replace(/^[\\/\s]+/, '').replace(/[\\/\s]+$/, '');
  };

  startsWith = function(haystack, needle) {
    return haystack.indexOf(needle) === 0;
  };

  endsWith = function(haystack, needle) {
    return haystack.lastIndexOf(needle) === haystack.length - 1;
  };

  countSubstrings = function(str, substr) {
    return str.split(substr).length - 1;
  };

  Finch = new ((function() {
    function _Class() {}

    _Class.prototype.tree = null;

    _Class.prototype.__run__ = function(default_return, routine) {
      var exception;
      try {
        return routine.call(this);
      } catch (_error) {
        exception = _error;
        if (exception instanceof Finch.Error) {
          this.trigger(exception.event_name, exception);
        } else {
          throw exception;
        }
      }
      return default_return;
    };

    _Class.prototype.route = function(route_string, callbacks) {
      return this.__run__(this, function() {
        var node;
        if (this.tree == null) {
          this.tree = new Finch.Tree;
        }
        node = this.tree.addRoute(route_string);
        node.setCallbacks(callbacks);
        return this;
      });
    };

    _Class.prototype.call = function(route_string) {
      return this.__run__(this, function() {
        if (this.tree == null) {
          this.tree = new Finch.Tree;
        }
        this.tree.callRoute(route_string);
        return this;
      });
    };

    _Class.prototype.reload = function() {
      return this.__run__(this, function() {
        if (this.tree == null) {
          this.tree = new Finch.Tree;
        }
        this.tree.load_path.reload();
        return this;
      });
    };

    _Class.prototype.peek = function() {
      return this.__run__(null, function() {
        return "";
      });
    };

    _Class.prototype.observe = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.__run__(null, function() {
        var observer;
        observer = (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(Finch.Observer.create, args, function(){});
        if (this.tree == null) {
          this.tree = new Finch.Tree;
        }
        this.tree.load_path.addObserver(observer);
        return observer;
      });
    };

    _Class.prototype.abort = function() {
      return this.__run__(this, function() {
        if (this.tree == null) {
          this.tree = new Finch.Tree;
        }
        this.tree.load_path.abort();
        return this;
      });
    };

    _Class.prototype.listen = function() {
      return this.__run__(false, function() {
        return Finch.UriManager.listen();
      });
    };

    _Class.prototype.ignore = function() {
      return this.__run__(false, function() {
        return Finch.UriManager.ignore();
      });
    };

    _Class.prototype.navigate = function(uri, params, do_update) {
      return this.__run__(this, function() {
        Finch.UriManager.navigate(uri, params, do_update);
        return this;
      });
    };

    _Class.prototype.reset = function() {
      return this.__run__(this, function() {
        if (this.tree == null) {
          this.tree = new Finch.Tree;
        }
        this.tree.load_path.abort();
        this.tree = new Finch.Tree();
        return this;
      });
    };

    _Class.prototype.options = function(key, value) {
      return this.__run__(this, function() {
        var k, v;
        if (isObject(key)) {
          for (k in key) {
            v = key[k];
            this.options(k, v);
          }
          return this;
        }
        switch (key) {
          case 'coerce_types':
          case 'CoerceParameterTypes':
            if (this.tree == null) {
              this.tree = new Finch.Tree;
            }
            this.tree.load_path.coerce_types = value;
        }
        return this;
      });
    };

    _Class.prototype.on = function() {};

    _Class.prototype.off = function() {};

    _Class.prototype.trigger = function() {};

    return _Class;

  })());

  Finch.Error = (function() {
    Error.prototype.name = "Finch.Error";

    Error.prototype.event_name = "error";

    Error.prototype.message = null;

    function Error(message) {
      this.message = message;
    }

    Error.prototype.toString = function() {
      return "" + this.name + ": " + this.message;
    };

    return Error;

  })();

  Finch.LoadPath = (function() {
    LoadPath.prototype.nodes = null;

    LoadPath.prototype.route_components = null;

    LoadPath.prototype.length = 0;

    LoadPath.prototype.is_traversing = false;

    LoadPath.prototype.current_operation_queue = null;

    LoadPath.prototype.bindings = null;

    LoadPath.prototype.observers = null;

    LoadPath.prototype.params = null;

    LoadPath.prototype.coerce_types = false;

    function LoadPath(nodes, route_components, params) {
      var key, node, value, _i, _len;
      if (nodes == null) {
        nodes = [];
      }
      if (route_components == null) {
        route_components = [];
      }
      if (!isArray(nodes)) {
        throw new Finch.Error("nodes must be an Array");
      }
      if (!isArray(route_components)) {
        throw new Finch.Error("route_components must be an Array");
      }
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        node = nodes[_i];
        if (!(node instanceof Finch.Node)) {
          throw new Finch.Error("nodes must be an instanceof Finch.Node");
        }
      }
      if (nodes.length !== route_components.length) {
        throw new Finch.Error("nodes and route_components must have the same lengths");
      }
      this.nodes = nodes;
      this.route_components = route_components;
      this.length = this.nodes.length;
      this.bindings = {};
      this.observers = [];
      if (!isObject(params)) {
        params = {};
      }
      this.params = {};
      for (key in params) {
        value = params[key];
        this.params[key] = value;
      }
    }

    LoadPath.prototype.abort = function() {
      if (this.current_operation_queue instanceof Finch.OperationQueue) {
        this.current_operation_queue.abort();
        this.current_operation_queue = null;
      }
      return this;
    };

    LoadPath.prototype.push = function(node, route_component) {
      var name;
      if (!(node instanceof Finch.Node)) {
        throw new Finch.Error("node must be an instanceof Finch.Node");
      }
      if (!isString(route_component)) {
        throw new Finch.Error("route_component must be a string");
      }
      this.nodes.push(node);
      this.route_components.push(route_component);
      this.observers.push([]);
      this.length++;
      if (node.type === Finch.Node.VARIABLE) {
        name = node.name.slice(1);
        this.bindings[name] = route_component;
      }
      return this;
    };

    LoadPath.prototype.pushUntil = function(target_load_path, target_node) {
      var current_index, end_index, i, node, nodes, route_component, route_components, _i, _len;
      if (!(target_load_path instanceof Finch.LoadPath)) {
        throw new Error("target_load_path must be an instanceof Finch.LoadPath");
      }
      if (!(target_node instanceof Finch.Node)) {
        throw new Error("target_node must be an instanceof Finch.Node");
      }
      current_index = this.length;
      end_index = target_load_path.indexFor(target_node) + 1;
      if (current_index >= end_index) {
        return this;
      }
      nodes = target_load_path.nodes.slice(current_index, end_index);
      route_components = target_load_path.route_components.slice(current_index, end_index);
      for (i = _i = 0, _len = nodes.length; _i < _len; i = ++_i) {
        node = nodes[i];
        route_component = route_components[i];
        this.push(node, route_component);
      }
      return this;
    };

    LoadPath.prototype.pop = function(node) {
      var name, route_component;
      if (!(this.length > 0)) {
        return null;
      }
      node = this.nodes.pop();
      route_component = this.route_components.pop();
      this.observers.pop();
      this.length--;
      if (this.length <= 0) {
        this.bindings = {};
      } else if (node.type === Finch.Node.VARIABLE) {
        name = node.name.slice(1);
        this.bindings[name] = void 0;
        delete this.bindings[name];
      }
      return [node, route_component];
    };

    LoadPath.prototype.popUntil = function(target_node) {
      if (!((target_node === null) || (target_node instanceof Finch.Node))) {
        throw new Finch.Error("target_node must be an instanceof Finch.Node");
      }
      while (this.length > 0 && this.nodes[this.length - 1] !== target_node) {
        this.pop();
      }
      return this;
    };

    LoadPath.prototype.indexFor = function(node) {
      var i, n, _i, _len, _ref;
      if (!(node instanceof Finch.Node)) {
        return -1;
      }
      _ref = this.nodes;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        n = _ref[i];
        if (n === node) {
          return i;
        }
      }
      return -1;
    };

    LoadPath.prototype.nodeAt = function(index) {
      if (!(index >= 0 && index < this.length)) {
        return null;
      }
      return this.nodes[index];
    };

    LoadPath.prototype.prepareParams = function(params) {
      var key, output_params, value, _ref, _ref1;
      this.params = params != null ? params : this.params;
      output_params = {};
      _ref = this.params;
      for (key in _ref) {
        value = _ref[key];
        output_params[key] = value;
      }
      _ref1 = this.bindings;
      for (key in _ref1) {
        value = _ref1[key];
        output_params[key] = value;
      }
      return this.coerceObject(output_params);
    };

    LoadPath.prototype.coerceObject = function(obj) {
      var key, output_obj, value;
      if (!this.coerce_types) {
        return obj;
      }
      output_obj = {};
      for (key in obj) {
        value = obj[key];
        if (value === "true") {
          output_obj[key] = true;
        } else if (value === "false") {
          output_obj[key] = false;
        } else if (/^[0-9]+$/.test(value)) {
          output_obj[key] = parseInt(value);
        } else if (/^[0-9]+\.[0-9]*$/.test(value)) {
          output_obj[key] = parseFloat(value);
        } else {
          output_obj[key] = value;
        }
      }
      return output_obj;
    };

    LoadPath.prototype.createOperationQueue = function() {
      return new Finch.OperationQueue({
        before_start: (function(_this) {
          return function() {
            return _this.is_traversing = true;
          };
        })(this),
        after_finish: (function(_this) {
          return function(did_abort) {
            _this.is_traversing = false;
            _this.current_operation_queue = null;
            if (!did_abort) {
              return _this.notifyObservers();
            }
          };
        })(this)
      });
    };

    LoadPath.prototype.reload = function() {
      var node;
      if (this.length <= 0) {
        return this;
      }
      node = this.nodeAt(this.length - 1);
      if (this.current_operation_queue == null) {
        this.current_operation_queue = this.createOperationQueue();
      }
      this.current_operation_queue.appendOperation(Finch.Operation.UNLOAD, node, {
        setup_params: (function(_this) {
          return function(action, node) {
            return _this.prepareParams();
          };
        })(this)
      });
      this.current_operation_queue.appendOperation(Finch.Operation.LOAD, node, {
        setup_params: (function(_this) {
          return function(action, node) {
            return _this.prepareParams();
          };
        })(this)
      });
      this.current_operation_queue.execute();
      return this;
    };

    LoadPath.prototype.traverseTo = function(target_load_path) {
      var ancestor_node, current_node, end_node, start_node, target_node_chain;
      if (!(target_load_path instanceof Finch.LoadPath)) {
        throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath");
      }
      if (this.routesAreEqual(target_load_path)) {
        if (this.paramsAreEqual(target_load_path)) {
          return this;
        }
        this.params = target_load_path.params;
        if (this.current_operation_queue != null) {
          return this;
        }
        this.notifyObservers();
        return this;
      }
      ancestor_node = this.findCommonAncestor(target_load_path);
      start_node = this.nodeAt(this.length - 1);
      end_node = target_load_path.nodeAt(target_load_path.length - 1);
      if (this.current_operation_queue == null) {
        this.current_operation_queue = this.createOperationQueue();
      }
      if (start_node instanceof Finch.Node && end_node instanceof Finch.Node) {
        if (start_node === end_node) {
          this.current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.prepareParams();
              };
            })(this),
            after_step: (function(_this) {
              return function(action, node) {
                return _this.popUntil(ancestor_node);
              };
            })(this)
          });
          this.current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
            before_step: (function(_this) {
              return function(action, node) {
                return _this.pushUntil(target_load_path, end_node);
              };
            })(this),
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.prepareParams(target_load_path.params);
              };
            })(this)
          });
        } else {
          this.current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.prepareParams();
              };
            })(this)
          });
          current_node = start_node;
          while (current_node !== ancestor_node) {
            this.current_operation_queue.appendOperation(Finch.Operation.TEARDOWN, current_node, {
              setup_params: (function(_this) {
                return function(action, node) {
                  return _this.prepareParams();
                };
              })(this),
              after_step: (function(_this) {
                return function(action, node) {
                  return _this.popUntil(node.parent);
                };
              })(this)
            });
            current_node = current_node.parent;
          }
          target_node_chain = [];
          current_node = end_node;
          while (current_node instanceof Finch.Node && current_node !== ancestor_node) {
            target_node_chain.push(current_node);
            current_node = current_node.parent;
          }
          while (current_node = target_node_chain.pop()) {
            this.current_operation_queue.appendOperation(Finch.Operation.SETUP, current_node, {
              before_step: (function(_this) {
                return function(action, node) {
                  return _this.pushUntil(target_load_path, node);
                };
              })(this),
              setup_params: (function(_this) {
                return function(action, node) {
                  return _this.prepareParams(target_load_path.params);
                };
              })(this)
            });
          }
          this.current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.prepareParams(target_load_path.params);
              };
            })(this)
          });
        }
      } else if (end_node instanceof Finch.Node) {
        target_node_chain = [];
        current_node = end_node;
        while (current_node instanceof Finch.Node && current_node !== ancestor_node) {
          target_node_chain.push(current_node);
          current_node = current_node.parent;
        }
        while (current_node = target_node_chain.pop()) {
          this.current_operation_queue.appendOperation(Finch.Operation.SETUP, current_node, {
            before_step: (function(_this) {
              return function(action, node) {
                return _this.pushUntil(target_load_path, node);
              };
            })(this),
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.prepareParams(target_load_path.params);
              };
            })(this)
          });
        }
        this.current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
          setup_params: (function(_this) {
            return function(action, node) {
              return _this.prepareParams(target_load_path.params);
            };
          })(this)
        });
      } else if (start_node instanceof Finch.Node) {
        this.current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
          setup_params: (function(_this) {
            return function(action, node) {
              return _this.prepareParams();
            };
          })(this)
        });
        current_node = start_node;
        while (current_node !== ancestor_node) {
          this.current_operation_queue.appendOperation(Finch.Operation.TEARDOWN, current_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.prepareParams();
              };
            })(this),
            after_step: (function(_this) {
              return function(action, node) {
                return _this.popUntil(node.parent);
              };
            })(this)
          });
          current_node = current_node.parent;
        }
      }
      this.current_operation_queue.execute();
      return this;
    };

    LoadPath.prototype.findCommonAncestor = function(target_load_path) {
      var ancestor_node, component_index, current_node, current_node_chain, current_route, i, target_node, target_node_chain, target_route, _i, _len;
      if (!(target_load_path instanceof Finch.LoadPath)) {
        throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath");
      }
      current_node = this.nodes[this.length - 1];
      target_node = target_load_path.nodes[target_load_path.length - 1];
      ancestor_node = null;
      current_node_chain = [];
      while (current_node instanceof Finch.Node) {
        current_node_chain.unshift(current_node);
        current_node = current_node.parent;
      }
      target_node_chain = [];
      while (target_node instanceof Finch.Node) {
        target_node_chain.unshift(target_node);
        target_node = target_node.parent;
      }
      for (i = _i = 0, _len = current_node_chain.length; _i < _len; i = ++_i) {
        current_node = current_node_chain[i];
        target_node = target_node_chain[i];
        if (current_node !== target_node) {
          return ancestor_node;
        }
        component_index = this.indexFor(target_node);
        current_route = this.route_components.slice(0, component_index + 1).join("/");
        target_route = target_load_path.route_components.slice(0, component_index + 1).join("/");
        if (current_route !== target_route) {
          return ancestor_node;
        }
        ancestor_node = current_node;
      }
      return ancestor_node;
    };

    LoadPath.prototype.routesAreEqual = function(target_load_path) {
      var i, route_component, target_route_component, _i, _len, _ref;
      if (!(target_load_path instanceof Finch.LoadPath)) {
        throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath");
      }
      if (this.length !== target_load_path.length) {
        return false;
      }
      _ref = this.route_components;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        route_component = _ref[i];
        target_route_component = target_load_path.route_components[i];
        if (route_component !== target_route_component) {
          return false;
        }
      }
      return true;
    };

    LoadPath.prototype.paramsAreEqual = function(target_load_path) {
      var key, params_length, target_params_length, v, value, _ref, _ref1, _ref2;
      if (!(target_load_path instanceof Finch.LoadPath)) {
        throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath");
      }
      params_length = 0;
      _ref = this.params;
      for (key in _ref) {
        value = _ref[key];
        params_length++;
      }
      target_params_length = 0;
      _ref1 = target_load_path.params;
      for (key in _ref1) {
        value = _ref1[key];
        target_params_length++;
      }
      if (params_length !== target_params_length) {
        return false;
      }
      _ref2 = this.params;
      for (key in _ref2) {
        value = _ref2[key];
        if ((v = target_load_path.params[key]) === void 0) {
          return false;
        }
        if (v !== value) {
          return false;
        }
      }
      return true;
    };

    LoadPath.prototype.addObserver = function(observer) {
      if (!(this.length > 0)) {
        return observer;
      }
      if (!this.nodes[this.length - 1].should_observe) {
        return observer;
      }
      this.observers[this.length - 1].push(observer);
      return observer;
    };

    LoadPath.prototype.notifyObservers = function() {
      var i, new_observer_list, observer, observer_list, _i, _j, _len, _len1, _ref;
      _ref = this.observers;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        observer_list = _ref[i];
        new_observer_list = [];
        for (_j = 0, _len1 = observer_list.length; _j < _len1; _j++) {
          observer = observer_list[_j];
          if (!(!observer.is_disposed)) {
            continue;
          }
          observer.notify(this.coerceObject(this.params));
          new_observer_list.push(observer);
        }
        this.observers[i] = new_observer_list;
      }
      return this;
    };

    LoadPath.prototype.toString = function() {
      var key, params, url, value;
      url = this.route_components.join("/");
      params = ((function() {
        var _ref, _results;
        _ref = this.params;
        _results = [];
        for (key in _ref) {
          value = _ref[key];
          _results.push("" + key + "=" + value);
        }
        return _results;
      }).call(this)).join("&");
      if (params.length > 0) {
        url += "?" + params;
      }
      return url;
    };

    return LoadPath;

  })();

  Finch.Node = (function() {
    var VALID_TYPES, VARIABLE_REGEX;

    Node.LITERAL = "literal";

    Node.VARIABLE = "variable";

    VALID_TYPES = [Node.LITERAL, Node.VARIABLE];

    VARIABLE_REGEX = /^:[a-z0-9_-]+$/i;

    Node.resolveType = function(name) {
      if (new RegExp(VARIABLE_REGEX).test(name)) {
        return Finch.Node.VARIABLE;
      } else {
        return Finch.Node.LITERAL;
      }
    };

    Node.prototype.type = null;

    Node.prototype.name = null;

    Node.prototype.parent = null;

    Node.prototype.params = null;

    Node.prototype.literal_children = null;

    Node.prototype.variable_child = null;

    Node.prototype.should_observe = true;

    Node.prototype.is_endpoint = false;

    Node.prototype.setup_callback = null;

    Node.prototype.load_callback = null;

    Node.prototype.unload_callback = null;

    Node.prototype.teardown_callback = null;

    Node.prototype.generalized_callback = null;

    function Node(name, parent) {
      this.name = name;
      this.type = Finch.Node.resolveType(this.name);
      this.parent = parent != null ? parent : null;
      this.params = {};
      this.context = {};
    }

    Node.prototype.addChildNode = function(node) {
      if (!(node instanceof Finch.Node)) {
        throw new Finch.Error("node must be an instanceof Finch.Node");
      }
      if (node.type === Finch.Node.VARIABLE) {
        this.variable_child = node;
      } else {
        if (this.literal_children == null) {
          this.literal_children = {};
        }
        if (this.literal_children[node.name]) {
          throw new Finch.Error("A node with the name '" + node.name + "' is already a child of the node '" + this.name + "'");
        }
        this.literal_children[node.name] = node;
      }
      return this;
    };

    Node.prototype.findChildNode = function(name) {
      var child, type, _ref;
      if (!isString(name)) {
        throw new Finch.Error("name must be a String");
      }
      type = Finch.Node.resolveType(name);
      if (type === Finch.Node.VARIABLE) {
        child = this.variable_child;
      } else {
        child = (_ref = this.literal_children) != null ? _ref[name] : void 0;
      }
      return child != null ? child : null;
    };

    Node.prototype.findMatchingChildNode = function(component) {
      var _ref, _ref1, _ref2;
      if (!isString(component)) {
        throw new Finch.Error("component must be a String");
      }
      return (_ref = (_ref1 = (_ref2 = this.literal_children) != null ? _ref2[component] : void 0) != null ? _ref1 : this.variable_child) != null ? _ref : null;
    };

    Node.prototype.setParentNode = function(node) {
      if (!(node === null || (node instanceof Finch.Node))) {
        throw new Finch.Error("node must be an instanceof Finch.Node");
      }
      this.parent = node;
      return this;
    };

    Node.prototype.setCallbacks = function(callbacks) {
      if (isFunction(callbacks)) {
        this.generalized_callback = callbacks;
        this.setup_callback = this.load_callback = this.unload_callback = this.teardown_callback = null;
      } else if (isObject(callbacks)) {
        this.generalized_callback = null;
        this.setup_callback = isFunction(callbacks.setup) ? callbacks.setup : (function() {});
        this.load_callback = isFunction(callbacks.load) ? callbacks.load : (function() {});
        this.unload_callback = isFunction(callbacks.unload) ? callbacks.unload : (function() {});
        this.teardown_callback = isFunction(callbacks.teardown) ? callbacks.teardown : (function() {});
      }
      return this;
    };

    Node.prototype.getCallback = function(action, previous_action, previous_node) {
      var method, _method;
      if (isFunction(this.generalized_callback)) {
        if (action === Finch.Operation.UNLOAD) {
          return (function() {});
        }
        if (action === Finch.Operation.TEARDOWN) {
          return (function() {});
        }
        if (previous_action === Finch.Operation.SETUP && previous_node === this) {
          return (function() {});
        }
        method = this.generalized_callback;
        this.should_observe = action === Finch.Operation.SETUP;
      } else {
        method = (function() {
          switch (action) {
            case Finch.Operation.SETUP:
              return this.setup_callback;
            case Finch.Operation.LOAD:
              return this.load_callback;
            case Finch.Operation.UNLOAD:
              return this.unload_callback;
            case Finch.Operation.TEARDOWN:
              return this.teardown_callback;
            default:
              throw new Finch.Error("Invalid action '" + action + "' given");
          }
        }).call(this);
      }
      if (!isFunction(method)) {
        return (function() {});
      }
      _method = method.bind(this.getContext());
      _method.length = method.length;
      return _method;
    };

    Node.prototype.getContext = function() {
      var context;
      context = this.context;
      context.parent = this.parent instanceof Finch.Node ? this.parent.context : null;
      return context;
    };

    Node.prototype.findCommonAncestor = function(target_node) {
      var active_ancestor, active_hierarchy, node, target_ancestor, target_hierarchy, _i, _j, _len, _len1;
      if (!(target_node instanceof Finch.Node)) {
        throw new Finch.Error("target_node must be an instanceof Finch.Node");
      }
      active_hierarchy = [];
      node = this;
      while (node instanceof Finch.Node) {
        active_hierarchy.push(node);
        node = node.parent;
      }
      target_hierarchy = [];
      node = target_node;
      while (node instanceof Finch.Node) {
        target_hierarchy.push(node);
        node = node.parent;
      }
      for (_i = 0, _len = active_hierarchy.length; _i < _len; _i++) {
        active_ancestor = active_hierarchy[_i];
        for (_j = 0, _len1 = target_hierarchy.length; _j < _len1; _j++) {
          target_ancestor = target_hierarchy[_j];
          if (active_ancestor === target_ancestor) {
            return active_ancestor;
          }
        }
      }
      if (!(ancestor instanceof Finch.Node)) {
        throw new Finch.Error("Could not find common ancestor between '" + this.name + "' and '" + target_node.name + "'");
      }
    };

    Node.prototype.toString = function() {
      return this.name;
    };

    return Node;

  })();

  Finch.NotFoundError = (function(_super) {
    __extends(NotFoundError, _super);

    function NotFoundError() {
      return NotFoundError.__super__.constructor.apply(this, arguments);
    }

    NotFoundError.prototype.name = "Finch.NotFoundError";

    NotFoundError.prototype.event_name = "not_found";

    return NotFoundError;

  })(Finch.Error);

  Finch.Observer = (function() {
    Observer.create = function() {
      var callback, key, keys, _callback;
      if (!(arguments.length > 0)) {
        throw new Finch.Error("Invalid arguments given for creating an observer");
      }
      if (isFunction(arguments[0])) {
        return new Finch.Observer(arguments[0]);
      } else if (isArray(arguments[0])) {
        keys = arguments[0], _callback = arguments[1];
      } else if (isString(arguments[0])) {
        keys = Array.prototype.slice.call(arguments, 0, arguments.length - 1);
        _callback = arguments[arguments.length - 1];
      } else {
        throw new Finch.Error("Invalid arguments given for creating an observer");
      }
      for (key in keys) {
        if (!isString(key)) {
          throw new Finch.Error("requested parameters must be string values");
        }
      }
      if (!isFunction(_callback)) {
        throw new Finch.Error("callback must be a function");
      }
      callback = function(accessor) {
        var values, _i, _len;
        values = [];
        for (_i = 0, _len = keys.length; _i < _len; _i++) {
          key = keys[_i];
          values.push(accessor(key));
        }
        return _callback.apply(this, values);
      };
      return new Finch.Observer(callback);
    };

    Observer.prototype.callback = null;

    Observer.prototype.dependencies = null;

    Observer.prototype.is_disposed = false;

    function Observer(callback) {
      if (!isFunction(callback)) {
        throw new Finch.Error("callback must be a Function");
      }
      this.callback = callback;
    }

    Observer.prototype.willMutate = function(params) {
      var key, value, _ref;
      if (!isObject(params)) {
        return false;
      }
      if (!isObject(this.dependencies)) {
        return true;
      }
      _ref = this.dependencies;
      for (key in _ref) {
        value = _ref[key];
        if (value !== params[key]) {
          return true;
        }
      }
      return false;
    };

    Observer.prototype.notify = function(params) {
      var dependencies;
      if (this.is_disposed) {
        return this;
      }
      if (!isObject(params)) {
        return this;
      }
      if (!this.willMutate(params)) {
        return this;
      }
      dependencies = {};
      this.callback.call(this, function(key) {
        return dependencies[key] = params[key];
      });
      this.dependencies = dependencies;
      return this;
    };

    Observer.prototype.dispose = function() {
      this.is_disposed = true;
      this.dependencies = null;
      this.callback = null;
      return this;
    };

    return Observer;

  })();

  Finch.Operation = (function() {
    var VALID_ACTIONS;

    Operation.SETUP = "setup";

    Operation.LOAD = "load";

    Operation.UNLOAD = "unload";

    Operation.TEARDOWN = "teardown";

    VALID_ACTIONS = [Operation.SETUP, Operation.LOAD, Operation.UNLOAD, Operation.TEARDOWN];

    Operation.prototype.action = null;

    Operation.prototype.node = null;

    Operation.prototype.before_step = null;

    Operation.prototype.after_step = null;

    Operation.prototype.setup_params = null;

    function Operation(action, node, callbacks) {
      var after_step, before_step, setup_params, _ref;
      if (__indexOf.call(VALID_ACTIONS, action) < 0) {
        throw new Finch.Error("Invalid action '" + action + "' given");
      }
      if (!(node instanceof Finch.Node)) {
        throw new Finch.Error("node must be an instanceof Finch.Node");
      }
      this.action = action;
      this.node = node;
      _ref = callbacks != null ? callbacks : {}, before_step = _ref.before_step, after_step = _ref.after_step, setup_params = _ref.setup_params;
      this.before_step = isFunction(before_step) ? before_step : (function() {});
      this.after_step = isFunction(after_step) ? after_step : (function() {});
      this.setup_params = isFunction(setup_params) ? setup_params : (function() {
        return {};
      });
    }

    Operation.prototype.execute = function(callback, previous_operation) {
      var continuation, method, params, previous_action, previous_node, _ref, _ref1;
      continuation = (function(_this) {
        return function() {
          _this.after_step(_this.action, _this.node);
          if (isFunction(callback)) {
            return callback(_this.action, _this.node);
          }
        };
      })(this);
      this.before_step(this.action, this.node);
      params = this.setup_params(this.action, this.node);
      if (!isObject(params)) {
        params = {};
      }
      previous_node = (_ref = previous_operation != null ? previous_operation.node : void 0) != null ? _ref : null;
      previous_action = (_ref1 = previous_operation != null ? previous_operation.action : void 0) != null ? _ref1 : null;
      method = this.node.getCallback(this.action, previous_action, previous_node);
      if (method.length === 2) {
        method(params, continuation);
      } else {
        method(params);
        continuation();
      }
      return this;
    };

    return Operation;

  })();

  Finch.OperationQueue = (function() {
    OperationQueue.prototype.queue = null;

    OperationQueue.prototype.before_start = null;

    OperationQueue.prototype.after_finish = null;

    OperationQueue.prototype.is_executing = false;

    function OperationQueue(options) {
      var _ref, _ref1;
      if (options == null) {
        options = {};
      }
      this.before_start = (_ref = options.before_start) != null ? _ref : (function() {});
      this.after_finish = (_ref1 = options.after_finish) != null ? _ref1 : (function() {});
      if (!isFunction(this.before_start)) {
        this.before_start = (function() {});
      }
      if (!isFunction(this.after_finish)) {
        this.after_finish = (function() {});
      }
      this.queue = [];
    }

    OperationQueue.prototype.appendOperation = function(action, node, step_callback) {
      var operation;
      operation = new Finch.Operation(action, node, step_callback);
      this.queue.push(operation);
      return operation;
    };

    OperationQueue.prototype.execute = function() {
      var operation, recurse;
      if (this.is_executing) {
        return this;
      }
      this.is_executing = true;
      this.before_start();
      operation = null;
      (recurse = (function(_this) {
        return function() {
          var previous_operation;
          previous_operation = operation;
          operation = _this.queue.shift();
          if (operation instanceof Finch.Operation) {
            return operation.execute(recurse, previous_operation);
          } else {
            _this.after_finish(false);
            return _this.is_executing = false;
          }
        };
      })(this))();
      return this;
    };

    OperationQueue.prototype.abort = function() {
      this.queue = [];
      this.after_finish(true);
      this.before_start = (function() {});
      this.after_finish = (function() {});
      this.is_executing = false;
      return this;
    };

    return OperationQueue;

  })();

  Finch.ParsedRouteString = (function() {
    ParsedRouteString.prototype.components = null;

    ParsedRouteString.prototype.parent_components = null;

    function ParsedRouteString(components, parent_components) {
      if (!isArray(components)) {
        throw new Finch.Error("components must be an Array");
      }
      if (!isArray(parent_components)) {
        parent_components = [];
      }
      this.components = components;
      this.parent_components = parent_components;
    }

    return ParsedRouteString;

  })();

  Finch.Tree = (function() {
    Tree.prototype.root_node = null;

    Tree.prototype.load_path = null;

    function Tree() {
      this.root_node = new Finch.Node("!");
      this.root_node.is_endpoint = true;
      this.load_path = new Finch.LoadPath();
    }

    Tree.prototype.parseRouteString = function(route_string) {
      var close_bracket_index, has_parent, open_bracket_index, parent_route_components, parent_route_string, route_components;
      if (!isString(route_string)) {
        throw new Finch.Error("route_string must be a String");
      }
      route_string = trim(route_string);
      parent_route_string = null;
      open_bracket_index = route_string.indexOf("[");
      close_bracket_index = route_string.indexOf("]");
      has_parent = (open_bracket_index + close_bracket_index) !== -2;
      if (has_parent) {
        if (open_bracket_index > 0) {
          throw new Finch.Error("Parsing failed on \"" + route_string + "\": [ not at beginning");
        } else if (open_bracket_index === -1) {
          throw new Finch.Error("Parsing failed on \"" + route_string + "\": Missing [");
        } else if (countSubstrings(route_string, "[") > 1) {
          throw new Finch.Error("Parsing failed on \"" + route_string + "\": Too many [");
        }
        if (open_bracket_index === -1) {
          throw new Finch.Error("Parsing failed on \"" + route_string + "\": Missing ]");
        } else if (countSubstrings(route_string, "]") > 1) {
          throw new Finch.Error("Parsing failed on \"" + route_string + "\": Too many ]");
        }
        parent_route_string = route_string.slice(open_bracket_index + 1, close_bracket_index);
        route_string = route_string.replace(/[\[\]]+/gi, "");
      } else {
        parent_route_string = "!";
      }
      route_string = this.standardizeRouteString(route_string);
      route_components = this.createRouteComponents(route_string);
      parent_route_string = this.standardizeRouteString(parent_route_string);
      parent_route_components = this.createRouteComponents(parent_route_string);
      return new Finch.ParsedRouteString(route_components, parent_route_components);
    };

    Tree.prototype.standardizeRouteString = function(route_string) {
      if (!isString(route_string)) {
        throw new Finch.Error("route_string must be a String");
      }
      route_string = Finch.UriManager.extractRouteString(route_string);
      if (route_string === "!") {
        return route_string;
      }
      if (startsWith(route_string, "/")) {
        route_string = "!" + route_string;
      }
      if (!startsWith(route_string, "!")) {
        route_string = "!/" + route_string;
      }
      if (!startsWith(route_string, "!/")) {
        route_string = "!/" + route_string.slice(1);
      }
      if (route_string === "!/") {
        return route_string;
      }
      if (!startsWith(route_string, "!//")) {
        route_string = "!//" + route_string.slice(2);
      }
      if (new RegExp(/^\!\/+$/).test(route_string)) {
        return route_string;
      } else {
        return trimSlashes(route_string);
      }
    };

    Tree.prototype.createRouteComponents = function(route_string) {
      var component, components;
      if (!isString(route_string)) {
        return [];
      }
      components = route_string.split("/");
      components = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = components.length; _i < _len; _i++) {
          component = components[_i];
          _results.push(trim(component));
        }
        return _results;
      })();
      return components;
    };

    Tree.prototype.addRoute = function(route_string) {
      var child_node, current_index, current_node, parent_node, parent_route_components, parsed_route_string, route_component, route_components;
      parsed_route_string = this.parseRouteString(route_string);
      route_components = parsed_route_string.components;
      parent_route_components = parsed_route_string.parent_components;
      if (route_components[0] !== "!") {
        throw new Finch.Error("Routes must start with the root '!' node");
      }
      if (parent_route_components[0] !== "!") {
        throw new Finch.Error("Parent routes must start with the root '!' node");
      }
      current_node = this.root_node;
      parent_node = null;
      current_index = 1;
      while (current_index < route_components.length) {
        route_component = route_components[current_index];
        if (current_index === parent_route_components.length) {
          parent_node = current_node;
        }
        child_node = current_node.findChildNode(route_component);
        if (child_node instanceof Finch.Node) {
          current_node = child_node;
        } else {
          child_node = new Finch.Node(route_component);
          current_node.addChildNode(child_node);
          current_node = child_node;
        }
        current_index++;
      }
      current_node.setParentNode(parent_node);
      current_node.is_endpoint = true;
      return current_node;
    };

    Tree.prototype.callRoute = function(route_string) {
      var params, route_components, target_load_path;
      if (!isString(route_string)) {
        throw new Finch.Error("route_string must be a String");
      }
      params = Finch.UriManager.extractQueryParameters(route_string);
      route_string = this.standardizeRouteString(route_string);
      route_components = this.createRouteComponents(route_string);
      target_load_path = this.createLoadPath(route_components, params);
      this.load_path.traverseTo(target_load_path);
      return this;
    };

    Tree.prototype.createLoadPath = function(route_components, params) {
      var nodes, recurse;
      if (!isArray(route_components)) {
        throw new Finch.Error("route_components must be an Array");
      }
      if (route_components[0] !== "!") {
        throw new Finch.Error("Routes must start with the root '!' node");
      }
      recurse = function(nodes) {
        var child_node, child_route_component, current_node, node, _nodes;
        if (nodes.length >= route_components.length) {
          return (nodes[nodes.length - 1].is_endpoint ? nodes : null);
        }
        current_node = nodes[nodes.length - 1];
        child_route_component = route_components[nodes.length];
        child_node = current_node.findMatchingChildNode(child_route_component);
        if (!(child_node instanceof Finch.Node)) {
          return null;
        }
        _nodes = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = nodes.length; _i < _len; _i++) {
            node = nodes[_i];
            _results.push(node);
          }
          return _results;
        })();
        _nodes.push(child_node);
        _nodes = recurse(_nodes);
        if (_nodes != null) {
          return _nodes;
        }
        child_node = current_node.variable_child;
        if (!(child_node instanceof Finch.Node)) {
          return null;
        }
        _nodes = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = nodes.length; _i < _len; _i++) {
            node = nodes[_i];
            _results.push(node);
          }
          return _results;
        })();
        _nodes.push(child_node);
        return recurse(_nodes);
      };
      nodes = recurse([this.root_node]);
      if (!isArray(nodes)) {
        throw new Finch.NotFoundError("Could not resolve the route '" + (route_components.join('/')) + "'");
      }
      return new Finch.LoadPath(nodes, route_components, params);
    };

    return Tree;

  })();

  Finch.UriManager = (function() {
    function UriManager() {}

    UriManager.is_listening = false;

    UriManager.getHash = function() {
      var hash;
      hash = window.location.hash;
      if (hash.charAt(0) === '#') {
        hash = hash.slice(1);
      }
      return hash;
    };

    UriManager.setHash = function(hash) {
      if (!isString(hash)) {
        hash = "";
      }
      hash = trim(hash);
      if (hash.charAt(0) === '#') {
        hash = hash.slice(1);
      }
      window.location.hash = hash;
      return this;
    };

    UriManager.parseQueryString = function(query_string) {
      var key, param, params, value, _i, _len, _ref, _ref1;
      if (!isString(query_string)) {
        return {};
      }
      params = {};
      _ref = query_string.split("&");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        param = _ref[_i];
        _ref1 = param.split("=", 2), key = _ref1[0], value = _ref1[1];
        params[key] = value;
      }
      return params;
    };

    UriManager.extractRouteString = function(route_string) {
      var _ref;
      if (!isString(route_string)) {
        return "";
      }
      return trim((_ref = route_string.split("?")[0]) != null ? _ref : "");
    };

    UriManager.extractQueryParameters = function(route_string) {
      return this.parseQueryString(route_string.split("?", 2)[1]);
    };

    UriManager.navigate = function(uri, params, do_update) {
      var built_uri, current_params, current_query_string, current_uri, key, piece, slash_index, uri_params, uri_query_string, value, _ref, _ref1, _ref2, _ref3;
      if (isObject(uri)) {
        _ref = [uri, params, null], params = _ref[0], do_update = _ref[1], uri = _ref[2];
      }
      if (isBoolean(params)) {
        _ref1 = [params, null], do_update = _ref1[0], params = _ref1[1];
      }
      _ref2 = this.getHash().split("?", 2), current_uri = _ref2[0], current_query_string = _ref2[1];
      current_params = this.parseQueryString(current_query_string);
      if (!isString(uri)) {
        uri = current_uri;
      }
      if (!isObject(params)) {
        params = {};
      }
      if (!isBoolean(do_update)) {
        do_update = false;
      }
      uri = trim(uri);
      if (uri.charAt(0) === "#") {
        uri = uri.slice(1);
      }
      if (startsWith(uri, "./") || startsWith(uri, "../")) {
        built_uri = current_uri;
        while (startsWith(uri, "./") || startsWith(uri, "../")) {
          slash_index = uri.indexOf("/");
          piece = uri.slice(0, slash_index);
          uri = uri.slice(slash_index + 1);
          if (piece === "..") {
            built_uri = built_uri.slice(0, built_uri.lastIndexOf("/"));
          }
        }
        uri = uri.length > 0 ? "" + built_uri + "/" + uri : built_uri;
      }
      _ref3 = uri.split("?", 2), uri = _ref3[0], uri_query_string = _ref3[1];
      uri_params = this.parseQueryString(uri_query_string);
      for (key in params) {
        value = params[key];
        uri_params[key] = value;
      }
      params = uri_params;
      if (do_update) {
        for (key in current_params) {
          value = current_params[key];
          if (!(key in params)) {
            params[key] = value;
          }
        }
      }
      for (key in params) {
        value = params[key];
        if (value == null) {
          delete params[key];
        }
      }
      uri += "?" + ((function() {
        var _results;
        _results = [];
        for (key in params) {
          value = params[key];
          _results.push("" + key + "=" + value);
        }
        return _results;
      })()).join("&");
      this.setHash(uri);
      return this;
    };

    UriManager.listen_callback = null;

    UriManager.listen_interval = null;

    UriManager.listen = function() {
      var _current_hash;
      if (this.is_listening) {
        return true;
      }
      _current_hash = null;
      this.listen_callback = (function(_this) {
        return function() {
          var hash;
          hash = _this.getHash();
          if (hash === _current_hash) {
            return;
          }
          return Finch.call(_current_hash = hash);
        };
      })(this);
      if ("onhashchange" in window) {
        if (isFunction(window.addEventListener)) {
          window.addEventListener("hashchange", this.listen_callback, true);
          this.is_listening = true;
        } else if (isFunction(window.attachEvent)) {
          window.attachEvent("hashchange", this.listen_callback);
          this.is_listening = true;
        }
      }
      if (!this.is_listening) {
        this.listen_interval = setInterval(this.listen_callback, 33);
        this.is_listening = true;
      }
      this.listen_callback();
      return this.is_listening;
    };

    UriManager.ignore = function() {
      if (!this.is_listening) {
        return true;
      }
      if (this.listen_interval !== null) {
        clearInterval(this.listen_interval);
        this.listen_interval = null;
        this.is_listening = false;
      } else if ("onhashchange" in window) {
        if (isFunction(window.removeEventListener)) {
          window.removeEventListener("hashchange", this.listen_callback, true);
          this.is_listening = false;
          this.listen_callback = null;
        } else if (isFunction(window.detachEvent)) {
          window.detachEvent("hashchange", this.listen_callback);
          this.is_listening = false;
          this.listen_callback = null;
        }
      }
      return !this.is_listening;
    };

    return UriManager;

  })();

  if ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null) {
    module.exports = Finch;
  } else if (((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) && isFunction(define)) {
    define(['Finch'], Finch);
  } else {
    this.Finch = Finch;
  }

}).call(this);
