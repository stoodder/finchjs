describe "Finch.UriManager", ->
	describe "extractRouteString", ->
		it "Should return empty string on invalid inputs", ->
			expect( Finch.UriManager.extractRouteString() ).toBe("")
			expect( Finch.UriManager.extractRouteString(null) ).toBe("")
			expect( Finch.UriManager.extractRouteString(123) ).toBe("")
		#END it

		it "Should extract properly without query paramsters", ->
			expect( Finch.UriManager.extractRouteString("foo/bar") ).toBe("foo/bar")
		#END it

		it "Should extract properly with query paramsters", ->
			expect( Finch.UriManager.extractRouteString("foo/bar?hello=world") ).toBe("foo/bar")
		#END it

		it "Should extract with only query parameters", ->
			expect( Finch.UriManager.extractRouteString("?hello=world") ).toBe("")
		#END it

		it "Should trim the string", ->
			expect( Finch.UriManager.extractRouteString("   foo/bar    ?hello=world") ).toBe("foo/bar")
		#END it
	#END describe
#END describe