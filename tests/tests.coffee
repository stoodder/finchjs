calledOnce = (fake, message) ->
	QUnit.push fake.calledOnce, fake.callCount, 1, message
neverCalled = (fake, message) ->
	QUnit.push !fake.called, fake.callCount, 0, message
lastCalledWithExactly = (fake, expectedArgs, message) ->
	result = fake.lastCall? and QUnit.equiv(fake.lastCall.args, expectedArgs)
	actualArgs = fake.lastCall?.args
	QUnit.push result, actualArgs, expectedArgs, message

callbackGroup = () ->
	group = {}
	group.reset = () ->
		for key, value of group
			value.reset() if Object::toString.call(value.reset) is "[object Function]"
	return group

module "Finch",
	teardown: ->
		Finch.reset()

test "Trivial routing", sinon.test ->

	Finch.route "foo/bar", foo_bar = @stub()
	Finch.route "baz/quux", baz_quux = @stub()

	# Test routes

	Finch.call "/foo/bar"

	calledOnce foo_bar, "foo/bar called"

	Finch.call "/baz/quux"

	calledOnce baz_quux, "baz/quux called"

test "Simple hierarchical routing", sinon.test ->

	Finch.route "foo",          	foo = @stub()
	Finch.route "[foo]/bar",    	foo_bar = @stub()
	Finch.route "[foo/bar]/:id",	foo_bar_id = @stub()
	Finch.route "[foo]/baz",    	foo_baz = @stub()
	Finch.route "[foo/baz]/:id",	foo_baz_id = @stub()
	Finch.route "quux",         	quux = @stub()
	Finch.route "[quux]/:id",   	quux_id = @stub()

	# Test routes

	Finch.call "/foo/bar"

	calledOnce foo, "foo called once"
	lastCalledWithExactly foo, [{}], "foo called with correct bindings"
	calledOnce foo_bar, "foo/bar called once"
	lastCalledWithExactly foo_bar, [{}], "foo called with correct bindings"
	ok foo.calledBefore(foo_bar), "foo called before foo/bar"
	foo.reset()
	foo_bar.reset()

	Finch.call "/foo/bar/123"

	neverCalled foo, "foo not called again"
	neverCalled foo_bar, "foo/bar not called again"
	calledOnce foo_bar_id, "foo/bar/id called once"
	lastCalledWithExactly foo_bar_id, [{ id: "123" }], "foo/bar/id bindings"
	foo_bar_id.reset()

	Finch.call "/foo/bar/123"

	neverCalled foo, "foo not called again"
	neverCalled foo_bar, "foo/bar not called again"
	neverCalled foo_bar_id, "foo/bar/id not called again"

	Finch.call "/foo/bar/123?x=Hello&y=World"

	neverCalled foo, "foo not called again"
	neverCalled foo_bar, "foo/bar not called again"
	neverCalled foo_bar_id, "foo/bar/id not called again"

	Finch.call "/foo/baz/456"

	neverCalled foo, "foo not called again"
	calledOnce foo_baz, "foo/baz called"
	calledOnce foo_baz_id, "foo/baz/id called"
	ok foo_baz.calledBefore(foo_baz_id), "foo/baz called before foo/baz/id"
	lastCalledWithExactly foo_baz_id, [{ id: "456" }], "foo/baz/id bindings"
	foo_baz.reset()
	foo_baz_id.reset()

	Finch.call "/quux/789?band=Sunn O)))&genre=Post-Progressive Fridgecore"

	calledOnce quux, "quux called"
	calledOnce quux_id, "quux/id called"
	ok quux.calledBefore(quux_id), "quux called before quux/id"
	lastCalledWithExactly quux_id, [{ id: "789" }], "quux/id bindings"

test "More hierarchical routing", sinon.test ->

	Finch.route "foo",           	foo = @stub()
	Finch.route "[foo]/bar/baz", 	foo_bar_baz = @stub()
	Finch.route "foo/bar",       	foo_bar = @stub()
	Finch.route "[foo/bar]/quux",	foo_bar_quux = @stub()

	# Test routes

	Finch.call "/foo/bar/baz"

	calledOnce foo, "foo called"
	calledOnce foo_bar_baz, "foo/bar/baz called"
	ok foo.calledBefore(foo_bar_baz), "foo called before foo/bar/baz"
	neverCalled foo_bar, "foo/bar NOT called"
	foo.reset()
	foo_bar_baz.reset()

	Finch.call "/foo/bar/quux"
	calledOnce foo_bar, "foo/bar called"
	calledOnce foo_bar_quux, "foo/bar/quux called"
	ok foo_bar.calledBefore(foo_bar_quux), "foo/bar called before foo/bar/quux"
	neverCalled foo, "foo NOT called"

test "Even more hierarchical routing", sinon.test ->

	Finch.route "foo",      	foo = @stub()
	Finch.route "[foo]/bar",	foo_bar = @stub()

	# Test routes

	Finch.call "/foo"

	calledOnce foo, "foo called"
	neverCalled foo_bar, "foo/bar not called"
	foo.reset()
	foo_bar.reset()

	Finch.call "/foo/bar"

	neverCalled foo, "foo called"
	calledOnce foo_bar, "foo/bar called"
	foo.reset()
	foo_bar.reset()

	Finch.call "/foo"

	calledOnce foo, "foo called"
	neverCalled foo_bar, "foo/bar not called"

test "Hierarchical routing with /", sinon.test ->

	Finch.route "/",         	slash = @stub()
	Finch.route "[/]foo",    	foo = @stub()
	Finch.route "[/foo]/bar",	bar = @stub()

	# Test routes

	Finch.call "/foo"

	calledOnce slash,	"/ called once"
	calledOnce foo,  	"foo called once"
	neverCalled bar, 	"bar never called"

	slash.reset()
	foo.reset()
	bar.reset()

	Finch.call "/"
	calledOnce slash,	"/ called once"
	neverCalled foo, 	"foo never called"
	neverCalled bar, 	"bar never called"

test "Simple routing with setup, load, and teardown", sinon.test ->

	cb = callbackGroup()

	Finch.route "/",
		setup:   	cb.setup_slash = @stub()
		load:    	cb.load_slash = @stub()
		teardown:	cb.teardown_slash = @stub()
	Finch.route "/foo",
		setup:   	cb.setup_foo = @stub()
		load:    	cb.load_foo = @stub()
		teardown:	cb.teardown_foo = @stub()
	Finch.route "foo/bar",
		setup:   	cb.setup_foo_bar = @stub()
		load:    	cb.load_foo_bar = @stub()
		teardown:	cb.teardown_foo_bar = @stub()

	# Test routes

	Finch.call "/"

	calledOnce cb.setup_slash,    	'/: / setup called once'
	calledOnce cb.load_slash,     	'/: / load called once'
	neverCalled cb.teardown_slash,	'/: / teardown not called'
	cb.reset()

	Finch.call "/foo"

	neverCalled cb.setup_slash,  	'/foo: / setup not called'
	neverCalled cb.load_slash,   	'/foo: / load called once'
	calledOnce cb.teardown_slash,	'/foo: / teardown called once'
	calledOnce cb.setup_foo,     	'/foo: foo setup called once'
	calledOnce cb.load_foo,      	'/foo: foo load called once'
	neverCalled cb.teardown_foo, 	'/foo: foo teardown not called'
	cb.reset()

	Finch.call "/foo/bar"

	neverCalled cb.setup_slash,     	'/foo/bar: / setup not called'
	neverCalled cb.load_slash,      	'/foo/bar: / teardown not called'
	neverCalled cb.teardown_slash,  	'/foo/bar: / teardown not called'
	neverCalled cb.setup_foo,       	'/foo/bar: foo setup not called'
	neverCalled cb.load_foo,        	'/foo/bar: foo load called once'
	calledOnce cb.teardown_foo,     	'/foo/bar: foo teardown called once'
	calledOnce cb.setup_foo_bar,    	'/foo/bar: foo/bar setup called once'
	calledOnce cb.load_foo_bar,     	'/foo/bar: foo/bar load called once'
	neverCalled cb.teardown_foo_bar,	'/foo/bar: foo/bar teardown not called'
	cb.reset()

	Finch.call "/foo/bar?baz=quux"

	neverCalled cb.setup_slash,     	'/foo/bar?baz=quux: / setup not called'
	neverCalled cb.load_slash,      	'/foo/bar?baz=quux: / load not called'
	neverCalled cb.teardown_slash,  	'/foo/bar?baz=quux: / teardown not called'
	neverCalled cb.setup_foo,       	'/foo/bar?baz=quux: foo setup not called'
	neverCalled cb.load_foo,        	'/foo/bar?baz=quux: foo load not called'
	neverCalled cb.teardown_foo,    	'/foo/bar?baz=quux: foo teardown not called'
	neverCalled cb.setup_foo_bar,   	'/foo/bar?baz=quux: foo/bar setup not called'
	neverCalled cb.load_foo_bar,    	'/foo/bar?baz=quux: foo/bar load not called'
	neverCalled cb.teardown_foo_bar,	'/foo/bar?baz=quux: foo/bar teardown not called'
	cb.reset()

	Finch.call "/foo/bar?baz=xyzzy"

	neverCalled cb.setup_slash,     	'/foo/bar?baz=xyzzy: / setup not called'
	neverCalled cb.load_slash,      	'/foo/bar?baz=xyzzy: / load not called'
	neverCalled cb.teardown_slash,  	'/foo/bar?baz=xyzzy: / teardown not called'
	neverCalled cb.setup_foo,       	'/foo/bar?baz=xyzzy: foo setup not called'
	neverCalled cb.load_foo,        	'/foo/bar?baz=xyzzy: foo load not called'
	neverCalled cb.teardown_foo,    	'/foo/bar?baz=xyzzy: foo teardown not called'
	neverCalled cb.setup_foo_bar,   	'/foo/bar?baz=xyzzy: foo/bar setup not called'
	neverCalled cb.load_foo_bar,    	'/foo/bar?baz=xyzzy: foo/bar load not called'
	neverCalled cb.teardown_foo_bar,	'/foo/bar?baz=xyzzy: foo/bar teardown not called'
	cb.reset()

