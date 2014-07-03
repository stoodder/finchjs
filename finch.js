/*
	Finch.js - Hierarchical Javascript Routing
	by Rick Allen (stoodder) and Greg Smith (smrq)

	Version 1.0.0
	Full source at https://github.com/stoodder/finchjs
	Copyright (c) 2014 RokkinCat, http://www.rokkincat.com

	MIT License, https://github.com/stoodder/finchjs/blob/master/LICENSE.md
*/
(function() {
  var arrayRemove, arrayUnique, countSubstrings, endsWith, isArray, isBoolean, isEmpty, isFunction, isNaN, isNumber, isObject, isString, startsWith, trim, trimSlashes,
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

  this.Finch = new ((function() {
    function _Class() {}

    _Class.prototype.tree = null;

    _Class.prototype.route = function(route_string, callbacks) {
      var node;
      if (this.tree == null) {
        this.tree = new Finch.Tree();
      }
      node = this.tree.addRoute(route_string);
      node.updateCallbacks(callbacks);
      return this;
    };

    _Class.prototype.call = function(route_string) {
      if (!(this.tree instanceof Finch.Tree)) {
        return this;
      }
      this.tree.callRoute(route_string);
      return this;
    };

    _Class.prototype.reload = function() {};

    _Class.prototype.peek = function() {};

    _Class.prototype.observe = function() {};

    _Class.prototype.abort = function() {};

    _Class.prototype.listen = function() {};

    _Class.prototype.ignore = function() {};

    _Class.prototype.navigate = function() {};

    _Class.prototype.reset = function() {};

    _Class.prototype.on = function() {};

    _Class.prototype.off = function() {};

    _Class.prototype.trigger = function() {};

    return _Class;

  })());

  Finch.Error = (function(_super) {
    __extends(Error, _super);

    function Error() {
      return Error.__super__.constructor.apply(this, arguments);
    }

    Error.prototype.name = "Finch.Error";

    Error.prototype.message = null;

    Error.prototype.stack = function() {
      return Error.__super__.stack.apply(this, arguments);
    };

    Error.prototype.toString = function() {
      return "" + this.name + ": @{message}";
    };

    return Error;

  })(Error);

  Finch.Console = new ((function() {
    function _Class() {}

    _Class.prototype.log = function() {};

    _Class.prototype.error = function() {};

    _Class.prototype.warn = function() {};

    return _Class;

  })());

  Finch.LoadPath = (function() {
    LoadPath.prototype.nodes = null;

    LoadPath.prototype.route_components = null;

    LoadPath.prototype.length = 0;

    LoadPath.prototype.is_traversing = false;

    LoadPath.prototype.current_operation_queue = null;

    LoadPath.prototype.bindings = null;

    function LoadPath(nodes, route_components) {
      var node, _i, _len;
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
    }

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

    LoadPath.prototype.traverseTo = function(target_load_path) {
      var ancestor_node, current_node, end_node, start_node, target_node_chain;
      if (!(target_load_path instanceof Finch.LoadPath)) {
        throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath");
      }
      if (this.current_operation_queue instanceof Finch.OperationQueue) {
        this.current_operation_queue.abort();
      }
      if (this.isEqual(target_load_path)) {
        return this;
      }
      ancestor_node = this.findCommonAncestor(target_load_path);
      start_node = this.nodeAt(this.length - 1);
      end_node = target_load_path.nodeAt(target_load_path.length - 1);
      this.current_operation_queue = new Finch.OperationQueue({
        before_start: (function(_this) {
          return function() {
            console.log(_this.route_components.join("/"), " -> ", target_load_path.route_components.join("/"));
            return _this.is_traversing = true;
          };
        })(this),
        after_finish: (function(_this) {
          return function(did_abort) {
            _this.is_traversing = false;
            _this.current_operation_queue = null;
            console.log(_this.route_components.join("/"));
            return console.log("\n");
          };
        })(this)
      });
      if (start_node instanceof Finch.Node && end_node instanceof Finch.Node) {
        if (start_node.parent === end_node.parent) {
          this.current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.bindings;
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
                return _this.bindings;
              };
            })(this)
          });
        } else {
          this.current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.bindings;
              };
            })(this)
          });
          current_node = start_node;
          while (current_node !== ancestor_node) {
            this.current_operation_queue.appendOperation(Finch.Operation.TEARDOWN, current_node, {
              setup_params: (function(_this) {
                return function(action, node) {
                  return _this.bindings;
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
                  return _this.bindings;
                };
              })(this)
            });
          }
          this.current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.bindings;
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
                return _this.bindings;
              };
            })(this)
          });
        }
        this.current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
          setup_params: (function(_this) {
            return function(action, node) {
              return _this.bindings;
            };
          })(this)
        });
      } else if (start_node instanceof Finch.Node) {
        this.current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
          setup_params: (function(_this) {
            return function(action, node) {
              return _this.bindings;
            };
          })(this)
        });
        current_node = start_node;
        while (current_node !== ancestor_node) {
          this.current_operation_queue.appendOperation(Finch.Operation.TEARDOWN, current_node, {
            setup_params: (function(_this) {
              return function(action, node) {
                return _this.bindings;
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

    LoadPath.prototype.isEqual = function(target_load_path) {
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

    Node.prototype.setup_callback = null;

    Node.prototype.load_callback = null;

    Node.prototype.unload_callback = null;

    Node.prototype.teardown_callback = null;

    function Node(name, parent) {
      this.name = name;
      this.type = Finch.Node.resolveType(this.name);
      this.parent = parent != null ? parent : null;
      this.params = {};
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

    Node.prototype.updateCallbacks = function(callbacks) {
      if (!isObject(callbacks)) {
        return this;
      }
      if (isFunction(callbacks.setup)) {
        this.setup_callback = callbacks.setup;
      }
      if (isFunction(callbacks.load)) {
        this.load_callback = callbacks.load;
      }
      if (isFunction(callbacks.unload)) {
        this.unload_callback = callbacks.unload;
      }
      if (isFunction(callbacks.teardown)) {
        this.teardown_callback = callbacks.teardown;
      }
      return this;
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

    return Node;

  })();

  Finch.NotFoundError = (function(_super) {
    __extends(NotFoundError, _super);

    function NotFoundError() {
      return NotFoundError.__super__.constructor.apply(this, arguments);
    }

    NotFoundError.prototype.name = "Finch.NotFoundError";

    return NotFoundError;

  })(Finch.Error);

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

    Operation.prototype.execute = function(callback) {
      var continuation, method, params;
      method = (function() {
        switch (this.action) {
          case Finch.Operation.SETUP:
            return this.node.setup_callback;
          case Finch.Operation.LOAD:
            return this.node.load_callback;
          case Finch.Operation.UNLOAD:
            return this.node.unload_callback;
          case Finch.Operation.TEARDOWN:
            return this.node.teardown_callback;
          default:
            return function() {};
        }
      }).call(this);
      if (!isFunction(method)) {
        method = (function() {});
      }
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
      if (method.length === 2) {
        method.call(this.node, params, continuation);
      } else {
        method.call(this.node, params);
        continuation();
      }
      return this;
    };

    return Operation;

  })();

  Finch.OperationQueue = (function() {
    OperationQueue.prototype.queue = [];

    OperationQueue.prototype.before_start = null;

    OperationQueue.prototype.after_finish = null;

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
    }

    OperationQueue.prototype.appendOperation = function(action, node, step_callback) {
      var operation;
      operation = new Finch.Operation(action, node, step_callback);
      this.queue.push(operation);
      return operation;
    };

    OperationQueue.prototype.execute = function() {
      var recurse;
      this.before_start();
      (recurse = (function(_this) {
        return function() {
          var operation;
          operation = _this.queue.shift();
          if (operation instanceof Finch.Operation) {
            return operation.execute(recurse);
          } else {
            return _this.after_finish(false);
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
      return this;
    };

    return OperationQueue;

  })();

  Finch.ParsedRouteString = (function() {
    ParsedRouteString.prototype.components = null;

    ParsedRouteString.prototype.parent_components = null;

    function ParsedRouteString(components, parent_components) {
      var i, parent_component, _i, _len;
      if (!isArray(components)) {
        throw new Finch.Error("components must be an Array");
      }
      if (!isArray(parent_components)) {
        parent_components = [];
      }
      for (i = _i = 0, _len = parent_components.length; _i < _len; i = ++_i) {
        parent_component = parent_components[i];
        if (components[i] !== parent_component) {
          throw new Finch.Error("Parent components does not match the components");
        }
      }
      this.components = components;
      this.parent_components = parent_components;
    }

    return ParsedRouteString;

  })();

  Finch.Tree = (function() {
    Tree.prototype.root_node = null;

    Tree.prototype.active_node = null;

    Tree.prototype.active_operation_queue = null;

    Tree.prototype.load_path = null;

    function Tree() {
      this.root_node = new Finch.Node("!");
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
      route_string = this.extractRouteString(route_string);
      route_components = this.splitRouteString(route_string);
      parent_route_string = this.extractRouteString(parent_route_string);
      parent_route_components = this.splitRouteString(parent_route_string);
      return new Finch.ParsedRouteString(route_components, parent_route_components);
    };

    Tree.prototype.extractRouteString = function(route_string) {
      if (route_string == null) {
        return "!";
      }
      route_string = route_string.split("?")[0];
      route_string = trim(route_string.toString());
      route_string = trimSlashes(route_string);
      if (route_string.length === 0) {
        route_string = "";
      }
      if (!startsWith(route_string, "!")) {
        route_string = "!/" + route_string;
      }
      return route_string;
    };

    Tree.prototype.extractQueryParameters = function(route_string) {
      var key, piece, query_params, query_params_string, value, _i, _len, _ref, _ref1;
      if (!isString(route_string)) {
        return {};
      }
      query_params_string = route_string.split("?", 2)[1];
      if (!isString(query_params_string)) {
        return {};
      }
      query_params = {};
      _ref = query_params_string.split("&");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        piece = _ref[_i];
        _ref1 = piece.split("=", 2), key = _ref1[0], value = _ref1[1];
        query_params[key] = value;
      }
      return query_params;
    };

    Tree.prototype.splitRouteString = function(route_string) {
      var piece, pieces;
      if (!isString(route_string)) {
        return [];
      }
      pieces = route_string.split("/");
      pieces = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = pieces.length; _i < _len; _i++) {
          piece = pieces[_i];
          _results.push(trim(piece));
        }
        return _results;
      })();
      return pieces;
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
      return current_node;
    };

    Tree.prototype.callRoute = function(route_string) {
      var params, route_components, target_load_path;
      if (!isString(route_string)) {
        throw new Finch.Error("route_string must be a String");
      }
      params = this.extractQueryParameters(route_string);
      route_string = this.extractRouteString(route_string);
      route_components = this.splitRouteString(route_string);
      target_load_path = this.createLoadPath(route_components);
      this.load_path.traverseTo(target_load_path);
      return this;
    };

    Tree.prototype.createLoadPath = function(route_components) {
      var current_node, nodes, route_component, _i, _len;
      if (!isArray(route_components)) {
        throw new Finch.Error("route_components must be an Array");
      }
      if (route_components[0] !== "!") {
        throw new Finch.Error("Routes must start with the root '!' node");
      }
      current_node = null;
      nodes = [];
      for (_i = 0, _len = route_components.length; _i < _len; _i++) {
        route_component = route_components[_i];
        if (!(current_node instanceof Finch.Node)) {
          current_node = this.root_node;
        } else {
          current_node = current_node.findMatchingChildNode(route_component);
        }
        if (!(current_node instanceof Finch.Node)) {
          throw new Finch.NotFoundError("Could not resolve the route '" + (route_components.join('/')) + "' at '" + route_component + "'");
        }
        nodes.push(current_node);
      }
      return new Finch.LoadPath(nodes, route_components);
    };

    return Tree;

  })();

}).call(this);
