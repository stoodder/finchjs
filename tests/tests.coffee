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

	ok foo_bar.called, "foo/bar called"

	Finch.call "/baz/quux"

	ok baz_quux.called, "baz/quux called"

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

	ok !foo.called, "foo not called again"
	ok !foo_bar.called, "foo/bar not called again"
	calledOnce foo_bar_id, "foo/bar/id called once"
	lastCalledWithExactly foo_bar_id, [{ id: "123" }], "foo/bar/id bindings"
	foo_bar_id.reset()

	Finch.call "/foo/bar/123"

	ok !foo.called, "foo not called again"
	ok !foo_bar.called, "foo/bar not called again"
	ok !foo_bar_id.called, "foo/bar/id not called again"

	Finch.call "/foo/bar/123?x=Hello&y=World"

	ok !foo.called, "foo not called again"
	ok !foo_bar.called, "foo/bar not called again"
	ok !foo_bar_id.called, "foo/bar/id not called again"

	Finch.call "/foo/baz/456"

	ok !foo.called, "foo not called again"
	ok foo_baz.called, "foo/baz called"
	ok foo_baz_id.called, "foo/baz/id called"
	ok foo_baz.calledBefore(foo_baz_id), "foo/baz called before foo/baz/id"
	lastCalledWithExactly foo_baz_id, [{ id: "456" }], "foo/baz/id bindings"
	foo_baz.reset()
	foo_baz_id.reset()

	Finch.call "/quux/789?band=Sunn O)))&genre=Post-Progressive Fridgecore"

	ok quux.called, "quux called"
	ok quux_id.called, "quux/id called"
	ok quux.calledBefore(quux_id), "quux called before quux/id"
	lastCalledWithExactly quux_id, [{ id: "789" }], "quux/id bindings"

test "More hierarchical routing", sinon.test ->

	Finch.route "foo",           	foo = @stub()
	Finch.route "[foo]/bar/baz", 	foo_bar_baz = @stub()
	Finch.route "foo/bar",       	foo_bar = @stub()
	Finch.route "[foo/bar]/quux",	foo_bar_quux = @stub()

	# Test routes

	Finch.call "/foo/bar/baz"

	ok foo.called, "foo called"
	ok foo_bar_baz.called, "foo/bar/baz called"
	ok foo.calledBefore(foo_bar_baz), "foo called before foo/bar/baz"
	ok !foo_bar.called, "foo/bar NOT called"
	foo.reset()
	foo_bar_baz.reset()

	Finch.call "/foo/bar/quux"
	ok foo_bar.called, "foo/bar called"
	ok foo_bar_quux.called, "foo/bar/quux called"
	ok foo_bar.calledBefore(foo_bar_quux), "foo/bar called before foo/bar/quux"
	ok !foo.called, "foo NOT called"

test "Hierarchical routing with /", sinon.test ->

	Finch.route "/",         	slash = @stub()
	Finch.route "[/]foo",    	foo = @stub()
	Finch.route "[/foo]/bar",	bar = @stub()

	# Test routes

	Finch.call "/foo"

	calledOnce slash,	"/ called once"
	calledOnce foo,  	"foo called once"
	calledOnce bar,  	"bar never called"