test "Hierarchical routing with setup, load, and teardown", sinon.test ->

	cb = callbackGroup()

	Finch.route "foo",
		setup:   	cb.setup_foo = @stub()
		load:    	cb.load_foo = @stub()
		unload:  	cb.unload_foo = @stub()
		teardown:	cb.teardown_foo = @stub()
	Finch.route "[foo]/bar",
		setup:   	cb.setup_foo_bar = @stub()
		load:    	cb.load_foo_bar = @stub()
		unload:  	cb.unload_foo_bar = @stub()
		teardown:	cb.teardown_foo_bar = @stub()
	Finch.route "[foo/bar]/:id",
		setup:   	cb.setup_foo_bar_id = @stub()
		load:    	cb.load_foo_bar_id = @stub()
		unload:  	cb.unload_foo_bar_id = @stub()
		teardown:	cb.teardown_foo_bar_id = @stub()
	Finch.route "[foo]/baz",
		setup:   	cb.setup_foo_baz = @stub()
		load:    	cb.load_foo_baz = @stub()
		unload:  	cb.unload_foo_baz = @stub()
		teardown:	cb.teardown_foo_baz = @stub()
	Finch.route "[foo/baz]/:id",
		setup:   	cb.setup_foo_baz_id = @stub()
		load:    	cb.load_foo_baz_id = @stub()
		unload:  	cb.unload_foo_baz_id = @stub()
		teardown:	cb.teardown_foo_baz_id = @stub()

	# Test routes

	Finch.call "/foo"

	calledOnce cb.setup_foo,	"/foo: foo setup"
	calledOnce cb.load_foo, 	"/foo: foo load"
	cb.reset()

	Finch.call "/foo/bar"

	calledOnce cb.unload_foo,   	"/foo/bar: foo unload"
	neverCalled cb.setup_foo,   	"/foo/bar: no foo setup"
	neverCalled cb.load_foo,    	"/foo/bar: no foo load"
	neverCalled cb.teardown_foo,	"/foo/bar: no foo teardown"
	calledOnce cb.setup_foo_bar,	"/foo/bar: foo/bar setup"
	calledOnce cb.load_foo_bar, 	"/foo/bar: foo/bar load"
	cb.reset()

	Finch.call "/foo"

	calledOnce cb.unload_foo_bar,  	"/foo: foo/bar unload"
	calledOnce cb.teardown_foo_bar,	"/foo return: foo/bar teardown"
	calledOnce cb.load_foo,        	"/foo return: no foo load"
	neverCalled cb.setup_foo,      	"/foo return: no foo setup"
	cb.reset()

	Finch.call "/foo/bar/123?x=abc"
	calledOnce cb.unload_foo,      	"/foo/bar/123: foo unload"
	neverCalled cb.unload_foo_bar, 	"/foo/bar/123: no foo/bar unload"
	neverCalled cb.teardown_foo,   	"/foo/bar/123: no foo teardown"
	neverCalled cb.load_foo,       	"/foo/bar/123: no foo load"
	neverCalled cb.setup_foo,      	"/foo/bar/123: no foo setup"
	calledOnce cb.setup_foo_bar,   	"/foo/bar/123: foo/bar setup"
	neverCalled cb.load_foo_bar,   	"/foo/bar/123: foo/bar load"
	calledOnce cb.setup_foo_bar_id,	"/foo/bar/123: foo/bar/id setup"
	calledOnce cb.load_foo_bar_id, 	"/foo/bar/123: foo/bar/id load"
	cb.reset()

	Finch.call "/foo/bar/456?x=aaa&y=zzz"

	calledOnce cb.unload_foo_bar_id,  	"/foo/bar/456?x=aaa&y=zzz: foo/bar/id unload"
	calledOnce cb.teardown_foo_bar_id,	"/foo/bar/456?x=aaa&y=zzz: foo/bar/id teardown"
	calledOnce cb.setup_foo_bar_id,   	"/foo/bar/456?x=aaa&y=zzz: foo/bar/id setup"
	calledOnce cb.load_foo_bar_id,    	"/foo/bar/456?x=aaa&y=zzz: foo/bar/id load"
	cb.reset()

	Finch.call "/foo/bar/456?x=bbb&y=zzz"

	neverCalled cb.unload_foo_bar_id,  	"/foo/bar/456?x=bbb&y=zzz: no foo/bar/id unload"
	neverCalled cb.teardown_foo_bar_id,	"/foo/bar/456?x=bbb&y=zzz: no foo/bar/id teardown"
	neverCalled cb.setup_foo_bar_id,   	"/foo/bar/456?x=bbb&y=zzz: no foo/bar/id setup"
	neverCalled cb.load_foo_bar_id,    	"/foo/bar/456?x=bbb&y=zzz: no foo/bar/id load"
	cb.reset()

	Finch.call "/foo/bar/456?y=zzz&x=bbb"

	neverCalled cb.unload_foo_bar_id,  	"/foo/bar/456?x=bbb&y=zzz: no foo/bar/id unload"
	neverCalled cb.teardown_foo_bar_id,	"/foo/bar/456?x=bbb&y=zzz: no foo/bar/id teardown"
	neverCalled cb.setup_foo_bar_id,   	"/foo/bar/456?y=zzz&x=bbb: no foo/bar/id setup"
	neverCalled cb.load_foo_bar_id,    	"/foo/bar/456?y=zzz&x=bbb: no foo/bar/id load"
	cb.reset()

	Finch.call "/foo/baz/789"

	calledOnce cb.unload_foo_bar_id,  	"/foo/baz/789: foo/baz/id unload"
	calledOnce cb.teardown_foo_bar_id,	"/foo/baz/789: foo/baz/id teardown"
	neverCalled cb.unload_foo_bar,    	"/foo/baz/789: no foo/bar unload"
	calledOnce cb.teardown_foo_bar,   	"/foo/baz/789: foo/bar teardown"
	neverCalled cb.unload_foo,        	"/foo/baz/789: no foo unload"
	neverCalled cb.teardown_foo,      	"/foo/baz/789: no foo teardown"
	neverCalled cb.setup_foo,         	"/foo/baz/789: no foo setup"
	neverCalled cb.load_foo,          	"/foo/baz/789: no foo load"
	calledOnce cb.setup_foo_baz,      	"/foo/baz/789: foo/baz setup"
	neverCalled cb.load_foo_baz,      	"/foo/baz/789: foo/baz load"
	calledOnce cb.setup_foo_baz_id,   	"/foo/baz/789: foo/baz/id setup"
	calledOnce cb.load_foo_baz_id,    	"/foo/baz/789: foo/baz/id load"
	cb.reset()

	Finch.call "/foo/baz/abc?term=Hello"

	calledOnce cb.unload_foo_baz_id,  	"/foo/baz/abc?term=Hello: foo/baz/id unload"
	calledOnce cb.teardown_foo_baz_id,	"/foo/baz/abc?term=Hello: foo/baz/id teardown"
	calledOnce cb.setup_foo_baz_id,   	"/foo/baz/abc?term=Hello: foo/baz/id setup"
	calledOnce cb.load_foo_baz_id,    	"/foo/baz/abc?term=Hello: foo/baz/id load"
	cb.reset()

	Finch.call "/foo/baz/abc?term=World"

	neverCalled cb.unload_foo_baz_id,  	"/foo/baz/abc?term=World: no foo/baz/id unload"
	neverCalled cb.teardown_foo_baz_id,	"/foo/baz/abc?term=World: no foo/baz/id teardown"
	neverCalled cb.setup_foo_baz_id,   	"/foo/baz/abc?term=World: no foo/baz/id setup"
	neverCalled cb.load_foo_baz_id,    	"/foo/baz/abc?term=World: no foo/baz/id load"

