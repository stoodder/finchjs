describe "Finch.Tree", ->
	beforeEach ->
		@tree = new Finch.Tree()
	#END beforeEach

	describe "parseRouteString", ->
	#END describe

	describe "extractRouteString", ->
		it "Should return empty string on invalid inputs", ->
			expect( @tree.extractRouteString() ).toBe("")
			expect( @tree.extractRouteString(null) ).toBe("")
			expect( @tree.extractRouteString(123) ).toBe("")
		#END it

		it "Should extract properly without query paramsters", ->
			expect( @tree.extractRouteString("foo/bar") ).toBe("foo/bar")
		#END it

		it "Should extract properly with query paramsters", ->
			expect( @tree.extractRouteString("foo/bar?hello=world") ).toBe("foo/bar")
		#END it

		it "Should extract with only query parameters", ->
			expect( @tree.extractRouteString("?hello=world") ).toBe("")
		#END it

		it "Should trim the string", ->
			expect( @tree.extractRouteString("   foo/bar    ?hello=world") ).toBe("foo/bar")
		#END it
	#END describe

	describe "standardizeRouteString", ->
		it "Should throw properly", ->
			expect( => @tree.standardizeRouteString() ).toThrow(jasmine.any(Error))
			expect( => @tree.standardizeRouteString(null) ).toThrow(jasmine.any(Error))
			expect( => @tree.standardizeRouteString(123) ).toThrow(jasmine.any(Error))
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