describe "Finch", ->
	afterEach ->
		Finch.reset()
	#END afterEach

	it "Should be able to handle trivial routing", ->
		Finch.route "foo/bar", foo_bar = sinon.spy()
		Finch.route "baz/quux", baz_quux = sinon.spy()

		# Test routes

		Finch.call "/foo/bar"

		expect( foo_bar ).toHaveBeenCalledOnce()

		Finch.call "/baz/quux"

		expect( baz_quux ).toHaveBeenCalledOnce()
	#END it

	it "Should handle simple hierarchical routing", ->
		Finch.route "foo",          	foo = sinon.spy()
		Finch.route "[foo]/bar",    	foo_bar = sinon.spy()
		Finch.route "[foo/bar]/:id",	foo_bar_id = sinon.spy()
		Finch.route "[foo]/baz",    	foo_baz = sinon.spy()
		Finch.route "[foo/baz]/:id",	foo_baz_id = sinon.spy()
		Finch.route "quux",         	quux = sinon.spy()
		Finch.route "[quux]/:id",   	quux_id = sinon.spy()

		# Test routes

		Finch.call "/foo/bar"

		expect( foo ).toHaveBeenCalledOnce()
		expect( foo ).toHaveBeenCalledWith({})
		expect( foo_bar ).toHaveBeenCalledOnce()
		expect( foo_bar ).toHaveBeenCalledWith({})
		expect( foo ).toHaveBeenCalledBefore(foo_bar)

		foo.reset()
		foo_bar.reset()

		Finch.call "/foo/bar/123"

		expect( foo ).not.toHaveBeenCalled()
		expect( foo_bar ).not.toHaveBeenCalled()
		expect( foo_bar_id ).toHaveBeenCalledOnce()
		expect( foo_bar_id ).toHaveBeenCalledWith({ id: "123" })
		foo_bar_id.reset()

		Finch.call "/foo/bar/123"

		expect( foo ).not.toHaveBeenCalled()
		expect( foo_bar ).not.toHaveBeenCalled()
		expect( foo_bar_id ).not.toHaveBeenCalled()

		Finch.call "/foo/bar/123?x=Hello&y=World"

		expect( foo ).not.toHaveBeenCalled()
		expect( foo_bar ).not.toHaveBeenCalled()
		expect( foo_bar_id ).not.toHaveBeenCalled()

		Finch.call "/foo/baz/456"

		expect( foo ).not.toHaveBeenCalled()
		expect( foo_baz ).toHaveBeenCalledOnce()
		expect( foo_baz_id ).toHaveBeenCalledOnce()
		expect( foo_baz ).toHaveBeenCalledBefore( foo_baz_id )
		expect( foo_baz_id ).toHaveBeenCalledWith({ id: "456" })
		foo_baz.reset()
		foo_baz_id.reset()

		Finch.call "/quux/789?band=Sunn O)))&genre=Post-Progressive Fridgecore"

		expect( quux ).toHaveBeenCalledOnce()
		expect( quux_id ).toHaveBeenCalledOnce()
		expect( quux ).toHaveBeenCalledBefore(quux_id)
		expect( quux_id ).toHaveBeenCalledWith({ id: "789" })
	#END it

	it "Should do more hierarchical routing", sinon.test ->
		Finch.route "foo",           	foo = sinon.spy()
		Finch.route "[foo]/bar/baz", 	foo_bar_baz = sinon.spy()
		Finch.route "foo/bar",       	foo_bar = sinon.spy()
		Finch.route "[foo/bar]/quux",	foo_bar_quux = sinon.spy()

		# Test routes

		Finch.call "/foo/bar/baz"

		expect( foo ).toHaveBeenCalledOnce()
		expect( foo_bar_baz ).toHaveBeenCalledOnce()
		expect( foo ).toHaveBeenCalledBefore(foo_bar_baz)
		expect( foo_bar ).not.toHaveBeenCalled()
		foo.reset()
		foo_bar_baz.reset()

		Finch.call "/foo/bar/quux"
		expect( foo_bar ).toHaveBeenCalledOnce()
		expect( foo_bar_quux ).toHaveBeenCalledOnce()
		expect( foo_bar ).toHaveBeenCalledBefore( foo_bar_quux )
		expect( foo ).not.toHaveBeenCalled()
	#END it
#END describe