test "Skipped levels hierarchical routing with setup, load, and teardown", sinon.test ->

	cb = callbackGroup()

	Finch.route "/foo",
		setup:   	cb.setup_foo = @stub()
		load:    	cb.load_foo = @stub()
		unload:  	cb.unload_foo = @stub()
		teardown:	cb.teardown_foo = @stub()
	Finch.route "[/foo]/bar",
		setup:   	cb.setup_foo_bar = @stub()
		load:    	cb.load_foo_bar = @stub()
		unload:  	cb.unload_foo_bar = @stub()
		teardown:	cb.teardown_foo_bar = @stub()
	Finch.route "[foo/bar]/:id/baz",
		setup:   	cb.setup_foo_bar_id_baz = @stub()
		load:    	cb.load_foo_bar_id_baz = @stub()
		unload:  	cb.unload_foo_bar_id_baz = @stub()
		teardown:	cb.teardown_foo_bar_id_baz = @stub()

	Finch.call "/foo/bar"

	calledOnce cb.setup_foo, "/foo setup"
	neverCalled cb.load_foo, "/foo load (skipped)"
	calledOnce cb.setup_foo_bar, "/foo/bar setup"
	calledOnce cb.load_foo_bar, "/foo/bar load"
	cb.reset()

	Finch.call "/foo/bar/12345/baz"

	neverCalled cb.setup_foo, "/foo setup (should be cached)"
	neverCalled cb.load_foo, "/foo load (skipped)"
	neverCalled cb.setup_foo_bar, "/foo/bar setup (should be cached)"
	neverCalled cb.load_foo_bar, "/foo/bar load (skipped)"
	calledOnce cb.setup_foo_bar_id_baz, "/foo/bar/:id/baz setup"
	calledOnce cb.load_foo_bar_id_baz, "/foo/bar/:id/baz load"

test "Calling with context", sinon.test ->

	Finch.route "foo",
		setup:   	setup_foo = @stub()
		load:    	load_foo = @stub()
		unload:  	unload_foo = @stub()
		teardown:	teardown_foo = @stub()
	Finch.route "bar", @stub()

	# Test routes

	Finch.call "/foo"

	calledOnce setup_foo, 'foo setup called once'
	context = setup_foo.getCall(0).thisValue
	ok load_foo.calledOn(context), 'foo load called on same context as setup'

	Finch.call "/bar"
	ok unload_foo.calledOn(context), 'foo load called on same context as setup'
	ok teardown_foo.calledOn(context), 'foo teardown called on same context as setup'

test "Checking Parent Context", ->
	Finch.route "/", ->
		equal @parent, null, "Parent is null"

		@someData = "Free Bird"

	Finch.route "[/]home", ->
		ok @parent isnt null, "Parent is defined in simple version"
		equal @parent.someData, "Free Bird", "Correct parent passed in"

		@moreData = "Hello World"

	Finch.route "[/home]/news",
		setup: ->
			ok @parent isnt null, "Parent is defined in setup"
			equal @parent.moreData, "Hello World", "Correct parent passed in"
			equal @parent.parent.someData, "Free Bird", "Correct parent's parent passed in"

		load: ->
			ok @parent isnt null, "Parent is defined in load"
			equal @parent.moreData, "Hello World", "Correct parent passed in"
			equal @parent.parent.someData, "Free Bird", "Correct parent's parent passed in"

		unload: ->
			ok @parent isnt null, "Parent is defined in unload"
			equal @parent.moreData, "Hello World", "Correct parent passed in"
			equal @parent.parent.someData, "Free Bird", "Correct parent's parent passed in"

		teardown: ->
			ok @parent isnt null, "Parent is defined in teardown"
			equal @parent.moreData, "Hello World", "Correct parent passed in"
			equal @parent.parent.someData, "Free Bird", "Correct parent's parent passed in"

	Finch.route "/foo",
		setup: ->
			equal @parent, null, "Parent is null in setup"

		load: ->
			equal @parent, null, "Parent is null in load"

		unload: ->
			equal @parent, null, "Parent is null in unload"

		teardown: ->
			equal @parent, null, "Parent is null in teardown"

	Finch.route "[/]bar",
		setup: ->
			ok @parent isnt null, "Parent is defined in simple version"
			equal @parent.someData, "Free Bird", "Correct parent passed in"

		load: ->
			ok @parent isnt null, "Parent is defined in simple version"
			equal @parent.someData, "Free Bird", "Correct parent passed in"

		unload: ->
			ok @parent isnt null, "Parent is defined in simple version"
			equal @parent.someData, "Free Bird", "Correct parent passed in"

		teardown: ->
			ok @parent isnt null, "Parent is defined in simple version"
			equal @parent.someData, "Free Bird", "Correct parent passed in"
	#End Finch.route /bar

	Finch.call("/bar")
	Finch.call("/home/news")
	Finch.call("/foo")
	Finch.call("/home/news")
	Finch.call("/bar")
	Finch.call("/foo")

test "Hierarchical calling with context", sinon.test ->

	Finch.route "foo",
		setup:   	setup_foo = @stub()
		load:    	load_foo = @stub()
		teardown:	teardown_foo = @stub()
	Finch.route "[foo]/bar",
		setup:   	setup_foo_bar = @stub()
		load:    	load_foo_bar = @stub()
		teardown:	teardown_foo_bar = @stub()
	Finch.route "baz", @stub()

	# Test routes
	Finch.call "/foo"

	calledOnce setup_foo, 'foo setup called once'
	foo_context = setup_foo.getCall(0).thisValue
	ok load_foo.calledOn(foo_context), 'foo load called on same context as setup'

	Finch.call "/foo/bar"

	calledOnce setup_foo_bar, 'foo/bar setup called once'
	foo_bar_context = setup_foo_bar.getCall(0).thisValue
	ok load_foo_bar.calledOn(foo_bar_context), 'foo/bar load called on same context as setup'

	notEqual foo_context, foo_bar_context, 'foo/bar should be called on a different context than foo'

	Finch.call "/baz"

	calledOnce teardown_foo_bar, 'foo/bar teardown called once'
	calledOnce teardown_foo, 'foo teardown called once'
	ok teardown_foo_bar.calledBefore(teardown_foo), 'foo/bar teardown called before foo teardown'

	ok teardown_foo_bar.calledOn(foo_bar_context), 'foo/bar teardown called on same context as setup'
	ok teardown_foo.calledOn(foo_context), 'foo teardown called on same context as'

