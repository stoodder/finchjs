(function() {
  describe("Finch.Tree", function() {
    beforeEach(function() {
      return this.tree = new Finch.Tree();
    });
    describe("parseRouteString", function() {});
    describe("extractRouteString", function() {
      it("Should return empty string on invalid inputs", function() {
        expect(this.tree.extractRouteString()).toBe("");
        expect(this.tree.extractRouteString(null)).toBe("");
        return expect(this.tree.extractRouteString(123)).toBe("");
      });
      it("Should extract properly without query paramsters", function() {
        return expect(this.tree.extractRouteString("foo/bar")).toBe("foo/bar");
      });
      it("Should extract properly with query paramsters", function() {
        return expect(this.tree.extractRouteString("foo/bar?hello=world")).toBe("foo/bar");
      });
      it("Should extract with only query parameters", function() {
        return expect(this.tree.extractRouteString("?hello=world")).toBe("");
      });
      return it("Should trim the string", function() {
        return expect(this.tree.extractRouteString("   foo/bar    ?hello=world")).toBe("foo/bar");
      });
    });
    return describe("standardizeRouteString", function() {
      it("Should throw properly", function() {
        expect((function(_this) {
          return function() {
            return _this.tree.standardizeRouteString();
          };
        })(this)).toThrow(jasmine.any(Error));
        expect((function(_this) {
          return function() {
            return _this.tree.standardizeRouteString(null);
          };
        })(this)).toThrow(jasmine.any(Error));
        return expect((function(_this) {
          return function() {
            return _this.tree.standardizeRouteString(123);
          };
        })(this)).toThrow(jasmine.any(Error));
      });
      it("Should parse '!' properly", function() {
        return expect(this.tree.standardizeRouteString("!")).toBe("!");
      });
      it("Should parse '' properly", function() {
        return expect(this.tree.standardizeRouteString("")).toBe("!/");
      });
      it("Should parse '/' properly", function() {
        return expect(this.tree.standardizeRouteString("/")).toBe("!/");
      });
      it("Should parse '//' properly", function() {
        return expect(this.tree.standardizeRouteString("//")).toBe("!//");
      });
      it("Should parse '!/' properly", function() {
        return expect(this.tree.standardizeRouteString("!/")).toBe("!/");
      });
      it("Should parse 'foo' properly", function() {
        return expect(this.tree.standardizeRouteString("foo")).toBe("!//foo");
      });
      it("Should parse '/foo' properly", function() {
        return expect(this.tree.standardizeRouteString("/foo")).toBe("!//foo");
      });
      it("Should parse 'foo/' properly", function() {
        return expect(this.tree.standardizeRouteString("foo/")).toBe("!//foo");
      });
      it("Should parse '/foo/' properly", function() {
        return expect(this.tree.standardizeRouteString("/foo/")).toBe("!//foo");
      });
      it("Should parse '!/foo' properly", function() {
        return expect(this.tree.standardizeRouteString("!/foo")).toBe("!//foo");
      });
      it("Should parse '!/foo/' properly", function() {
        return expect(this.tree.standardizeRouteString("!/foo/")).toBe("!//foo");
      });
      it("Should parse '!//foo' properly", function() {
        return expect(this.tree.standardizeRouteString("!//foo")).toBe("!//foo");
      });
      it("Should parse '!//foo/' properly", function() {
        return expect(this.tree.standardizeRouteString("!//foo/")).toBe("!//foo");
      });
      it("Should parse 'foo/bar' properly", function() {
        return expect(this.tree.standardizeRouteString("foo/bar")).toBe("!//foo/bar");
      });
      it("Should parse '/foo/bar' properly", function() {
        return expect(this.tree.standardizeRouteString("/foo/bar")).toBe("!//foo/bar");
      });
      it("Should parse 'foo/bar/' properly", function() {
        return expect(this.tree.standardizeRouteString("foo/bar/")).toBe("!//foo/bar");
      });
      it("Should parse '/foo/bar/' properly", function() {
        return expect(this.tree.standardizeRouteString("/foo/bar/")).toBe("!//foo/bar");
      });
      it("Should parse '!/foo/bar' properly", function() {
        return expect(this.tree.standardizeRouteString("!/foo/bar")).toBe("!//foo/bar");
      });
      it("Should parse '!/foo/bar/' properly", function() {
        return expect(this.tree.standardizeRouteString("!/foo/bar/")).toBe("!//foo/bar");
      });
      it("Should parse '!//foo/bar' properly", function() {
        return expect(this.tree.standardizeRouteString("!//foo/bar")).toBe("!//foo/bar");
      });
      return it("Should parse '!//foo/bar/' properly", function() {
        return expect(this.tree.standardizeRouteString("!//foo/bar/")).toBe("!//foo/bar");
      });
    });
  });

}).call(this);
