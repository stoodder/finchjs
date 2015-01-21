describe "Finch.Tree", ->
	beforeEach ->
		@tree = new Finch.Tree()
	#END beforeEach

	describe "parseRouteString", ->
	#END describe

	describe "standardizeRouteString", ->
		it "Should throw properly", ->
			expect( => @tree.standardizeRouteString() ).toThrow(jasmine.any(Finch.Error))
			expect( => @tree.standardizeRouteString(null) ).toThrow(jasmine.any(Finch.Error))
			expect( => @tree.standardizeRouteString(123) ).toThrow(jasmine.any(Finch.Error))
		#END it

		it "Should parse '!' properly", ->
			expect( @tree.standardizeRouteString("!") ).toBe("!")
		#END it

		it "Should parse '' properly", ->
			expect( @tree.standardizeRouteString("") ).toBe("!/")
		#END it

		it "Should parse '/' properly", ->
			expect( @tree.standardizeRouteString("/") ).toBe("!/")
		#END it

		it "Should parse '//' properly", ->
			expect( @tree.standardizeRouteString("//") ).toBe("!//")
		#END it

		it "Should parse '!/' properly", ->
			expect( @tree.standardizeRouteString("!/") ).toBe("!/")
		#END it

		it "Should parse 'foo' properly", ->
			expect( @tree.standardizeRouteString("foo") ).toBe("!//foo")
		#END it

		it "Should parse '/foo' properly", ->
			expect( @tree.standardizeRouteString("/foo") ).toBe("!//foo")
		#END it

		it "Should parse 'foo/' properly", ->
			expect( @tree.standardizeRouteString("foo/") ).toBe("!//foo")
		#END it

		it "Should parse '/foo/' properly", ->
			expect( @tree.standardizeRouteString("/foo/") ).toBe("!//foo")
		#END it

		it "Should parse '!/foo' properly", ->
			expect( @tree.standardizeRouteString("!/foo") ).toBe("!//foo")
		#END it

		it "Should parse '!/foo/' properly", ->
			expect( @tree.standardizeRouteString("!/foo/") ).toBe("!//foo")
		#END it

		it "Should parse '!//foo' properly", ->
			expect( @tree.standardizeRouteString("!//foo") ).toBe("!//foo")
		#END it

		it "Should parse '!//foo/' properly", ->
			expect( @tree.standardizeRouteString("!//foo/") ).toBe("!//foo")
		#END it

		it "Should parse 'foo/bar' properly", ->
			expect( @tree.standardizeRouteString("foo/bar") ).toBe("!//foo/bar")
		#END it

		it "Should parse '/foo/bar' properly", ->
			expect( @tree.standardizeRouteString("/foo/bar") ).toBe("!//foo/bar")
		#END it

		it "Should parse 'foo/bar/' properly", ->
			expect( @tree.standardizeRouteString("foo/bar/") ).toBe("!//foo/bar")
		#END it

		it "Should parse '/foo/bar/' properly", ->
			expect( @tree.standardizeRouteString("/foo/bar/") ).toBe("!//foo/bar")
		#END it

		it "Should parse '!/foo/bar' properly", ->
			expect( @tree.standardizeRouteString("!/foo/bar") ).toBe("!//foo/bar")
		#END it

		it "Should parse '!/foo/bar/' properly", ->
			expect( @tree.standardizeRouteString("!/foo/bar/") ).toBe("!//foo/bar")
		#END it

		it "Should parse '!//foo/bar' properly", ->
			expect( @tree.standardizeRouteString("!//foo/bar") ).toBe("!//foo/bar")
		#END it

		it "Should parse '!//foo/bar/' properly", ->
			expect( @tree.standardizeRouteString("!//foo/bar/") ).toBe("!//foo/bar")
		#END it
	#END describe
#END describe