test 'Testing synchronous and asynchronous unload method and context', sinon.test ->

	cb = callbackGroup()
	cb.home_setup = @stub()
	cb.home_load = @stub()
	cb.home_unload = @stub()
	cb.home_teardown = @stub()

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

	cb.home_news_setup = @stub()
	cb.home_news_load = @stub()
	cb.home_news_unload = @stub()
	cb.home_news_teardown = @stub()

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

	Finch.route "/foo", cb.foo = @stub()

	Finch.call("/home")
	calledOnce cb.home_setup, "Called Home Setup"
	calledOnce cb.home_load, "Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"
	neverCalled cb.foo, "Never Called Foo"

	ok cb.home_setup.calledBefore(cb.home_load), "Called Home setup before load"

	cb.reset()

	Finch.call("/home/news")

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	calledOnce cb.home_unload, "Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	calledOnce cb.home_news_setup, "Called Home News Setup"
	calledOnce cb.home_news_load, "Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"
	neverCalled cb.foo, "Never Called Foo"

	ok cb.home_unload.calledBefore(cb.home_news_setup), "Home unload called before Home/News setup"
	ok cb.home_news_setup.calledBefore(cb.home_news_load), "Home/News setup called before Home/News load"

	cb.reset()

	Finch.call("/foo")

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	calledOnce cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"
	neverCalled cb.foo, "Never Called Foo"

	call = cb.home_news_unload.getCall(0)
	call_context = call.args[0]
	call_next = call.args[1]

	ok call_context.did_setup?, "Setup was passed in context"
	ok call_context.did_load?, "Load was passed in context"
	ok call_context.did_unload?, "Unload was passed in context"
	ok not call_context.did_teardown?, "Teardown was not passed in context"
	
	call_next()

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	calledOnce cb.home_teardown, "Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	calledOnce cb.home_news_unload, "Called Home News Unload"
	calledOnce cb.home_news_teardown, "Called Home News Teardown"
	calledOnce cb.foo, "Called Foo"

	cb.reset()

test "Reload", sinon.test ->

	cb = callbackGroup()
	cb.home_setup = @stub()
	cb.home_load = @stub()
	cb.home_unload = @stub()
	cb.home_teardown = @stub()

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

	cb.home_news_setup = @stub()
	cb.home_news_load = @stub()
	cb.home_news_unload = @stub()
	cb.home_news_teardown = @stub()

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

	calledOnce cb.home_setup, "Called Home Setup"
	calledOnce cb.home_load, "Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	cb.reset()
	Finch.reload()

	neverCalled cb.home_setup, "Never Called Home Setup"
	calledOnce cb.home_load, "Called Home Load"
	calledOnce cb.home_unload, "Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	cb.reset()
	Finch.call("/home/news")

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	calledOnce cb.home_unload, "Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	calledOnce cb.home_news_setup, "Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	call = cb.home_news_setup.getCall(0)
	call_context = call.args[0]
	call_next = call.args[1]

	ok call_context.did_setup?, "Setup was passed in context"
	ok not call_context.did_load?, "Load was not passed in context"
	ok not call_context.did_unload?, "Unload was not passed in context"
	ok not call_context.did_teardown?, "Teardown was not passed in context"

	cb.reset()
	Finch.reload()

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"
	
	cb.reset()
	call_next()

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	calledOnce cb.home_news_load, "Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	call = cb.home_news_load.getCall(0)
	call_context = call.args[0]
	call_next = call.args[1]

	ok call_context.did_setup?, "Setup was passed in context"
	ok call_context.did_load?, "Load was passed in context"
	ok not call_context.did_unload?, "Unload was not passed in context"
	ok not call_context.did_teardown?, "Teardown was not passed in context"

	cb.reset()
	Finch.reload()

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	cb.reset()
	call_next()
	Finch.reload()

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	calledOnce cb.home_news_unload, "Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	call = cb.home_news_unload.getCall(0)
	call_context = call.args[0]
	call_next = call.args[1]

	ok call_context.did_setup?, "Setup was passed in context"
	ok call_context.did_load?, "Load was passed in context"
	ok call_context.did_unload?, "Unload was passed in context"
	ok not call_context.did_teardown?, "Teardown was not passed in context"

	cb.reset()
	Finch.reload()

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	neverCalled cb.home_news_load, "Never Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	cb.reset()
	call_next()

	neverCalled cb.home_setup, "Never Called Home Setup"
	neverCalled cb.home_load, "Never Called Home Load"
	neverCalled cb.home_unload, "Never Called Home Unload"
	neverCalled cb.home_teardown, "Never Called Home Teardown"
	neverCalled cb.home_news_setup, "Never Called Home News Setup"
	calledOnce cb.home_news_load, "Called Home News Load"
	neverCalled cb.home_news_unload, "Never Called Home News Unload"
	neverCalled cb.home_news_teardown, "Never Called Home News Teardown"

	call = cb.home_news_load.getCall(0)
	call_context = call.args[0]
	call_next = call.args[1]

	ok call_context.did_setup?, "Setup was passed in context"
	ok call_context.did_load?, "Load was passed in context"
	ok call_context.did_unload?, "Unload was passed in context"
	ok not call_context.did_teardown?, "Teardown was not passed in context"

test "Route sanitation", sinon.test ->

	Finch.route "/", slash = @stub()
	Finch.route "/foo", foo = @stub()
	Finch.route "/foo/bar", foo_bar = @stub()

	Finch.call ""
	calledOnce slash, "/ called once"
	slash.reset()

	Finch.call "/"
	neverCalled slash, "/ not called again"
	slash.reset()

	Finch.call ""
	neverCalled slash, "/ not called again"
	slash.reset()

	Finch.call "//"
	neverCalled slash, "/ not called again"
	slash.reset()

	Finch.call "foo"
	neverCalled slash,	"/ not called again"
	calledOnce foo,   	"foo called once"
	slash.reset()
	foo.reset()

	Finch.call "/foo"
	neverCalled slash,	"/ not called again"
	neverCalled foo,  	"foo not called again"
	slash.reset()
	foo.reset()

	Finch.call "/foo/"
	neverCalled slash,	"/ not called again"
	neverCalled foo,  	"foo not called again"
	slash.reset()
	foo.reset()

	Finch.call "foo/"
	neverCalled slash,	"/ not called again"
	neverCalled foo,  	"foo not called again"
	slash.reset()
	foo.reset()

	Finch.call "foo/bar"
	neverCalled slash, 	"/ not called again"
	neverCalled foo,   	"foo not called again"
	calledOnce foo_bar,	"foo/bar called once"
	slash.reset()
	foo.reset()
	foo_bar.reset()

	Finch.call "/foo/bar"
	neverCalled slash,  	"/ not called again"
	neverCalled foo,    	"foo not called again"
	neverCalled foo_bar,	"foo/bar not called again"
	slash.reset()
	foo.reset()
	foo_bar.reset()

	Finch.call "/foo/bar/"
	neverCalled slash,  	"/ not called again"
	neverCalled foo,    	"foo not called again"
	neverCalled foo_bar,	"foo/bar not called again"
	slash.reset()
	foo.reset()
	foo_bar.reset()

	Finch.call "foo/bar/"
	neverCalled slash,  	"/ not called again"
	neverCalled foo,    	"foo not called again"
	neverCalled foo_bar,	"foo/bar not called again"
	slash.reset()
	foo.reset()
	foo_bar.reset()

