callbackGroup = () ->
	group = {}
	group.reset = () ->
		for key, value of group when (typeof value.reset is "function")
			value.reset()
		#END for
	return group
#END callbackGroup

describe "Finch", ->
	afterEach ->
		Finch.reset()
	#END afterEach

	describe "Trivial Routing", ->
		it "Should be able to handle trivial routing", ->
			Finch.route "foo/bar", foo_bar = sinon.spy()
			Finch.route "baz/quux", baz_quux = sinon.spy()

			# Test routes

			Finch.call "/foo/bar"

			expect( foo_bar ).toHaveBeenCalledOnce()

			Finch.call "/baz/quux"

			expect( baz_quux ).toHaveBeenCalledOnce()
		#END it
	#END describe

	describe "Hierarchical Routing", ->
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
			expect( quux_id ).toHaveBeenCalledWith({
				id: "789"
				band: "Sunn O)))"
				genre: "Post-Progressive Fridgecore"
			})
		#END it

		it "Should do more hierarchical routing", ->
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

		it "Should do even more hierarchical routing", ->
			Finch.route "foo",      	foo = sinon.spy()
			Finch.route "[foo]/bar",	foo_bar = sinon.spy()

			# Test routes

			Finch.call "/foo"

			expect( foo ).toHaveBeenCalledOnce()
			expect( foo_bar ).not.toHaveBeenCalled()
			foo.reset()
			foo_bar.reset()

			Finch.call "/foo/bar"

			expect( foo ).not.toHaveBeenCalled()
			expect( foo_bar ).toHaveBeenCalledOnce()
			foo.reset()
			foo_bar.reset()

			Finch.call "/foo"

			expect( foo ).toHaveBeenCalledOnce()
			expect( foo_bar ).not.toHaveBeenCalled()
		#END it

		it "Should handle hierarchical routing with /", ->
			Finch.route "/",         	slash = sinon.spy()
			Finch.route "[/]foo",    	foo = sinon.spy()
			Finch.route "[/foo]/bar",	bar = sinon.spy()

			# Test routes

			Finch.call "/foo"

			expect( slash ).toHaveBeenCalledOnce()
			expect( foo ).toHaveBeenCalledOnce()
			expect( bar ).not.toHaveBeenCalled()

			slash.reset()
			foo.reset()
			bar.reset()

			Finch.call "/"
			expect( slash ).toHaveBeenCalledOnce()
			expect( foo ).not.toHaveBeenCalled()
			expect( bar ).not.toHaveBeenCalled()
		#END it
	#END describe

	describe "Routing with setup, load, unload, and teardown", ->
		it "Should handle simple routing with setup, load, and teardown", ->
			cb = callbackGroup()

			Finch.route "/",
				setup:   	cb.setup_slash = sinon.spy()
				load:    	cb.load_slash = sinon.spy()
				teardown:	cb.teardown_slash = sinon.spy()
			Finch.route "/foo",
				setup:   	cb.setup_foo = sinon.spy()
				load:    	cb.load_foo = sinon.spy()
				teardown:	cb.teardown_foo = sinon.spy()
			Finch.route "foo/bar",
				setup:   	cb.setup_foo_bar = sinon.spy()
				load:    	cb.load_foo_bar = sinon.spy()
				teardown:	cb.teardown_foo_bar = sinon.spy()

			# Test routes

			Finch.call "/"

			expect( cb.setup_slash ).toHaveBeenCalledOnce()
			expect( cb.load_slash ).toHaveBeenCalledOnce()
			expect( cb.teardown_slash ).not.toHaveBeenCalled()
			cb.reset()

			Finch.call "/foo"

			expect( cb.setup_slash ).not.toHaveBeenCalled()
			expect( cb.load_slash ).not.toHaveBeenCalled()
			expect( cb.teardown_slash ).toHaveBeenCalledOnce()
			expect( cb.setup_foo ).toHaveBeenCalledOnce()
			expect( cb.load_foo ).toHaveBeenCalledOnce()
			expect( cb.teardown_foo ).not.toHaveBeenCalled()
			cb.reset()

			Finch.call "/foo/bar"

			expect( cb.setup_slash ).not.toHaveBeenCalled()
			expect( cb.load_slash ).not.toHaveBeenCalled()
			expect( cb.teardown_slash ).not.toHaveBeenCalled()
			expect( cb.setup_foo ).not.toHaveBeenCalled()
			expect( cb.load_foo ).not.toHaveBeenCalled()
			expect( cb.teardown_foo ).toHaveBeenCalledOnce()
			expect( cb.setup_foo_bar ).toHaveBeenCalledOnce()
			expect( cb.load_foo_bar ).toHaveBeenCalledOnce()
			expect( cb.teardown_foo_bar ).not.toHaveBeenCalled()
			cb.reset()

			Finch.call "/foo/bar?baz=quux"

			expect( cb.setup_slash ).not.toHaveBeenCalled()
			expect( cb.load_slash ).not.toHaveBeenCalled()
			expect( cb.teardown_slash ).not.toHaveBeenCalled()
			expect( cb.setup_foo ).not.toHaveBeenCalled()
			expect( cb.load_foo ).not.toHaveBeenCalled()
			expect( cb.teardown_foo ).not.toHaveBeenCalled()
			expect( cb.setup_foo_bar ).not.toHaveBeenCalled()
			expect( cb.load_foo_bar ).not.toHaveBeenCalled()
			expect( cb.teardown_foo_bar ).not.toHaveBeenCalled()
			cb.reset()

			Finch.call "/foo/bar?baz=xyzzy"

			expect( cb.setup_slash ).not.toHaveBeenCalled()
			expect( cb.load_slash ).not.toHaveBeenCalled()
			expect( cb.teardown_slash ).not.toHaveBeenCalled()
			expect( cb.setup_foo ).not.toHaveBeenCalled()
			expect( cb.load_foo ).not.toHaveBeenCalled()
			expect( cb.teardown_foo ).not.toHaveBeenCalled()
			expect( cb.setup_foo_bar ).not.toHaveBeenCalled()
			expect( cb.load_foo_bar ).not.toHaveBeenCalled()
			expect( cb.teardown_foo_bar ).not.toHaveBeenCalled()
			cb.reset()
		#END it


		it 'Should test synchronous and asynchronous unload method and context', ->
			cb = callbackGroup()
			cb.home_setup = sinon.spy()
			cb.home_load = sinon.spy()
			cb.home_unload = sinon.spy()
			cb.home_teardown = sinon.spy()

			Finch.route "/home",
				setup: (bindings, next) -> 
					cb.home_setup()
					next()
				load: (bindings, next) ->
					cb.home_load() 
					next()
				unload: (bindings, next) -> 
					cb.home_unload()
					next()
				teardown: (bindings, next) -> 
					cb.home_teardown()
					next()

			cb.home_news_setup = sinon.spy()
			cb.home_news_load = sinon.spy()
			cb.home_news_unload = sinon.spy()
			cb.home_news_teardown = sinon.spy()

			Finch.route "[/home]/news",
				setup: (bindings, next) -> 
					@did_setup = true
					cb.home_news_setup()
					next()
				load: (bindings, next) ->
					@did_load = true
					cb.home_news_load() 
					next()
				unload: (bindings, next) -> 
					@did_unload = true
					cb.home_news_unload(this, next)
				teardown: (bindings, next) -> 
					@did_teardown = true
					cb.home_news_teardown()
					next()

			Finch.route "/foo", cb.foo = sinon.spy()

			Finch.call("/home")
			expect(cb.home_setup).toHaveBeenCalledOnce()
			expect(cb.home_load).toHaveBeenCalledOnce()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()
			expect(cb.foo).not.toHaveBeenCalled()

			expect(cb.home_setup).toHaveBeenCalledBefore(cb.home_load)

			cb.reset()

			Finch.call("/home/news")

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).toHaveBeenCalledOnce()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).toHaveBeenCalledOnce()
			expect(cb.home_news_load).toHaveBeenCalledOnce()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()
			expect(cb.foo).not.toHaveBeenCalled()

			expect(cb.home_unload).toHaveBeenCalledBefore(cb.home_news_setup)
			expect(cb.home_news_setup).toHaveBeenCalledBefore(cb.home_news_load)

			cb.reset()

			Finch.call("/foo")

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).toHaveBeenCalledOnce()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()
			expect(cb.foo).not.toHaveBeenCalled()

			call = cb.home_news_unload.getCall(0)
			call_context = call.args[0]
			call_next = call.args[1]

			expect(call_context.did_setup).toBeDefined()
			expect(call_context.did_load).toBeDefined()
			expect(call_context.did_unload).toBeDefined()
			expect(call_context.did_teardown).not.toBeDefined()
			
			call_next()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).toHaveBeenCalledOnce()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).toHaveBeenCalledOnce()
			expect(cb.home_news_teardown).toHaveBeenCalledOnce()
			expect(cb.foo).toHaveBeenCalledOnce()

			cb.reset()
		#END it
	#END describe

	describe "Routing Context", ->
		it "Should be able to call with a specific context", ->
			Finch.route "foo",
				setup:   	setup_foo = sinon.spy()
				load:    	load_foo = sinon.spy()
				unload:  	unload_foo = sinon.spy()
				teardown:	teardown_foo = sinon.spy()
			Finch.route "bar", boo = sinon.spy()

			# Test routes

			Finch.call "/foo"

			expect(setup_foo).toHaveBeenCalledOnce()
			context = setup_foo.getCall(0).thisValue

			expect(load_foo).toHaveBeenCalledOn(context)

			Finch.call "/bar"
			expect(unload_foo).toHaveBeenCalledOn(context)
			expect(teardown_foo).toHaveBeenCalledOn(context)

			expect(boo).toHaveBeenCalledOnce()
			expect(boo).not.toHaveBeenCalledOn(context)
		#END it

		it "Should handle parent context", ->
			Finch.route "!", ->
				expect(@parent).toBeNull()

			Finch.route "/", ->
				expect(@parent).not.toBeNull()

				@someData = "Free Bird"

			Finch.route "[/]home", ->
				expect(@parent).not.toBeNull()
				expect(@parent.someData).toBe("Free Bird")

				@moreData = "Hello World"

			Finch.route "[/home]/news",
				setup: ->
					expect(@parent).not.toBeNull()
					expect(@parent.moreData).toBe("Hello World")
					expect(@parent.parent.someData).toBe("Free Bird")
				#END setup

				load: ->
					expect(@parent).not.toBeNull()
					expect(@parent.moreData).toBe("Hello World")
					expect(@parent.parent.someData).toBe("Free Bird")
				#END load

				unload: ->
					expect(@parent).not.toBeNull()
					expect(@parent.moreData).toBe("Hello World")
					expect(@parent.parent.someData).toBe("Free Bird")
				#END unload

				teardown: ->
					expect(@parent).not.toBeNull()
					expect(@parent.moreData).toBe("Hello World")
					expect(@parent.parent.someData).toBe("Free Bird")
				#END teardown

			Finch.route "/foo",
				setup: ->
					expect(@parent).not.toBeNull()
					expect(@parent.parent).toBeNull()
				#END setup

				load: ->
					expect(@parent).not.toBeNull()
					expect(@parent.parent).toBeNull()
				#END load

				unload: ->
					expect(@parent).not.toBeNull()
					expect(@parent.parent).toBeNull()
				#END unload

				teardown: ->
					expect(@parent).not.toBeNull()
					expect(@parent.parent).toBeNull()
				#END teardown

			Finch.route "[/]bar",
				setup: ->
					expect(@parent).not.toBeNull()
					expect(@parent.someData).toBe("Free Bird")
				#END setup

				load: ->
					expect(@parent).not.toBeNull()
					expect(@parent.someData).toBe("Free Bird")
				#END load

				unload: ->
					expect(@parent).not.toBeNull()
					expect(@parent.someData).toBe("Free Bird")
				#END unload

				teardown: ->
					expect(@parent).not.toBeNull()
					expect(@parent.someData).toBe("Free Bird")
				#END teardown
			#End Finch.route /bar

			Finch.call("/bar")
			Finch.call("/home/news")
			Finch.call("/foo")
			Finch.call("/home/news")
			Finch.call("/bar")
			Finch.call("/foo")
		#END it

		it "Should handle hierarchical calling with context", ->
			Finch.route "foo",
				setup:   	setup_foo = sinon.spy()
				load:    	load_foo = sinon.spy()
				teardown:	teardown_foo = sinon.spy()
			Finch.route "[foo]/bar",
				setup:   	setup_foo_bar = sinon.spy()
				load:    	load_foo_bar = sinon.spy()
				teardown:	teardown_foo_bar = sinon.spy()
			Finch.route "baz", sinon.spy()

			# Test routes
			Finch.call "/foo"

			expect(setup_foo).toHaveBeenCalledOnce()
			foo_context = setup_foo.getCall(0).thisValue
			expect(load_foo).toHaveBeenCalledOn(foo_context)

			Finch.call "/foo/bar"

			expect(setup_foo_bar).toHaveBeenCalledOnce()
			foo_bar_context = setup_foo_bar.getCall(0).thisValue
			expect(load_foo_bar).toHaveBeenCalledOn(foo_bar_context)

			expect(foo_context).not.toBe(foo_bar_context)

			Finch.call "/baz"

			expect(teardown_foo_bar).toHaveBeenCalledOnce()
			expect(teardown_foo).toHaveBeenCalledOnce()
			expect(teardown_foo_bar).toHaveBeenCalledBefore(teardown_foo)

			expect(teardown_foo_bar).toHaveBeenCalledOn(foo_bar_context)
			expect(teardown_foo).toHaveBeenCalledOn(foo_context)
		#END it

	describe "Reload", ->
		it "Should reload properly", ->
			cb = callbackGroup()
			cb.home_setup = sinon.spy()
			cb.home_load = sinon.spy()
			cb.home_unload = sinon.spy()
			cb.home_teardown = sinon.spy()

			Finch.route "/home",
				setup: (bindings, next) -> 
					cb.home_setup()
					next()
				load: (bindings, next) ->
					cb.home_load() 
					next()
				unload: (bindings, next) -> 
					cb.home_unload()
					next()
				teardown: (bindings, next) -> 
					cb.home_teardown()
					next()

			cb.home_news_setup = sinon.spy()
			cb.home_news_load = sinon.spy()
			cb.home_news_unload = sinon.spy()
			cb.home_news_teardown = sinon.spy()

			Finch.route "[/home]/news",
				setup: (bindings, next) -> 
					@did_setup = true
					cb.home_news_setup(this, next)
				load: (bindings, next) ->
					@did_load = true
					cb.home_news_load(this, next) 
				unload: (bindings, next) -> 
					@did_unload = true
					cb.home_news_unload(this, next)
				teardown: (bindings, next) -> 
					@did_teardown = true
					cb.home_news_teardown()
					next()

			Finch.call("/home")

			expect(cb.home_setup).toHaveBeenCalledOnce()
			expect(cb.home_load).toHaveBeenCalledOnce()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			cb.reset()
			Finch.reload()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).toHaveBeenCalledOnce()
			expect(cb.home_unload).toHaveBeenCalledOnce()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			cb.reset()
			Finch.call("/home/news")

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).toHaveBeenCalledOnce()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).toHaveBeenCalledOnce()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			call = cb.home_news_setup.getCall(0)
			call_context = call.args[0]
			call_next = call.args[1]

			expect(call_context.did_setup).toBeDefined()
			expect(call_context.did_load).not.toBeDefined()
			expect(call_context.did_unload).not.toBeDefined()
			expect(call_context.did_teardown).not.toBeDefined()

			cb.reset()
			Finch.reload()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()
			
			cb.reset()
			call_next()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).toHaveBeenCalledOnce()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			call = cb.home_news_load.getCall(0)
			call_context = call.args[0]
			call_next = call.args[1]

			expect(call_context.did_setup).toBeDefined()
			expect(call_context.did_load).toBeDefined()
			expect(call_context.did_unload).not.toBeDefined()
			expect(call_context.did_teardown).not.toBeDefined()

			cb.reset()
			Finch.reload()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			cb.reset()
			call_next()
			Finch.reload()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).toHaveBeenCalledOnce()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			call = cb.home_news_unload.getCall(0)
			call_context = call.args[0]
			call_next = call.args[1]

			expect(call_context.did_setup).toBeDefined()
			expect(call_context.did_load).toBeDefined()
			expect(call_context.did_unload).toBeDefined()
			expect(call_context.did_teardown).not.toBeDefined()

			cb.reset()
			Finch.reload()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).not.toHaveBeenCalled()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			cb.reset()
			call_next()

			expect(cb.home_setup).not.toHaveBeenCalled()
			expect(cb.home_load).not.toHaveBeenCalled()
			expect(cb.home_unload).not.toHaveBeenCalled()
			expect(cb.home_teardown).not.toHaveBeenCalled()
			expect(cb.home_news_setup).not.toHaveBeenCalled()
			expect(cb.home_news_load).toHaveBeenCalledOnce()
			expect(cb.home_news_unload).not.toHaveBeenCalled()
			expect(cb.home_news_teardown).not.toHaveBeenCalled()

			call = cb.home_news_load.getCall(0)
			call_context = call.args[0]
			call_next = call.args[1]

			expect(call_context.did_setup).toBeDefined()
			expect(call_context.did_load).toBeDefined()
			expect(call_context.did_unload).toBeDefined()
			expect(call_context.did_teardown).not.toBeDefined()
		#END it
	#END describe
	
	describe "Route Call Variations", ->
		it "Should call routes properly", ->
			Finch.reset()
			Finch.route "/", slash = sinon.spy()
			Finch.route "/foo", foo = sinon.spy()
			Finch.route "/foo/bar", foo_bar = sinon.spy()

			Finch.call ""
			expect(slash).toHaveBeenCalledOnce()
			slash.reset()

			Finch.call "/"
			expect(slash).not.toHaveBeenCalled()
			slash.reset()

			Finch.call ""
			expect(slash).not.toHaveBeenCalled()
			slash.reset()

			Finch.call "//"
			expect(slash).not.toHaveBeenCalled()
			slash.reset()

			Finch.call "foo"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).toHaveBeenCalledOnce()
			slash.reset()
			foo.reset()

			Finch.call "/foo"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			slash.reset()
			foo.reset()

			Finch.call "/foo/"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			slash.reset()
			foo.reset()

			Finch.call "foo/"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			slash.reset()
			foo.reset()

			Finch.call "foo/bar"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			expect(foo_bar).toHaveBeenCalledOnce()
			slash.reset()
			foo.reset()
			foo_bar.reset()

			Finch.call "/foo/bar"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			expect(foo_bar).not.toHaveBeenCalled()
			slash.reset()
			foo.reset()
			foo_bar.reset()

			Finch.call "/foo/bar/"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			expect(foo_bar).not.toHaveBeenCalled()
			slash.reset()
			foo.reset()
			foo_bar.reset()

			Finch.call "foo/bar/"
			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			expect(foo_bar).not.toHaveBeenCalled()
			slash.reset()
			foo.reset()
			foo_bar.reset()
		#END it
	#END describe

	describe "Observable Tests", ->
		trivialObservableTest = (fn) ->
			Finch.call "/foo"
			expect(fn).toHaveBeenCalledOnce()
			expect(fn).toHaveBeenCalledWith(undefined, undefined)
			fn.reset()

			Finch.call "/foo?sort=asc"
			expect(fn).toHaveBeenCalledOnce()
			expect(fn).toHaveBeenCalledWith("asc", undefined)
			fn.reset()

			Finch.call "/foo"
			expect(fn).toHaveBeenCalledOnce()
			expect(fn).toHaveBeenCalledWith(undefined, undefined)
			fn.reset()

			Finch.call "/foo?query=unicorn"
			expect(fn).toHaveBeenCalledOnce()
			expect(fn).toHaveBeenCalledWith(undefined, "unicorn")
			fn.reset()

			Finch.call "/foo?query=unicorn&sort=desc"
			expect(fn).toHaveBeenCalledOnce()
			expect(fn).toHaveBeenCalledWith("desc", "unicorn")
			fn.reset()

			Finch.call "/foo?sort=desc&query=unicorn"
			expect(fn).not.toHaveBeenCalled()
			fn.reset()

			Finch.call "/foo"
			expect(fn).toHaveBeenCalledOnce()
			expect(fn).toHaveBeenCalledWith(undefined, undefined)
			fn.reset()

			Finch.call "/foo?Unrelated=Parameter"
			expect(fn).not.toHaveBeenCalled()
		#END trivialObservableTest

		it "Trivial observable test (accessor form)", ->

			fn = sinon.spy()

			Finch.reset().route "foo", (bindings) ->
				Finch.observe (params) ->
					fn(params("sort"), params("query"))

			trivialObservableTest(fn)
		#END it

		it "Trivial observable test (binding array form)", ->

			fn = sinon.spy()

			Finch.reset().route "foo", (bindings) ->
				Finch.observe ["sort", "query"], (sort, query) ->
					fn(sort, query)

			trivialObservableTest(fn)
		#END it

		it "Trivial observable test (binding list form)", ->

			fn = sinon.spy()

			Finch.reset().route "foo", (bindings) ->
				Finch.observe "sort", "query", (sort, query) ->
					fn(sort, query)

			trivialObservableTest(fn)
		#END it

		it "Observable dependency tracking", ->
			bar_on = sinon.spy()
			bar_off = sinon.spy()

			Finch.route "bar", (bindings) ->
				Finch.observe (params) ->
					if params("flag") then bar_on params("on") else bar_off params("off")

			Finch.call("/bar")

			expect(bar_off).toHaveBeenCalledOnce()
			expect(bar_on).not.toHaveBeenCalled()
			expect(bar_off).toHaveBeenCalledWith(undefined)
			bar_off.reset()

			Finch.call("/bar?off=Grue")

			expect(bar_off).toHaveBeenCalledOnce()
			expect(bar_on).not.toHaveBeenCalled()
			expect(bar_off).toHaveBeenCalledWith("Grue")
			bar_off.reset()

			Finch.call("/bar?off=Grue&on=Lantern")

			expect(bar_off).not.toHaveBeenCalled()
			expect(bar_on).not.toHaveBeenCalled()

			Finch.call("/bar?flag=true&off=Grue&on=Lantern")

			expect(bar_off).not.toHaveBeenCalled()
			expect(bar_on).toHaveBeenCalledOnce()
			expect(bar_on).toHaveBeenCalledWith("Lantern")
			bar_on.reset()

			Finch.call("/bar?flag=true&on=Lantern")

			expect(bar_off).not.toHaveBeenCalled()
			expect(bar_on).not.toHaveBeenCalled()
		#END it

		it "Observable hierarchy 1", ->
			foo = sinon.spy()
			bar = sinon.spy()
			id = sinon.spy()

			Finch.route "foo", (bindings) ->
				Finch.observe ["a"], (a) -> foo(a)
			Finch.route "[foo]/bar", (bindings) ->
				Finch.observe ["b"], (b) -> bar(b)
			Finch.route "[foo/bar]/:id", (bindings) ->
				Finch.observe ["c"], (c) -> id(c)

			Finch.call "/foo/bar?&a=1&b=2&c=3"

			expect(foo).toHaveBeenCalledOnce()
			expect(foo).toHaveBeenCalledWith("1")
			expect(bar).toHaveBeenCalledOnce()
			expect(bar).toHaveBeenCalledWith("2")
			expect(id).not.toHaveBeenCalled()

			foo.reset()
			bar.reset()
			id.reset()

			Finch.call "/foo/bar?a=1&b=2&c=11"

			expect(foo).not.toHaveBeenCalled()
			expect(bar).not.toHaveBeenCalled()
			expect(id).not.toHaveBeenCalled()

			foo.reset()
			bar.reset()
			id.reset()

			Finch.call "/foo?a=21&b=2&c=23"

			expect(foo).toHaveBeenCalledOnce()
			expect(foo).toHaveBeenCalledWith("21")
			expect(bar).not.toHaveBeenCalled()
			expect(id).not.toHaveBeenCalled()

			foo.reset()
			bar.reset()
			id.reset()

			Finch.call "/foo?a=31&b=32&c=23"

			expect(foo).toHaveBeenCalledOnce()
			expect(foo).toHaveBeenCalledWith("31")
			expect(bar).not.toHaveBeenCalled()
			expect(id).not.toHaveBeenCalled()
		#END it

		it "Observable hierarchy 2", ->
			slash = sinon.spy()
			foo = sinon.spy()
			bar = sinon.spy()
			id = sinon.spy()

			Finch.route "/", (bindings) ->
				Finch.observe ["x"], (x) -> slash(x)
			Finch.route "[/]foo", (bindings) ->
				Finch.observe ["a"], (a) -> foo(a)
			Finch.route "[/foo]/bar", (bindings) ->
				Finch.observe ["b"], (b) -> bar(b)
			Finch.route "[/foo/bar]/:id", (bindings) ->
				Finch.observe ["c"], (c) -> id(c)

			Finch.call "/foo/bar?x=0&a=1&b=2&c=3"

			expect(slash).toHaveBeenCalledOnce()
			expect(slash).toHaveBeenCalledWith("0")
			expect(foo).toHaveBeenCalledOnce()
			expect(foo).toHaveBeenCalledWith("1")
			expect(bar).toHaveBeenCalledOnce()
			expect(bar).toHaveBeenCalledWith("2")
			expect(id).not.toHaveBeenCalled()

			slash.reset()
			foo.reset()
			bar.reset()
			id.reset()

			Finch.call "/foo/bar?x=0&a=1&b=10&c=11"

			expect(slash).not.toHaveBeenCalled()
			expect(foo).not.toHaveBeenCalled()
			expect(bar).toHaveBeenCalledOnce()
			expect(bar).toHaveBeenCalledWith("10")
			expect(id).not.toHaveBeenCalled()
		#END it

		it "Observable value types", ->
			stub = sinon.spy()

			Finch.route "/", (bindings) ->
				Finch.observe ["x"], (x) -> stub(x)

			Finch.call "/?x=123"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("123")
			stub.reset()

			Finch.call "/?x=123.456"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("123.456")
			stub.reset()

			Finch.call "/?x=true"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("true")
			stub.reset()

			Finch.call "/?x=false"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("false")
			stub.reset()

			Finch.call "/?x=stuff"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("stuff")
			stub.reset()

			Finch.options(CoerceParameterTypes: true)

			Finch.call "/?x=123"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(123)
			stub.reset()

			Finch.call "/?x=123.456"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(123.456)
			stub.reset()

			Finch.call "/?x=true"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(true)
			stub.reset()

			Finch.call "/?x=false"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(false)
			stub.reset()

			Finch.call "/?x=stuff"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("stuff")
			stub.reset()
	#END describe

	describe "Bindings", ->
		it "Binding value types", ->
			stub = sinon.spy()

			Finch.route "/:x", ({x}) -> stub(x)

			Finch.call "/123"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith('123')
			stub.reset()

			Finch.call "/123.456"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith('123.456')
			stub.reset()

			Finch.call "/true"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith('true')
			stub.reset()

			Finch.call "/false"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith('false')
			stub.reset()

			Finch.call "/stuff"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("stuff")
			stub.reset()

			Finch.options(CoerceParameterTypes: true)

			Finch.call "/123"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(123)
			stub.reset()

			Finch.call "/123.456"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(123.456)
			stub.reset()

			Finch.call "/true"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(true)
			stub.reset()

			Finch.call "/false"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith(false)
			stub.reset()

			Finch.call "/stuff"
			expect(stub).toHaveBeenCalledOnce()
			expect(stub).toHaveBeenCalledWith("stuff")
			stub.reset()
		#END it
	#END describe

	describe "Other Static Methods", ->
		it "Finch.navigate", ->
			window.location.hash = ""

			hash = -> "#" + ( window.location.href.split("#", 2)[1] ? "" )

			homeRegex = /^#?\/home/
			homeNewsRegex = /^#?\/home\/news/
			homeAccountRegex = /^#?\/home\/account/
			homeNewsArticleRegex = /^#?\/home\/news\/article/
			#helloWorldRegex = /^#?\/hello%20world/
			helloWorldRegex = /^#?\/hello world/

			#Navigate to just a single route
			Finch.navigate("/home")
			expect(homeRegex.test(hash())).toBe(true)

			Finch.navigate("/home/news")
			expect(homeNewsRegex.test(hash())).toBe(true)

			Finch.navigate("/home")
			expect(homeRegex.test(hash())).toBe(true)

			#navigate to a route and query parameters
			Finch.navigate("/home", foo:"bar")
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foo=bar") > -1 ).toBe(true)

			#navigate to a route and query parameters
			Finch.navigate("/home", hello:"world")
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foo=bar") is -1).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)

			#Navigate to only a new hash
			Finch.navigate(foos:"bars")
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("hello=world") is -1).toBe(true)
			expect( hash().indexOf("foos=bars") > -1 ).toBe(true)

			#Only update the hash
			Finch.navigate(foos:"baz")
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foos=baz") > -1 ).toBe(true)

			Finch.navigate(hello:"world", true)
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foos=baz") > -1 ).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)

			#Remove a paremeter
			Finch.navigate(foos:null, true)
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foos=baz") is -1).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)

			#Make siure the doUpdate navigate keeps the query string
			Finch.navigate("/home/news", true)
			expect(homeNewsRegex.test(hash())).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)

			#Make sure we add proper escaping
			Finch.navigate("/hello world", {})
			expect( helloWorldRegex.test(hash()) ).toBe( true )
			expect( hash().indexOf("hello=world") is -1).toBe(true)

			Finch.navigate("/hello world", foo:"bar bar")
			expect( helloWorldRegex.test(hash()) ).toBe( true )
			expect( hash().indexOf("foo=bar bar") > -1 ).toBe(true)

			Finch.navigate(foo:"baz baz")
			expect( helloWorldRegex.test(hash()) ).toBe( true )
			expect( hash().indexOf("foo=bar bar") is -1).toBe(true)
			expect( hash().indexOf("foo=baz baz") > -1 ).toBe(true)

			Finch.navigate(hello:'world world', true)
			expect( helloWorldRegex.test(hash()) ).toBe( true )
			expect( hash().indexOf("foo=baz baz") > -1 ).toBe(true)
			expect( hash().indexOf("hello=world world") > -1 ).toBe(true)

			#Make sure we don't add multiple '?'
			Finch.navigate("/home?foo=bar",hello:"world")
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foo=bar") > -1 ).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)
			expect( hash().split("?").length-1 ).toBe( 1 )
			expect( hash().split("&").length-1 ).toBe( 1 )

			Finch.navigate("/home?foo=bar",{hello:"world",foo:"baz"})
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foo=bar") is -1).toBe(true)
			expect( hash().indexOf("foo=baz") > -1 ).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)
			expect( hash().split("?").length-1 ).toBe( 1 )
			expect( hash().split("&").length-1 ).toBe( 1 )

			Finch.navigate("/home?foo=bar",{hello:"world",free:"bird"})
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("foo=bar") > -1 ).toBe(true)
			expect( hash().indexOf("free=bird") > -1 ).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)
			expect( hash().split("?").length-1 ).toBe( 1 )
			expect( hash().split("&").length-1 ).toBe( 2 )

			#Account for the hash character
			Finch.navigate("#/home", true)
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("free=bird") > -1 ).toBe(true)
			expect( hash().indexOf("hello=world") > -1 ).toBe(true)

			Finch.navigate("#/home")
			expect(homeRegex.test(hash())).toBe(true)
			expect( hash().indexOf("free=bird") is -1).toBe(true)
			expect( hash().indexOf("hello=world") is -1).toBe(true)

			Finch.navigate("#/home/news",{free:"birds",hello:"worlds"})
			expect(homeNewsRegex.test(hash())).toBe(true)
			expect( hash().indexOf("free=birds") > -1 ).toBe(true)
			expect( hash().indexOf("hello=worlds") > -1 ).toBe(true)

			Finch.navigate("#/home/news", {foo:"bar"}, true)
			expect(homeNewsRegex.test(hash())).toBe(true)
			expect( hash().indexOf("free=birds") > -1 ).toBe(true)
			expect( hash().indexOf("hello=worlds") > -1 ).toBe(true)
			expect( hash().indexOf("foo=bar") > -1 ).toBe(true)

			#Test relative navigation
			Finch.navigate("/home/news")
			expect(homeNewsRegex.test(hash())).toBe(true)

			Finch.navigate("../")
			expect(homeRegex.test(hash())).toBe(true)

			Finch.navigate("./")
			expect(homeRegex.test(hash())).toBe(true)

			Finch.navigate("./news")
			expect(homeNewsRegex.test(hash())).toBe(true)

			Finch.navigate("/home/news/article")
			expect( homeNewsArticleRegex.test(hash()) ).toBe( true )

			Finch.navigate("../../account")
			expect( homeAccountRegex.test(hash()) ).toBe( true )
		#END it

		it "Finch.listen and Finch.ignore", ->
			#Default the necessary window methods, if they don't exist
			window.hasOwnProperty ?= (prop) -> (prop of @)

			cb = callbackGroup()
			cb.attachEvent = sinon.spy()
			cb.detachEvent = sinon.spy()
			cb.addEventListener = sinon.spy()
			cb.removeEventListener = sinon.spy()
			cb.setInterval = sinon.spy()
			cb.clearInterval = sinon.spy()

			clearWindowMethods = ->
				window.attachEvent = null if "attachEvent" of window
				window.detachEvent = null if "detachEvent" of window
				window.addEventListener = null if "addEventListener" of window
				window.removeEventListener = null if "removeEventListener" of window
				window.setInterval = null if "setInterval" of window
				window.clearInterval = null if "clearInterval" of window

			#Test the fallback set interval
			clearWindowMethods()
			window.setInterval = cb.setInterval
			window.clearInterval = cb.clearInterval
			cb.reset()

			expect( Finch.listen() ).toBe( true )
			expect( cb.addEventListener.callCount ).toBe( 0 )
			expect( cb.attachEvent.callCount ).toBe( 0 )
			expect( cb.setInterval.callCount ).toBe( 1 )

			expect( Finch.ignore() ).toBe( true )
			expect( cb.removeEventListener.callCount ).toBe( 0 )
			expect( cb.detachEvent.callCount ).toBe( 0 )
			expect( cb.clearInterval.callCount ).toBe( 1 )

			# Test the add/remove EventListener methods
			clearWindowMethods()
			window.onhashchange = "defined"
			window.addEventListener = cb.addEventListener
			window.removeEventListener = cb.removeEventListener
			cb.reset()

			expect( Finch.listen() ).toBe( true )
			expect( cb.addEventListener.callCount ).toBe( 1 )
			expect( cb.attachEvent.callCount ).toBe( 0 )
			expect( cb.setInterval.callCount ).toBe( 0 )

			expect( Finch.ignore() ).toBe( true )
			expect( cb.removeEventListener.callCount ).toBe( 1 )
			expect( cb.detachEvent.callCount ).toBe( 0 )
			expect( cb.clearInterval.callCount ).toBe( 0 )

			#Test the attach/detach Event methods
			clearWindowMethods()
			window.onhashchange = "defined"
			window.attachEvent = cb.attachEvent
			window.detachEvent = cb.detachEvent
			cb.reset()

			expect( Finch.listen() ).toBe( true )
			expect( cb.addEventListener.callCount ).toBe( 0 )
			expect( cb.attachEvent.callCount ).toBe( 1 )
			expect( cb.setInterval.callCount ).toBe( 0 )

			expect( Finch.ignore() ).toBe( true )
			expect( cb.removeEventListener.callCount ).toBe( 0 )
			expect( cb.detachEvent.callCount ).toBe( 1 )
			expect( cb.clearInterval.callCount ).toBe( 0 )
		#END it

		it "Finch.abort", ->
			homeStub = sinon.spy()
			fooStub = sinon.spy()

			Finch.route "/home", (bindings, continuation) -> homeStub()
			Finch.route "/foo", (bindings, continuation) -> fooStub()

			#make a call to home
			Finch.call("home")
			expect( homeStub.callCount ).toBe( 1 )
			expect( fooStub.callCount ).toBe( 0 )

			homeStub.reset()
			fooStub.reset()

			#Call foo
			Finch.call("foo")
			expect( homeStub.callCount ).toBe( 0 )
			expect( fooStub.callCount ).toBe( 0 )

			homeStub.reset()
			fooStub.reset()

			#abort first, then call foo
			Finch.abort().call("foo")
			expect( homeStub.callCount ).toBe( 0 )
			expect( fooStub.callCount ).toBe( 1 )
		#END it
	#END describe

	describe "Miscellaneous Tests", ->
		it "Route finding backtracking 1", ->
			Finch.abort().reset()

			Finch.route "/foo",          	foo = sinon.spy()
			Finch.route "[/foo]/bar",    	bar = sinon.spy()
			Finch.route "[/foo/bar]/baz",	baz = sinon.spy()

			Finch.route "/:var1",              	var1 = sinon.spy()
			Finch.route "[/:var1/]:var2",      	var2 = sinon.spy()
			Finch.route "[/:var1/:var2]/:var3",	var3 = sinon.spy()

			# Test routes

			Finch.call "/foo/nope"

			expect( var1 ).toHaveBeenCalledOnce()
			expect( var1 ).toHaveBeenCalledWith({var1: "foo"})
			expect( var2 ).toHaveBeenCalledOnce()
			expect( var2 ).toHaveBeenCalledWith({var1: "foo", var2: "nope"})
			expect( foo ).not.toHaveBeenCalled()
		#END it

		it "Route finding backtracking 2", ->

			Finch.route "/foo",          	foo = sinon.spy()
			Finch.route "[/foo]/bar",    	bar = sinon.spy()
			Finch.route "[/foo/bar]/baz",	baz = sinon.spy()

			Finch.route "/:var1",              	var1 = sinon.spy()
			Finch.route "[/:var1/]:var2",      	var2 = sinon.spy()
			Finch.route "[/:var1/:var2]/:var3",	var3 = sinon.spy()

			# Test routes

			Finch.call "/foo/bar/nope"

			expect( var1 ).toHaveBeenCalledOnce()
			expect( var1 ).toHaveBeenCalledWith({var1: "foo"})
			expect( var2 ).toHaveBeenCalledOnce()
			expect( var2 ).toHaveBeenCalledWith({var1: "foo", var2: "bar"})
			expect( var3 ).toHaveBeenCalledOnce()
			expect( var3 ).toHaveBeenCalledWith({var1: "foo", var2: "bar", var3: "nope"})
			expect( foo ).not.toHaveBeenCalled()
			expect( bar ).not.toHaveBeenCalled()
		#END it

		it "Optional parameter parsing", ->

			Finch.route "/"
			Finch.route "/home/news/:id", foo = sinon.spy()
			Finch.call "/home/news/1234"

			expect( foo ).toHaveBeenCalledOnce()
			expect( foo ).toHaveBeenCalledWith({id: "1234"})

			foo.reset()

			Finch.options { CoerceParameterTypes: true }

			Finch.call "/"
			Finch.call "/home/news/1234"

			expect( foo ).toHaveBeenCalledOnce()
			expect( foo ).toHaveBeenCalledWith({id: 1234})
		#END it

		it "Variable parent routes called if no children found", ->
			cb = callbackGroup()

			Finch.route "/", 
				'setup': cb.slash_setup = sinon.spy()
				'load': cb.slash_load = sinon.spy()
				'unload': cb.slash_unload = sinon.spy()
				'teardown': cb.slash_teardown = sinon.spy()

			Finch.route "[/]users/profile", 
				'setup': cb.profile_setup = sinon.spy()
				'load': cb.profile_load = sinon.spy()
				'unload': cb.profile_unload = sinon.spy()
				'teardown': cb.profile_teardown = sinon.spy()

			Finch.route "[/]:page", 
				'setup': cb.page_setup = sinon.spy()
				'load': cb.page_load = sinon.spy()
				'unload': cb.page_unload = sinon.spy()
				'teardown': cb.page_teardown = sinon.spy()

			Finch.call "/users"

			expect( cb.slash_setup ).toHaveBeenCalledOnce()
			expect( cb.slash_load ).not.toHaveBeenCalled()
			expect( cb.slash_unload ).not.toHaveBeenCalled()
			expect( cb.slash_teardown ).not.toHaveBeenCalled()

			expect( cb.page_setup ).toHaveBeenCalledOnce()
			expect( cb.page_load ).toHaveBeenCalledOnce()
			expect( cb.page_unload ).not.toHaveBeenCalled()
			expect( cb.page_teardown ).not.toHaveBeenCalled()

			expect( cb.profile_setup ).not.toHaveBeenCalled()
			expect( cb.profile_load ).not.toHaveBeenCalled()
			expect( cb.profile_unload ).not.toHaveBeenCalled()
			expect( cb.profile_teardown ).not.toHaveBeenCalled()

			expect( cb.page_setup ).toHaveBeenCalledWith({page: "users"})
			expect( cb.page_load ).toHaveBeenCalledWith({page: "users"})
		#END it

		it "Test double deep variable basic routes up and down", ->
			cb = callbackGroup()
			Finch.route "/project/:project_id", cb.project_id_load = sinon.spy()
			Finch.route "[/project/:project_id]/milestone", cb.milestone_load = sinon.spy()
			Finch.route "[/project/:project_id/milestone]/:milestone_id", cb.milestone_id_load = sinon.spy()

			Finch.call "/project/1234"
			expect( cb.project_id_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_load ).not.toHaveBeenCalled()
			expect( cb.milestone_id_load ).not.toHaveBeenCalled()
			expect( cb.project_id_load ).toHaveBeenCalledWith({project_id: "1234"})
			cb.reset()

			Finch.call "/project/1234/milestone"
			expect( cb.project_id_load ).not.toHaveBeenCalled()
			expect( cb.milestone_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_id_load ).not.toHaveBeenCalled()
			expect( cb.milestone_load ).toHaveBeenCalledWith({project_id: "1234"})
			cb.reset()

			Finch.call "/project/1234/milestone/5678"
			expect( cb.project_id_load ).not.toHaveBeenCalled()
			expect( cb.milestone_load ).not.toHaveBeenCalled()
			expect( cb.milestone_id_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_id_load ).toHaveBeenCalledWith({project_id: "1234", milestone_id: "5678"})
			cb.reset()

			Finch.call "/project/1234/milestone"
			expect( cb.project_id_load ).not.toHaveBeenCalled()
			expect( cb.milestone_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_id_load ).not.toHaveBeenCalled()
			expect( cb.milestone_load ).toHaveBeenCalledWith({project_id: "1234"})
			cb.reset()

			Finch.call "/project/1234"
			expect( cb.project_id_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_load ).not.toHaveBeenCalled()
			expect( cb.milestone_id_load ).not.toHaveBeenCalled()
			expect( cb.project_id_load ).toHaveBeenCalledWith({project_id: "1234"})
			cb.reset()
		#END it

		it "Test double deep variable basic routes up and down", ->
			cb = callbackGroup()
			Finch.route "/project/:project_id/milestone",
				setup: cb.milestone_setup = sinon.spy()
				load: cb.milestone_load = sinon.spy()
				unload: cb.milestone_unload = sinon.spy()
				teardown: cb.milestone_teardown = sinon.spy()
			#END rout

			Finch.route "[/project/:project_id/milestone]/:milestone_id",
				setup: cb.milestone_id_setup = sinon.spy()
				load: cb.milestone_id_load = sinon.spy()
				unload: cb.milestone_id_unload = sinon.spy()
				teardown: cb.milestone_id_teardown = sinon.spy()
			#END rout

			Finch.call "/project/1234/milestone"
			expect( cb.milestone_setup ).toHaveBeenCalledOnce()
			expect( cb.milestone_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_unload ).not.toHaveBeenCalled()
			expect( cb.milestone_teardown ).not.toHaveBeenCalled()

			expect( cb.milestone_id_setup ).not.toHaveBeenCalled()
			expect( cb.milestone_id_load ).not.toHaveBeenCalled()
			expect( cb.milestone_id_unload ).not.toHaveBeenCalled()
			expect( cb.milestone_id_teardown ).not.toHaveBeenCalled()

			expect( cb.milestone_setup ).toHaveBeenCalledWith({project_id: "1234"})
			expect( cb.milestone_load ).toHaveBeenCalledWith({project_id: "1234"})

			cb.reset()

			Finch.call "/project/1234/milestone/5678"
			expect( cb.milestone_setup ).not.toHaveBeenCalled()
			expect( cb.milestone_load ).not.toHaveBeenCalled()
			expect( cb.milestone_unload ).toHaveBeenCalledOnce()
			expect( cb.milestone_teardown ).not.toHaveBeenCalled()

			expect( cb.milestone_id_setup ).toHaveBeenCalledOnce()
			expect( cb.milestone_id_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_id_unload ).not.toHaveBeenCalled()
			expect( cb.milestone_id_teardown ).not.toHaveBeenCalled()

			expect( cb.milestone_unload ).toHaveBeenCalledWith({project_id: "1234"})

			expect( cb.milestone_id_setup ).toHaveBeenCalledWith({project_id: "1234", milestone_id: "5678"})
			expect( cb.milestone_id_load ).toHaveBeenCalledWith({project_id: "1234", milestone_id: "5678"})
			cb.reset()


			Finch.call "/project/1234/milestone"
			expect( cb.milestone_setup ).not.toHaveBeenCalled()
			expect( cb.milestone_load ).toHaveBeenCalledOnce()
			expect( cb.milestone_unload ).not.toHaveBeenCalled()
			expect( cb.milestone_teardown ).not.toHaveBeenCalled()

			expect( cb.milestone_id_setup ).not.toHaveBeenCalled()
			expect( cb.milestone_id_load ).not.toHaveBeenCalled()
			expect( cb.milestone_id_unload ).toHaveBeenCalledOnce()
			expect( cb.milestone_id_teardown ).toHaveBeenCalledOnce()

			expect( cb.milestone_load ).toHaveBeenCalledWith({project_id: "1234"})

			expect( cb.milestone_id_unload ).toHaveBeenCalledWith({project_id: "1234", milestone_id: "5678"})
			expect( cb.milestone_id_teardown ).toHaveBeenCalledWith({project_id: "1234", milestone_id: "5678"})
			cb.reset()
		#END it
	#END describe
#END describe