test "Simple routing with setup/teardown", sinon.test ->

	cb = callbackGroup()

	Finch.route "/",
		setup:   	cb.setup_slash = @stub()
		teardown:	cb.teardown_slash = @stub()
	Finch.route "/foo",
		setup:   	cb.setup_foo = @stub()
		teardown:	cb.teardown_foo = @stub()
	Finch.route "foo/bar",
		setup:   	cb.setup_foo_bar = @stub()
		teardown:	cb.teardown_foo_bar = @stub()

	# Test routes

	Finch.call "/"

	calledOnce cb.setup_slash,    	'/: / setup called once'
	neverCalled cb.teardown_slash,	'/: / teardown not called'
	cb.reset()

	Finch.call "/foo"

	neverCalled cb.setup_slash,  	'/foo: / setup not called'
	calledOnce cb.teardown_slash,	'/foo: / teardown called once'
	calledOnce cb.setup_foo,     	'/foo: foo setup called once'
	neverCalled cb.teardown_foo, 	'/foo: foo teardown not called'
	cb.reset()

	Finch.call "/foo/bar"

	neverCalled cb.setup_slash,     	'/foo/bar: / setup not called'
	neverCalled cb.teardown_slash,  	'/foo/bar: / teardown not called'
	neverCalled cb.setup_foo,       	'/foo/bar: foo setup not called'
	calledOnce cb.teardown_foo,            	'/foo/bar: foo teardown called once'
	calledOnce cb.setup_foo_bar,           	'/foo/bar: foo/bar setup called once'
	neverCalled cb.teardown_foo_bar,	'/foo/bar: foo/bar teardown not called'
	cb.reset()

	Finch.call "/foo/bar?baz=quux"

	neverCalled cb.setup_slash,     	'/foo/bar?baz=quux: / setup not called'
	neverCalled cb.teardown_slash,  	'/foo/bar?baz=quux: / teardown not called'
	neverCalled cb.setup_foo,       	'/foo/bar?baz=quux: foo setup not called'
	neverCalled cb.teardown_foo,    	'/foo/bar?baz=quux: foo teardown not called'
	neverCalled cb.setup_foo_bar,   	'/foo/bar?baz=quux: foo/bar setup not called'
	neverCalled cb.teardown_foo_bar,	'/foo/bar?baz=quux: foo/bar teardown not called'
	cb.reset()

	Finch.call "/foo/bar?baz=xyzzy"

	neverCalled cb.setup_slash,     	'/foo/bar?baz=xyzzy: / setup not called'
	neverCalled cb.teardown_slash,  	'/foo/bar?baz=xyzzy: / teardown not called'
	neverCalled cb.setup_foo,       	'/foo/bar?baz=xyzzy: foo setup not called'
	neverCalled cb.teardown_foo,    	'/foo/bar?baz=xyzzy: foo teardown not called'
	neverCalled cb.setup_foo_bar,   	'/foo/bar?baz=xyzzy: foo/bar setup not called'
	neverCalled cb.teardown_foo_bar,	'/foo/bar?baz=xyzzy: foo/bar teardown not called'
	cb.reset()