test "Asynchronous setup, load, and teardown", sinon.test ->
	cb = callbackGroup()
	cb.setup_foo = @stub()
	cb.load_foo = @stub()
	cb.teardown_foo = @stub()
	cb.setup_foo_bar = @stub()
	cb.load_foo_bar = @stub()

	Finch.route "foo",
		setup: (bindings, callback) -> cb.setup_foo bindings, callback
		load: (bindings, callback) -> cb.load_foo bindings, callback
		teardown: (bindings, callback) -> cb.teardown_foo bindings, callback
	Finch.route "foo/bar",
		setup: (bindings, callback) -> cb.setup_foo_bar bindings, callback
		load: (bindings, callback) -> cb.load_foo_bar bindings, callback
		teardown: cb.teardown_foo_bar = @stub()
	Finch.route "[foo/bar]/baz",
		setup: cb.setup_foo_bar_baz = @stub()
		teardown: cb.teardown_foo_bar_baz = @stub()
	Finch.route "quux",
		setup: cb.setup_quux = @stub()

	# Call /foo to start
	Finch.call "/foo"

	calledOnce cb.setup_foo,    	"/foo (before /foo callback): foo setup called once"
	neverCalled cb.load_foo,    	"/foo (after /foo callback): foo load not called"
	neverCalled cb.teardown_foo,	"/foo (after /foo callback): foo teardown not called"

	cb.setup_foo.callArg 1
	calledOnce cb.setup_foo,    	"/foo (after /foo callback): foo setup not called again"
	calledOnce cb.load_foo,     	"/foo (before /foo callback): foo load called once"
	neverCalled cb.teardown_foo,	"/foo (after /foo callback): foo teardown not called"

	cb.load_foo.callArg 1
	calledOnce cb.setup_foo,    	"/foo (after /foo callback): foo setup not called again"
	calledOnce cb.load_foo,     	"/foo (after /foo callback): foo load not called again"
	neverCalled cb.teardown_foo,	"/foo (after /foo callback): foo teardown not called"

	cb.reset()

	# Call /foo/bar/baz next
	Finch.call "/foo/bar/baz"

	calledOnce cb.teardown_foo,  	"/foo/bar/baz (before /foo teardown): foo teardown called once"
	neverCalled cb.setup_foo_bar,	"/foo/bar/baz (before /foo teardown): foo/bar setup not called yet"
	neverCalled cb.load_foo_bar, 	"/foo/bar/baz (before /foo teardown): foo/bar load not called yet"

	cb.teardown_foo.callArg 1

	calledOnce cb.setup_foo_bar,     	"/foo/bar/baz (before /foo/bar callback): foo/bar setup called once"
	neverCalled cb.load_foo_bar,     	"/foo/bar/baz (before /foo/bar callback): foo/bar load not called"
	neverCalled cb.setup_foo_bar_baz,	"/foo/bar/baz (before /foo/bar callback): foo/bar/baz setup not called yet"

	# Call /quux before the call to /foo/bar/baz completes
	Finch.call "/quux"

	calledOnce cb.setup_foo_bar,     	"/quux (before /foo/bar callback): foo/bar setup not called again"
	neverCalled cb.setup_foo_bar_baz,	"/quux (before /foo/bar callback): foo/bar/baz setup not called"
	neverCalled cb.setup_quux,       	"/quux (before /foo/bar callback): quux setup not called yet"

	cb.setup_foo_bar.callArg 1

	equal cb.setup_foo_bar.callCount, 1,       	"/quux (after /foo/bar callback): foo/bar setup not called again"
	equal cb.teardown_foo_bar.callCount, 1,    	"/quux (after /foo/bar callback): foo/bar teardown called"
	equal cb.setup_foo_bar_baz.callCount, 0,   	"/quux (after /foo/bar callback): foo/bar/baz setup not called"
	equal cb.teardown_foo_bar_baz.callCount, 0,	"/quux (after /foo/bar callback): foo/bar/baz teardown not called"
	equal cb.setup_quux.callCount, 1,          	"/quux (after /foo/bar callback): quux setup called"
	calledOnce cb.setup_foo_bar,               	"/quux (after /foo/bar callback): foo/bar setup not called again"
	calledOnce cb.teardown_foo_bar,            	"/quux (after /foo/bar callback): foo/bar teardown called"
	neverCalled cb.setup_foo_bar_baz,          	"/quux (after /foo/bar callback): foo/bar/baz setup not called"
	neverCalled cb.teardown_foo_bar_baz,       	"/quux (after /foo/bar callback): foo/bar/baz teardown not called"
	calledOnce cb.setup_quux,                  	"/quux (after /foo/bar callback): quux setup called"

do ->
	trivialObservableTest = (fn) ->

		Finch.call "/foo"
		calledOnce fn, "observable callback called once"
		lastCalledWithExactly fn, [undefined, undefined], "called with given args"
		fn.reset()

		Finch.call "/foo?sort=asc"
		calledOnce fn, "observable callback called once"
		lastCalledWithExactly fn, ["asc", undefined], "called with given args"
		fn.reset()

		Finch.call "/foo"
		calledOnce fn, "observable callback called once"
		lastCalledWithExactly fn, [undefined, undefined], "called with given args"
		fn.reset()

		Finch.call "/foo?query=unicorn"
		calledOnce fn, "observable callback called once"
		lastCalledWithExactly fn, [undefined, "unicorn"], "called with given args"
		fn.reset()

		Finch.call "/foo?query=unicorn&sort=desc"
		calledOnce fn, "observable callback called once"
		lastCalledWithExactly fn, ["desc", "unicorn"], "called with given args"
		fn.reset()

		Finch.call "/foo?sort=desc&query=unicorn"
		neverCalled fn, "observable callback not called"
		fn.reset()

		Finch.call "/foo"
		calledOnce fn, "observable callback called once"
		lastCalledWithExactly fn, [undefined, undefined], "called with given args"
		fn.reset()

		Finch.call "/foo?Unrelated=Parameter"
		neverCalled fn, "observable callback not called"

	test "Trivial observable test (accessor form)", sinon.test ->

		fn = @stub()

		Finch.route "foo", (bindings) ->
			Finch.observe (params) ->
				fn(params("sort"), params("query"))

		trivialObservableTest(fn)

	test "Trivial observable test (binding array form)", sinon.test ->

		fn = @stub()

		Finch.route "foo", (bindings) ->
			Finch.observe ["sort", "query"], (sort, query) ->
				fn(sort, query)

		trivialObservableTest(fn)

	test "Trivial observable test (binding list form)", sinon.test ->

		fn = @stub()

		Finch.route "foo", (bindings) ->
			Finch.observe "sort", "query", (sort, query) ->
				fn(sort, query)

		trivialObservableTest(fn)

# END trivial observable test

test "Observable dependency tracking", sinon.test ->

	bar_on = @stub()
	bar_off = @stub()

	Finch.route "bar", (bindings) ->
		Finch.observe (params) ->
			if params("flag") then bar_on params("on") else bar_off params("off")

	Finch.call("/bar")

	calledOnce bar_off, "off callback called once"
	neverCalled bar_on, "on callback not called"
	lastCalledWithExactly bar_off, [undefined], "called with given args"
	bar_off.reset()

	Finch.call("/bar?off=Grue")

	calledOnce bar_off, "off callback called once"
	neverCalled bar_on, "on callback not called"
	lastCalledWithExactly bar_off, ["Grue"], "called with given args"
	bar_off.reset()

	Finch.call("/bar?off=Grue&on=Lantern")

	neverCalled bar_off, "off callback not called"
	neverCalled bar_on, "on callback not called"

	Finch.call("/bar?flag=true&off=Grue&on=Lantern")

	neverCalled bar_off, "off callback not called"
	calledOnce bar_on, "on callback called once"
	lastCalledWithExactly bar_on, ["Lantern"], "called with given args"
	bar_on.reset()

	Finch.call("/bar?flag=true&on=Lantern")

	neverCalled bar_off, "off callback not called"
	neverCalled bar_on, "on callback not called"

test "Observable hierarchy 1", sinon.test ->

	foo = @stub()
	bar = @stub()
	id = @stub()

	Finch.route "foo", (bindings) ->
		Finch.observe ["a"], (a) -> foo(a)
	Finch.route "[foo]/bar", (bindings) ->
		Finch.observe ["b"], (b) -> bar(b)
	Finch.route "[foo/bar]/:id", (bindings) ->
		Finch.observe ["c"], (c) -> id(c)

	Finch.call "/foo/bar?&a=1&b=2&c=3"

	calledOnce foo,                  	"foo callback called once"
	lastCalledWithExactly foo, ["1"],	"foo callback args"
	calledOnce bar,                  	"bar callback called once"
	lastCalledWithExactly bar, ["2"],	"bar callback args"
	neverCalled id,                  	"id callback not called"

	foo.reset()
	bar.reset()
	id.reset()

	Finch.call "/foo/bar?a=1&b=2&c=11"

	neverCalled foo,	"foo callback not called"
	neverCalled bar,	"bar callback not called"
	neverCalled id, 	"id callback not called"

	foo.reset()
	bar.reset()
	id.reset()

	Finch.call "/foo?a=21&b=2&c=23"

	calledOnce foo,                   	"foo callback called once"
	lastCalledWithExactly foo, ["21"],	"foo callback args"
	neverCalled bar,                  	"bar callback not called"
	neverCalled id,                   	"id callback not called"

	foo.reset()
	bar.reset()
	id.reset()

	Finch.call "/foo?a=31&b=32&c=23"

	calledOnce foo,                   	"foo callback called once"
	lastCalledWithExactly foo, ["31"],	"foo callback args"
	neverCalled bar,                  	"bar callback not called"
	neverCalled id,                   	"id callback not called"

