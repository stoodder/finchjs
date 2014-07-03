(function() {
  describe("Finch.RouteNode", function() {
    return describe("Instance Methods", function() {
      describe("findOrCreateNode", function() {
        var child_literal_one, child_literal_two, child_variable, great_great_grandchild_literal, great_great_grandchild_variable, node, settings;
        node = new Finch.RouteNode("!");
        child_literal_one = null;
        child_literal_two = null;
        child_variable = null;
        great_great_grandchild_literal = null;
        great_great_grandchild_variable = null;
        settings = {};
        beforeEach(function() {
          return sinonSpyOn(Finch.RouteNode.prototype, "updateSettings");
        });
        it("Should add a child literal properly", function() {
          child_literal_one = node.findOrCreateNode(["hello"], settings);
          expect(node.literal_children.length).toBe(1);
          expect(node.literal_children).toEqual([child_literal_one]);
          expect(child_literal_one.parent_node).toBe(node);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOnce();
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOn(child_literal_one);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledWith(settings);
          return expect(child_literal_one).toEqual(jasmine.any(Finch.RouteNode));
        });
        it("Should add a second child literal properly", function() {
          child_literal_two = node.findOrCreateNode(["foo"], settings);
          expect(node.literal_children.length).toBe(2);
          expect(node.literal_children).toEqual([child_literal_one, child_literal_two]);
          expect(child_literal_two.parent_node).toBe(node);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOnce();
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOn(child_literal_two);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledWith(settings);
          return expect(child_literal_two).toEqual(jasmine.any(Finch.RouteNode));
        });
        it("Should add a second child literal properly", function() {
          child_variable = node.findOrCreateNode([":free"], settings);
          expect(node.variable_child).toBe(child_variable);
          expect(child_variable.parent_node).toBe(node);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOnce();
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOn(child_variable);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledWith(settings);
          return expect(child_variable).toEqual(jasmine.any(Finch.RouteNode));
        });
        it("Should find existing nodes", function() {
          expect(node.findOrCreateNode(["hello"])).toBe(child_literal_one);
          expect(node.findOrCreateNode(["foo"])).toBe(child_literal_two);
          expect(node.findOrCreateNode([":free"])).toBe(child_variable);
          return expect(Finch.RouteNode.prototype.updateSettings).not.toHaveBeenCalledOnce();
        });
        it("Should add a great great grand child literal properly", function() {
          great_great_grandchild_literal = node.findOrCreateNode(["hello", "world", "you", "rock"], settings);
          expect(great_great_grandchild_literal.name).toBe("rock");
          expect(great_great_grandchild_literal.parent_node.name).toBe("you");
          expect(great_great_grandchild_literal.parent_node.parent_node.name).toBe("world");
          expect(great_great_grandchild_literal.parent_node.parent_node.parent_node.name).toBe("hello");
          expect(great_great_grandchild_literal.parent_node.parent_node.parent_node.parent_node).toBe(node);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOnce();
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOn(great_great_grandchild_literal);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledWith(settings);
          return expect(great_great_grandchild_literal).toEqual(jasmine.any(Finch.RouteNode));
        });
        it("Should add a great great grand child literal properly", function() {
          great_great_grandchild_variable = node.findOrCreateNode([":free", "bird", ":rock", ":classics"], settings);
          expect(great_great_grandchild_variable.name).toBe(":classics");
          expect(great_great_grandchild_variable.parent_node.name).toBe(":rock");
          expect(great_great_grandchild_variable.parent_node.parent_node.name).toBe("bird");
          expect(great_great_grandchild_variable.parent_node.parent_node.parent_node.name).toBe(":free");
          expect(great_great_grandchild_variable.parent_node.parent_node.parent_node.parent_node).toBe(node);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOnce();
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledOn(great_great_grandchild_variable);
          expect(Finch.RouteNode.prototype.updateSettings).toHaveBeenCalledWith(settings);
          return expect(great_great_grandchild_variable).toEqual(jasmine.any(Finch.RouteNode));
        });
        return it("Should find existing great great grand children", function() {
          expect(node.findOrCreateNode(["hello", "world", "you", "rock"])).toBe(great_great_grandchild_literal);
          expect(node.findOrCreateNode([":foo", "bird", ":rock", ":classics"])).toBe(great_great_grandchild_variable);
          return expect(Finch.RouteNode.prototype.updateSettings).not.toHaveBeenCalledOnce();
        });
      });
      return describe("toString", function() {});
    });
  });

  describe("Finch.RouteTree", function() {
    describe("constructor", function() {});
    describe("Static Methods", function() {
      describe("_standardizeRouteString", function() {
        var tree;
        tree = new Finch.RouteTree;
        it("Should work properly without a parent", function() {
          expect(Finch.RouteTree._standardizeRouteString("!")).toEqual({
            parent_route_string: null,
            route_string: "!"
          });
          expect(Finch.RouteTree._standardizeRouteString("/!/")).toEqual({
            parent_route_string: null,
            route_string: "!/"
          });
          expect(Finch.RouteTree._standardizeRouteString("hello/world")).toEqual({
            parent_route_string: null,
            route_string: "!/hello/world/"
          });
          expect(Finch.RouteTree._standardizeRouteString("/hello/world/")).toEqual({
            parent_route_string: null,
            route_string: "!/hello/world/"
          });
          expect(Finch.RouteTree._standardizeRouteString("!/hello/world")).toEqual({
            parent_route_string: null,
            route_string: "!/hello/world/"
          });
          return expect(Finch.RouteTree._standardizeRouteString("/!/hello/world/")).toEqual({
            parent_route_string: null,
            route_string: "!/hello/world/"
          });
        });
        return it("Should work properly with a parent", function() {
          expect(Finch.RouteTree._standardizeRouteString("[!]")).toEqual({
            parent_route_string: "!",
            route_string: "!/"
          });
          expect(Finch.RouteTree._standardizeRouteString("[!]/")).toEqual({
            parent_route_string: "!",
            route_string: "!/"
          });
          expect(Finch.RouteTree._standardizeRouteString("/[!/]")).toEqual({
            parent_route_string: "!",
            route_string: "!/"
          });
          expect(Finch.RouteTree._standardizeRouteString("[hello]/world")).toEqual({
            parent_route_string: "!/hello",
            route_string: "!/hello/world/"
          });
          expect(Finch.RouteTree._standardizeRouteString("[/hello/]world/")).toEqual({
            parent_route_string: "!/hello",
            route_string: "!/hello/world/"
          });
          expect(Finch.RouteTree._standardizeRouteString("[!/hello]/world")).toEqual({
            parent_route_string: "!/hello",
            route_string: "!/hello/world/"
          });
          return expect(Finch.RouteTree._standardizeRouteString("[/!/hello]/world/")).toEqual({
            parent_route_string: "!/hello",
            route_string: "!/hello/world/"
          });
        });
      });
      return describe("_splitRoute", function() {
        var tree;
        tree = new Finch.RouteTree;
        return it("Should work properly", function() {
          expect(Finch.RouteTree._splitRoute("!/hello/:world")).toEqual(["!", "hello", ":world"]);
          expect(Finch.RouteTree._splitRoute("/!/hello/:world/")).toEqual(["", "!", "hello", ":world", ""]);
          expect(Finch.RouteTree._splitRoute("!")).toEqual(["!"]);
          expect(Finch.RouteTree._splitRoute("")).toEqual([]);
          return expect(Finch.RouteTree._splitRoute("/")).toEqual(["", ""]);
        });
      });
    });
    return describe("Instance Methods", function() {
      return describe("addRoute", function() {});
    });
  });

}).call(this);