test "Hierarchical routing with setup/teardown", sinon.test ->

	cb = callbackGroup()

	Finch.route "foo",
		setup:   	cb.setup_foo = @stub()
		teardown:	cb.teardown_foo = @stub()
	Finch.route "[foo]/bar",
		setup:   	cb.setup_foo_bar = @stub()
		teardown:	cb.teardown_foo_bar = @stub()
	Finch.route "[foo/bar]/:id",
		setup:   	cb.setup_foo_bar_id = @stub()
		teardown:	cb.teardown_foo_bar_id = @stub()
	Finch.route "[foo]/baz",
		setup:   	cb.setup_foo_baz = @stub()
		teardown:	cb.teardown_foo_baz = @stub()
	Finch.route "[foo/baz]/:id",
		setup:   	cb.setup_foo_baz_id = @stub()
		teardown:	cb.teardown_foo_baz_id = @stub()

	# Test routes

	Finch.call "/foo"

	ok cb.setup_foo.called,	"/foo: foo setup"
	cb.reset()

	Finch.call "/foo/bar"

	ok !cb.setup_foo.called,   	"/foo/bar: no foo setup"
	ok !cb.teardown_foo.called,	"/foo/bar: no foo teardown"
	ok cb.setup_foo_bar.called,	"/foo/bar: foo/bar setup"
	cb.reset()

	Finch.call "/foo"

	ok cb.teardown_foo_bar.called,	"/foo return: foo/bar teardown"
	ok !cb.setup_foo.called,      	"/foo return: no foo setup"
	cb.reset()

	Finch.call "/foo/bar/123?x=abc"
	ok !cb.teardown_foo.called,   	"/foo/bar/123: no foo teardown"
	ok !cb.setup_foo.called,      	"/foo/bar/123: no foo setup"
	ok cb.setup_foo_bar.called,   	"/foo/bar/123: foo/bar setup"
	ok cb.setup_foo_bar_id.called,	"/foo/bar/123: foo/bar/id setup"
	cb.reset()

	Finch.call "/foo/bar/456?x=aaa&y=zzz"

	ok cb.teardown_foo_bar_id.called,	"/foo/bar/456?x=aaa&y=zzz: foo/bar/id teardown"
	ok cb.setup_foo_bar_id.called,   	"/foo/bar/456?x=aaa&y=zzz: foo/bar/id setup"
	cb.reset()

	Finch.call "/foo/bar/456?x=bbb&y=zzz"

	ok !cb.setup_foo_bar_id.called,	"/foo/bar/456?x=bbb&y=zzz: no foo/bar/id setup"
	cb.reset()

	Finch.call "/foo/bar/456?y=zzz&x=bbb"

	ok !cb.setup_foo_bar_id.called,	"/foo/bar/456?y=zzz&x=bbb: no foo/bar/id setup"
	cb.reset()

	Finch.call "/foo/baz/789"

	ok cb.teardown_foo_bar_id.called, 	"/foo/baz/789: foo/baz/id teardown"
	ok cb.teardown_foo_bar.called,    	"/foo/baz/789: foo/bar teardown"
	ok !cb.teardown_foo.called,       	"/foo/baz/789: no foo teardown"
	ok !cb.setup_foo.called,          	"/foo/baz/789: no foo setup"
	ok cb.setup_foo_baz.calledOnce,   	"/foo/baz/789: foo/baz setup"
	ok cb.setup_foo_baz_id.calledOnce,	"/foo/baz/789: foo/baz/id setup"
	cb.reset()

	Finch.call "/foo/baz/abc?term=Hello"

	ok cb.teardown_foo_baz_id.called,	"/foo/baz/abc?term=Hello: foo/baz/id teardown"
	ok cb.setup_foo_baz_id.called,   	"/foo/baz/abc?term=Hello: foo/baz/id setup"
	cb.reset()

	Finch.call "/foo/baz/abc?term=World"

	ok !cb.teardown_foo_baz_id.called,	"/foo/baz/abc?term=World: no foo/baz/id teardown"
	ok !cb.setup_foo_baz_id.called,   	"/foo/baz/abc?term=World: no foo/baz/id setup"

test "Calling with context", sinon.test ->

	Finch.route "foo",
		setup:   	setup_foo = @stub()
		teardown:	teardown_foo = @stub()
	Finch.route "bar", @stub()

	# Test routes

	Finch.call "/foo"

	calledOnce setup_foo, 'foo setup called once'
	context = setup_foo.getCall(0).thisValue

	Finch.call "/bar"
	ok teardown_foo.calledOn(context), 'foo teardown called on same context as setup'

test "Hierarchical calling with context", sinon.test ->

	Finch.route "foo",
		setup:   	setup_foo = @stub()
		teardown:	teardown_foo = @stub()
	Finch.route "[foo]/bar",
		setup:   	setup_foo_bar = @stub()
		teardown:	teardown_foo_bar = @stub()
	Finch.route "baz", @stub()

	# Test routes

	Finch.call "/foo"

	calledOnce setup_foo, 'foo setup called once'
	foo_context = setup_foo.getCall(0).thisValue

	Finch.call "/foo/bar"

	calledOnce setup_foo_bar, 'foo/bar setup called once'
	foo_bar_context = setup_foo_bar.getCall(0).thisValue

	notEqual foo_context, foo_bar_context, 'foo/bar should be called on a different context than foo'

	Finch.call "/baz"

	calledOnce teardown_foo_bar, 'foo/bar teardown called once'
	calledOnce teardown_foo, 'foo teardown called once'
	ok teardown_foo_bar.calledBefore(teardown_foo), 'foo/bar teardown called before foo teardown'

	ok teardown_foo_bar.calledOn(foo_bar_context), 'foo/bar teardown called on same context as setup'
	ok teardown_foo.calledOn(foo_context), 'foo teardown called on same context as'

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
	calledOnce foo,          	"foo called once"
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
	neverCalled slash,	"/ not called again"
	neverCalled foo,  	"foo not called again"
	calledOnce foo_bar,      	"foo/bar called once"
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