test "Observable hierarchy 2", sinon.test ->

	slash = @stub()
	foo = @stub()
	bar = @stub()
	id = @stub()

	Finch.route "/", (bindings) ->
		Finch.observe ["x"], (x) -> slash(x)
	Finch.route "[/]foo", (bindings) ->
		Finch.observe ["a"], (a) -> foo(a)
	Finch.route "[/foo]/bar", (bindings) ->
		Finch.observe ["b"], (b) -> bar(b)
	Finch.route "[/foo/bar]/:id", (bindings) ->
		Finch.observe ["c"], (c) -> id(c)

	Finch.call "/foo/bar?x=0&a=1&b=2&c=3"

	calledOnce slash,                  	"/ callback called once"
	lastCalledWithExactly slash, ["0"],	"/ callback args"
	calledOnce foo,                    	"foo callback called once"
	lastCalledWithExactly foo, ["1"],  	"foo callback args"
	calledOnce bar,                    	"bar callback called once"
	lastCalledWithExactly bar, ["2"],  	"bar callback args"
	neverCalled id,                    	"id callback not called"

	slash.reset()
	foo.reset()
	bar.reset()
	id.reset()

	Finch.call "/foo/bar?x=0&a=1&b=10&c=11"

	neverCalled slash,                	"/ callback not called"
	neverCalled foo,                  	"foo callback not called"
	calledOnce bar,                   	"bar callback called once"
	lastCalledWithExactly bar, ["10"],	"bar callback args"
	neverCalled id,                   	"id callback not called"

test "Observable value types", sinon.test ->

	stub = @stub()

	Finch.route "/", (bindings) ->
		Finch.observe ["x"], (x) -> stub(x)

	Finch.call "/?x=123"
	calledOnce stub,                    	"/ callback called once"
	lastCalledWithExactly stub, ["123"],	"/ called with correct 123"
	stub.reset()

	Finch.call "/?x=123.456"
	calledOnce stub,                        	"/ callback called once"
	lastCalledWithExactly stub, ["123.456"],	"/ called with correct 123.456"
	stub.reset()

	Finch.call "/?x=true"
	calledOnce stub,                     	"/ callback called once"
	lastCalledWithExactly stub, ["true"],	"/ called with correct true"
	stub.reset()

	Finch.call "/?x=false"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, ["false"],	"/ called with correct false"
	stub.reset()

	Finch.call "/?x=stuff"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, ["stuff"],	"/ called with correct stuff"
	stub.reset()

	Finch.options(CoerceParameterTypes: true)

	Finch.call "/?x=123"
	calledOnce stub,                  	"/ callback called once"
	lastCalledWithExactly stub, [123],	"/ called with correct 123"
	stub.reset()

	Finch.call "/?x=123.456"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, [123.456],	"/ called with correct 123.456"
	stub.reset()

	Finch.call "/?x=true"
	calledOnce stub,                   	"/ callback called once"
	lastCalledWithExactly stub, [true],	"/ called with correct true"
	stub.reset()

	Finch.call "/?x=false"
	calledOnce stub,                    	"/ callback called once"
	lastCalledWithExactly stub, [false],	"/ called with correct false"
	stub.reset()

	Finch.call "/?x=stuff"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, ["stuff"],	"/ called with correct stuff"
	stub.reset()

test "Binding value types", sinon.test ->

	stub = @stub()

	Finch.route "/:x", ({x}) -> stub(x)

	Finch.call "/123"
	calledOnce stub,                    	"/ callback called once"
	lastCalledWithExactly stub, ['123'],	"/ called with correct 123"
	stub.reset()

	Finch.call "/123.456"
	calledOnce stub,                        	"/ callback called once"
	lastCalledWithExactly stub, ['123.456'],	"/ called with correct 123.456"
	stub.reset()

	Finch.call "/true"
	calledOnce stub,                     	"/ callback called once"
	lastCalledWithExactly stub, ['true'],	"/ called with correct true"
	stub.reset()

	Finch.call "/false"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, ['false'],	"/ called with correct false"
	stub.reset()

	Finch.call "/stuff"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, ["stuff"],	"/ called with correct stuff"
	stub.reset()

	Finch.options(CoerceParameterTypes: true)

	Finch.call "/123"
	calledOnce stub,                  	"/ callback called once"
	lastCalledWithExactly stub, [123],	"/ called with correct 123"
	stub.reset()

	Finch.call "/123.456"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, [123.456],	"/ called with correct 123.456"
	stub.reset()

	Finch.call "/true"
	calledOnce stub,                   	"/ callback called once"
	lastCalledWithExactly stub, [true],	"/ called with correct true"
	stub.reset()

	Finch.call "/false"
	calledOnce stub,                    	"/ callback called once"
	lastCalledWithExactly stub, [false],	"/ called with correct false"
	stub.reset()

	Finch.call "/stuff"
	calledOnce stub,                      	"/ callback called once"
	lastCalledWithExactly stub, ["stuff"],	"/ called with correct stuff"
	stub.reset()

test "Finch.navigate", sinon.test ->

	window.location.hash = ""

	hash = ->
		return "#" + ( window.location.href.split("#", 2)[1] ? "" )

	homeRegex = /^#?\/home/
	homeNewsRegex = /^#?\/home\/news/
	homeAccountRegex = /^#?\/home\/account/
	homeNewsArticleRegex = /^#?\/home\/news\/article/
	helloWorldRegex = /^#?\/hello%20world/

	#Navigate to just a single route
	Finch.navigate("/home")
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"

	Finch.navigate("/home/news")
	ok homeNewsRegex.test(hash()), "Navigate called and changed hash to /home/news"

	Finch.navigate("/home")
	ok homeRegex.test(hash()), "fNavigate called and changed hash to /home"

	#navigate to a route and query parameters
	Finch.navigate("/home", foo:"bar")
	ok homeRegex.test(hash()), "Navigate remained on the /home route"
	ok hash().indexOf("foo=bar") > -1, "Had correct query parameter set"

	#navigate to a route and query parameters
	Finch.navigate("/home", hello:"world")
	ok homeRegex.test(hash()), "Navigate remained on the /home route"
	ok hash().indexOf("foo=bar") is -1, "Removed foo=bar"
	ok hash().indexOf("hello=world") > -1, "Added hello=world"

	#Navigate to only a new hash
	Finch.navigate(foos:"bars")
	ok homeRegex.test(hash()), "Navigate remained on the /home route"
	ok hash().indexOf("hello=world") is -1, "Removed hello=world"
	ok hash().indexOf("foos=bars") > -1, "Added foos=bars"

	#Only update the hash
	Finch.navigate(foos:"baz")
	ok homeRegex.test(hash()), "Navigate remained on the /home route"
	ok hash().indexOf("foos=baz") > -1, "Changed to foos=baz"

	Finch.navigate(hello:"world", true)
	ok homeRegex.test(hash()), "Navigate remained on the /home route"
	ok hash().indexOf("foos=baz") > -1, "Kept foos=baz"
	ok hash().indexOf("hello=world") > -1, "Added hello=world"

	#Remove a paremeter
	Finch.navigate(foos:null, true)
	ok homeRegex.test(hash()), "Navigate remained on the /home route"
	ok hash().indexOf("foos=baz") is -1, "Removed foos=baz"
	ok hash().indexOf("hello=world") > -1, "Kept hello=world"

	#Make siure the doUpdate navigate keeps the query string
	Finch.navigate("/home/news", true)
	ok homeNewsRegex.test(hash()), "Navigate called and changed hash to /home/news"
	ok hash().indexOf("hello=world") > -1, "Kept hello=world"

	#Make sure we add proper escaping
	Finch.navigate("/hello world", {})
	ok helloWorldRegex.test(hash()), "Navigated to /hello%20world"
	ok hash().indexOf("hello=world") is -1, "Removed hello=world"

	Finch.navigate("/hello world", foo:"bar bar")
	ok helloWorldRegex.test(hash()), "Navigate remained at /hello%20world"
	ok hash().indexOf("foo=bar%20bar") > -1, "Added and escaped foo=bar bar"

	Finch.navigate(foo:"baz baz")
	ok helloWorldRegex.test(hash()), "Navigate remained at /hello%20world"
	ok hash().indexOf("foo=bar%20bar") is -1, "Removed foo=bar bar"
	ok hash().indexOf("foo=baz%20baz") > -1, "Added and escaped foo=baz baz"

	Finch.navigate(hello:'world world', true)
	ok helloWorldRegex.test(hash()), "Navigate remained at /hello%20world"
	ok hash().indexOf("foo=baz%20baz") > -1, "Kept and escaped foo=baz baz"
	ok hash().indexOf("hello=world%20world") > -1, "Added and escaped hello=world world"

	#Make sure we don't add multiple '?'
	Finch.navigate("/home?foo=bar",hello:"world")
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"
	ok hash().indexOf("foo=bar") > -1, "Had correct query parameter set foo=bar"
	ok hash().indexOf("hello=world") > -1, "Had correct query parameter set hello=world"
	equal hash().split("?").length-1, 1, "Correct number of '?'"
	equal hash().split("&").length-1, 1, "Correct number of '&'"

	Finch.navigate("/home?foo=bar",{hello:"world",foo:"baz"})
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"
	ok hash().indexOf("foo=bar") is -1, "foo=bar not set"
	ok hash().indexOf("foo=baz") > -1, "Had correct query parameter set foo=baz"
	ok hash().indexOf("hello=world") > -1, "Had correct query parameter set hello=world"
	equal hash().split("?").length-1, 1, "Correct number of '?'"
	equal hash().split("&").length-1, 1, "Correct number of '&'"

	Finch.navigate("/home?foo=bar",{hello:"world",free:"bird"})
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"
	ok hash().indexOf("foo=bar") > -1, "Had correct query parameter set foo=bar"
	ok hash().indexOf("free=bird") > -1, "Had correct query parameter set free=bird"
	ok hash().indexOf("hello=world") > -1, "Had correct query parameter set hello=world"
	equal hash().split("?").length-1, 1, "Correct number of '?'"
	equal hash().split("&").length-1, 2, "Correct number of '&'"

	#Account for the hash character
	Finch.navigate("#/home", true)
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"
	ok hash().indexOf("free=bird") > -1, "Had correct query parameter set free=bird"
	ok hash().indexOf("hello=world") > -1, "Had correct query parameter set hello=world"

	Finch.navigate("#/home")
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"
	ok hash().indexOf("free=bird") is -1, "Had correct query parameter set free=bird"
	ok hash().indexOf("hello=world") is -1, "Had correct query parameter set hello=world"

	Finch.navigate("#/home/news",{free:"birds",hello:"worlds"})
	ok homeNewsRegex.test(hash()), "Navigate called and changed hash to /home"
	ok hash().indexOf("free=birds") > -1, "Had correct query parameter set free=birds"
	ok hash().indexOf("hello=worlds") > -1, "Had correct query parameter set hello=worlds"

	Finch.navigate("#/home/news", {foo:"bar"}, true)
	ok homeNewsRegex.test(hash()), "Navigate called and changed hash to /home"
	ok hash().indexOf("free=birds") > -1, "Had correct query parameter set free=birds"
	ok hash().indexOf("hello=worlds") > -1, "Had correct query parameter set hello=worlds"
	ok hash().indexOf("foo=bar") > -1, "Had correct query parameter set hello=worlds"

	#Test relative navigation
	Finch.navigate("/home/news")
	ok homeNewsRegex.test(hash()), "Navigate called and changed hash to /home/news"

	Finch.navigate("../")
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"

	Finch.navigate("./")
	ok homeRegex.test(hash()), "Navigate called and changed hash to /home"

	Finch.navigate("./news")
	ok homeNewsRegex.test(hash()), "Navigate called and changed hash to /home/news"

	Finch.navigate("/home/news/article")
	ok homeNewsArticleRegex.test(hash()), "Navigate called and changed hash to /home/news/article"

	Finch.navigate("../../account")
	ok homeAccountRegex.test(hash()), "Navigate called and changed hash to /home/account"

test "Finch.listen and Finch.ignore", sinon.test ->

	#Default the necessary window methods, if they don't exist
	window.hasOwnProperty ?= (prop) -> (prop of @)

	cb = callbackGroup()
	cb.attachEvent = @stub()
	cb.detachEvent = @stub()
	cb.addEventListener = @stub()
	cb.removeEventListener = @stub()
	cb.setInterval = @stub()
	cb.clearInterval = @stub()

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

	ok Finch.listen(), "Finch successfully listening"
	equal cb.addEventListener.callCount, 0,"addEventListener not called"
	equal cb.attachEvent.callCount, 0,"attachEvent not called"
	equal cb.setInterval.callCount, 1,"setInterval called once"

	ok Finch.ignore(), "Finch successfuly ignoring"
	equal cb.removeEventListener.callCount, 0, "removeEventListener not called"
	equal cb.detachEvent.callCount, 0, "detachEvent not called"
	equal cb.clearInterval.callCount, 1, "clearInterval called once"

	# Test the add/remove EventListener methods
	clearWindowMethods()
	window.onhashchange = "defined"
	window.addEventListener = cb.addEventListener
	window.removeEventListener = cb.removeEventListener
	cb.reset()

	ok Finch.listen(), "Finch successfully listening"
	equal cb.addEventListener.callCount, 1,"addEventListener Called once"
	equal cb.attachEvent.callCount, 0,"attachEvent not called"
	equal cb.setInterval.callCount, 0,"setInterval not called"

	ok Finch.ignore(), "Finch successfuly ignoring"
	equal cb.removeEventListener.callCount, 1, "removeEventListener Called once"
	equal cb.detachEvent.callCount, 0, "detachEvent not called"
	equal cb.clearInterval.callCount, 0, "clearInterval not called"

	#Test the attach/detach Event methods
	clearWindowMethods()
	window.onhashchange = "defined"
	window.attachEvent = cb.attachEvent
	window.detachEvent = cb.detachEvent
	cb.reset()

	ok Finch.listen(), "Finch successfully listening"
	equal cb.addEventListener.callCount, 0,"addEventListener not called"
	equal cb.attachEvent.callCount, 1,"attachEvent called once"
	equal cb.setInterval.callCount, 0,"setInterval not called"

	ok Finch.ignore(), "Finch successfuly ignoring"
	equal cb.removeEventListener.callCount, 0, "removeEventListener not called"
	equal cb.detachEvent.callCount, 1, "detachEvent called once"
	equal cb.clearInterval.callCount, 0, "clearInterval not called"

test "Finch.abort", sinon.test ->

	homeStub = @stub()
	fooStub = @stub()

	Finch.route "/home", (bindings, continuation) -> homeStub()
	Finch.route "/foo", (bindings, continuation) -> fooStub()

	#make a call to home
	Finch.call("home")
	equal homeStub.callCount, 1, "Home called correctly"
	equal fooStub.callCount, 0, "Foo not called"

	homeStub.reset()
	fooStub.reset()

	#Call foo
	Finch.call("foo")
	equal homeStub.callCount, 0, "Home not called"
	equal fooStub.callCount, 0, "Foo not called"

	homeStub.reset()
	fooStub.reset()

	#abort first, then call foo
	Finch.abort()
	Finch.call("foo")
	equal homeStub.callCount, 0, "Home not called"
	equal fooStub.callCount, 1, "Foo called correctly"

test "Route finding backtracking 1", sinon.test ->

	Finch.route "/foo",          	foo = @stub()
	Finch.route "[/foo]/bar",    	bar = @stub()
	Finch.route "[/foo/bar]/baz",	baz = @stub()

	Finch.route "/:var1",              	var1 = @stub()
	Finch.route "[/:var1/]:var2",      	var2 = @stub()
	Finch.route "[/:var1/:var2]/:var3",	var3 = @stub()

	# Test routes

	Finch.call "/foo/nope"

	calledOnce var1,	"var1 called once"
	lastCalledWithExactly var1, [{var1: "foo"}], "var1 called with binding for var1"
	calledOnce var2,	"var2 called once"
	lastCalledWithExactly var2, [{var1: "foo", var2: "nope"}], "var2 called with bindings for var1 and var2"
	neverCalled foo,	"foo never called"