test "Asynchronous setup/teardown", sinon.test ->
	cb = callbackGroup()
	cb.setup_foo = @stub()
	cb.teardown_foo = @stub()
	cb.setup_foo_bar = @stub()

	Finch.route "foo",
		setup: (bindings, callback) -> cb.setup_foo bindings, callback
		teardown: (bindings, callback) -> cb.teardown_foo bindings, callback
	Finch.route "foo/bar",
		setup: (bindings, callback) -> cb.setup_foo_bar bindings, callback
		teardown: cb.teardown_foo_bar = @stub()
	Finch.route "[foo/bar]/baz",
		setup: cb.setup_foo_bar_baz = @stub()
		teardown: cb.teardown_foo_bar_baz = @stub()
	Finch.route "quux",
		setup: cb.setup_quux = @stub()

	# Call /foo to start
	Finch.call "/foo"

	calledOnce cb.setup_foo,	"/foo (before /foo callback): foo setup called once"

	cb.setup_foo.callArg 1
	calledOnce cb.setup_foo,	"/foo (after /foo callback): foo setup not called again"

	cb.reset()

	# Call /foo/bar/baz next
	Finch.call "/foo/bar/baz"

	calledOnce cb.teardown_foo,         	"/foo/bar/baz (before /foo teardown): foo teardown called once"
	neverCalled cb.setup_foo_bar,	"/foo/bar/baz (before /foo teardown): foo/bar setup not called yet"

	cb.teardown_foo.callArg 1

	calledOnce cb.setup_foo_bar,            	"/foo/bar/baz (before /foo/bar callback): foo/bar setup called once"
	neverCalled cb.setup_foo_bar_baz,	"/foo/bar/baz (before /foo/bar callback): foo/bar/baz setup not called yet"

	# Call /quux before the call to /foo/bar/baz completes
	Finch.call "/quux"

	calledOnce cb.setup_foo_bar,            	"/quux (before /foo/bar callback): foo/bar setup not called again"
	neverCalled cb.setup_foo_bar_baz,	"/quux (before /foo/bar callback): foo/bar/baz setup not called"
	neverCalled cb.setup_quux,       	"/quux (before /foo/bar callback): quux setup not called yet"

	cb.setup_foo_bar.callArg 1

	calledOnce cb.setup_foo_bar,               	"/quux (after /foo/bar callback): foo/bar setup not called again"
	calledOnce cb.teardown_foo_bar,            	"/quux (after /foo/bar callback): foo/bar teardown called"
	neverCalled cb.setup_foo_bar_baz,   	"/quux (after /foo/bar callback): foo/bar/baz setup not called"
	neverCalled cb.teardown_foo_bar_baz,	"/quux (after /foo/bar callback): foo/bar/baz teardown not called"
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

	test "Trivial observable test (binding form)", sinon.test ->

		fn = @stub()

		Finch.route "foo", (bindings) ->
			Finch.observe ["sort", "query"], (sort, query) ->
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

	Finch.call "/foo/bar?a=1&b=10&c=11"

	neverCalled foo,	"foo callback not called"
	neverCalled bar,	"bar callback not called"
	neverCalled id, 	"id callback not called"

	foo.reset()
	bar.reset()
	id.reset()

	Finch.call "/foo?a=21&b=22&c=23"

	calledOnce foo,                   	"foo callback called once"
	lastCalledWithExactly foo, ["21"],	"foo callback args"
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

	neverCalled slash,	"/ callback not called"
	neverCalled foo,  	"foo callback not called"
	neverCalled bar,  	"bar callback not called"
	neverCalled id,   	"id callback not called"