test "Route finding backtracking 2", sinon.test ->

	Finch.route "/foo",          	foo = @stub()
	Finch.route "[/foo]/bar",    	bar = @stub()
	Finch.route "[/foo/bar]/baz",	baz = @stub()

	Finch.route "/:var1",              	var1 = @stub()
	Finch.route "[/:var1/]:var2",      	var2 = @stub()
	Finch.route "[/:var1/:var2]/:var3",	var3 = @stub()

	# Test routes

	Finch.call "/foo/bar/nope"

	calledOnce var1,	"var1 called once"
	lastCalledWithExactly var1, [{var1: "foo"}], "var1 called with binding for var1"
	calledOnce var2,	"var2 called once"
	lastCalledWithExactly var2, [{var1: "foo", var2: "bar"}], "var2 called with bindings for var1 and var2"
	calledOnce var3,	"var3 called once"
	lastCalledWithExactly var3, [{var1: "foo", var2: "bar", var3: "nope"}], "var3 called with bindings for var1, var2 and var3"
	neverCalled foo,	"foo never called"
	neverCalled bar,	"bar never called"

test "Optional parameter parsing", sinon.test ->

	Finch.route "/"
	Finch.route "/home/news/:id", foo = @stub()
	Finch.call "/home/news/1234"

	calledOnce foo, "foo called once"
	lastCalledWithExactly foo, [{id: "1234"}], "foo called with int parameter"

	foo.reset()

	Finch.options { CoerceParameterTypes: true }

	Finch.call "/"
	Finch.call "/home/news/1234"

	calledOnce foo, "foo called once"
	lastCalledWithExactly foo, [{id: 1234}], "foo called with string parameter"

test "Variable parent routes called if no children found", sinon.test ->
	cb = callbackGroup()

	Finch.route "/", 
		'setup': cb.slash_setup = @stub()
		'load': cb.slash_load = @stub()
		'unload': cb.slash_unload = @stub()
		'teardown': cb.slash_teardown = @stub()

	Finch.route "[/]users/profile", 
		'setup': cb.profile_setup = @stub()
		'load': cb.profile_load = @stub()
		'unload': cb.profile_unload = @stub()
		'teardown': cb.profile_teardown = @stub()

	Finch.route "[/]:page", 
		'setup': cb.page_setup = @stub()
		'load': cb.page_load = @stub()
		'unload': cb.page_unload = @stub()
		'teardown': cb.page_teardown = @stub()

	Finch.call "/users"

	calledOnce cb.slash_setup, "slash setup called once"
	neverCalled cb.slash_load, "slash load never called"
	neverCalled cb.slash_unload, "slash unload never called"
	neverCalled cb.slash_teardown, "slash teardown never called"

	calledOnce cb.page_setup, "page setup called once"
	calledOnce cb.page_load, "page load called once"
	neverCalled cb.page_unload, "page unload never called"
	neverCalled cb.page_teardown, "page unload never called"

	neverCalled cb.profile_setup, "profile setup never called"
	neverCalled cb.profile_load, "profile load never called"
	neverCalled cb.profile_unload, "profile unload never called"
	neverCalled cb.profile_teardown, "profile teardown never called"

	lastCalledWithExactly cb.page_setup, [{page: "users"}], "page setup called with correct parameters"
	lastCalledWithExactly cb.page_load, [{page: "users"}], "page setup called with correct parameters"

test "Test double deep variable basic routes up and down", sinon.test ->
	cb = callbackGroup()
	Finch.route "/project/:project_id", cb.project_id_load = @stub()
	Finch.route "[/project/:project_id]/milestone", cb.milestone_load = @stub()
	Finch.route "[/project/:project_id/milestone]/:milestone_id", cb.milestone_id_load = @stub()

	Finch.call "/project/1234"
	calledOnce cb.project_id_load
	neverCalled cb.milestone_load
	neverCalled cb.milestone_id_load
	lastCalledWithExactly cb.project_id_load, [{project_id: "1234"}]
	cb.reset()

	Finch.call "/project/1234/milestone"
	neverCalled cb.project_id_load
	calledOnce cb.milestone_load
	neverCalled cb.milestone_id_load
	lastCalledWithExactly cb.milestone_load, [{project_id: "1234"}]
	cb.reset()

	Finch.call "/project/1234/milestone/5678"
	neverCalled cb.project_id_load
	neverCalled cb.milestone_load
	calledOnce cb.milestone_id_load
	lastCalledWithExactly cb.milestone_id_load, [{project_id: "1234", milestone_id: "5678"}]
	cb.reset()

	Finch.call "/project/1234/milestone"
	neverCalled cb.project_id_load
	calledOnce cb.milestone_load
	neverCalled cb.milestone_id_load
	lastCalledWithExactly cb.milestone_load, [{project_id: "1234"}]
	cb.reset()

	Finch.call "/project/1234"
	calledOnce cb.project_id_load
	neverCalled cb.milestone_load
	neverCalled cb.milestone_id_load
	lastCalledWithExactly cb.project_id_load, [{project_id: "1234"}]
	cb.reset()

test "Test double deep variable basic routes up and down", sinon.test ->
	cb = callbackGroup()
	Finch.route "/project/:project_id/milestone",
		setup: cb.milestone_setup = @stub()
		load: cb.milestone_load = @stub()
		unload: cb.milestone_unload = @stub()
		teardown: cb.milestone_teardown = @stub()
	#END rout

	Finch.route "[/project/:project_id/milestone]/:milestone_id",
		setup: cb.milestone_id_setup = @stub()
		load: cb.milestone_id_load = @stub()
		unload: cb.milestone_id_unload = @stub()
		teardown: cb.milestone_id_teardown = @stub()
	#END rout

	Finch.call "/project/1234/milestone"
	calledOnce cb.milestone_setup
	calledOnce cb.milestone_load
	neverCalled cb.milestone_unload
	neverCalled cb.milestone_teardown

	neverCalled cb.milestone_id_setup
	neverCalled cb.milestone_id_load
	neverCalled cb.milestone_id_unload
	neverCalled cb.milestone_id_teardown

	lastCalledWithExactly cb.milestone_setup, [{project_id: "1234"}]
	lastCalledWithExactly cb.milestone_load, [{project_id: "1234"}]

	cb.reset()

	Finch.call "/project/1234/milestone/5678"
	neverCalled cb.milestone_setup
	neverCalled cb.milestone_load
	calledOnce cb.milestone_unload
	neverCalled cb.milestone_teardown

	calledOnce cb.milestone_id_setup
	calledOnce cb.milestone_id_load
	neverCalled cb.milestone_id_unload
	neverCalled cb.milestone_id_teardown

	lastCalledWithExactly cb.milestone_unload, [{project_id: "1234"}]

	lastCalledWithExactly cb.milestone_id_setup, [{project_id: "1234", milestone_id: "5678"}]
	lastCalledWithExactly cb.milestone_id_load, [{project_id: "1234", milestone_id: "5678"}]
	cb.reset()


	Finch.call "/project/1234/milestone"
	neverCalled cb.milestone_setup
	calledOnce cb.milestone_load
	neverCalled cb.milestone_unload
	neverCalled cb.milestone_teardown

	neverCalled cb.milestone_id_setup
	neverCalled cb.milestone_id_load
	calledOnce cb.milestone_id_unload
	calledOnce cb.milestone_id_teardown

	lastCalledWithExactly cb.milestone_load, [{project_id: "1234"}]

	lastCalledWithExactly cb.milestone_id_unload, [{project_id: "1234", milestone_id: "5678"}]
	lastCalledWithExactly cb.milestone_id_teardown, [{project_id: "1234", milestone_id: "5678"}]
	cb.reset()
#END test

test "Test Finch.route chaining", sinon.test ->
  newFinch = Finch.route("foo", -> true)
  result   = QUnit.equiv(Finch, newFinch)
  QUnit.push(result, newFinch, Finch, 'Finch.route returned this for chaining')
#END test
