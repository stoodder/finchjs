callbackGroup = () ->
	group = {}
	group.reset = () ->
		for key, value of group
			value.reset() if Object::toString.call(value.reset) is "[object Function]"
	return group

module "Finch",
	teardown: ->
		Finch.reset()

test "Simple routing", sinon.test ->

	foo_bar = @stub()
	baz_quux = @stub()

	Finch.route "foo/bar", foo_bar
	Finch.route "baz/quux", baz_quux

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

	ok foo.calledOnce, "foo called"
	ok foo_bar.calledOnce, "foo/bar called"
	ok foo.calledBefore(foo_bar), "foo called before foo/bar"
	foo.reset()
	foo_bar.reset()

	Finch.call "/foo/bar/123"

	ok !foo.called, "foo not called again"
	ok !foo_bar.called, "foo/bar not called again"
	ok foo_bar_id.calledOnce, "foo/bar/id called"
	deepEqual foo_bar_id.getCall(0).args[0], { id: "123" }, "foo/bar/id params"
	foo_bar_id.reset()

	Finch.call "/foo/bar/123?x=Hello&y=World"

	ok !foo.called, "foo not called again"
	ok !foo_bar.called, "foo/bar not called again"
	ok foo_bar_id.calledOnce, "foo/bar/id called"
	deepEqual foo_bar_id.getCall(0).args[0], {
		x: "Hello"
		y: "World"
		id: "123"
	}, "foo/bar/id params"
	foo_bar_id.reset()

	Finch.call "/foo/baz/456"

	ok !foo.called, "foo not called again"
	ok foo_baz.called, "foo/baz called"
	ok foo_baz_id.called, "foo/baz/id called"
	ok foo_baz.calledBefore(foo_baz_id), "foo/baz called before foo/baz/id"
	deepEqual foo_baz_id.getCall(0).args[0], { id: "456" }, "foo/baz/id params"
	foo_baz.reset()
	foo_baz_id.reset()

	Finch.call "/quux/789?band=Sunn O)))&genre=Post-Progressive Fridgecore"

	ok quux.called, "quux called"
	ok quux_id.called, "quux/id called"
	ok quux.calledBefore(quux_id), "quux called before quux/id"
	deepEqual quux_id.getCall(0).args[0], {
		band: "Sunn O)))"
		genre: "Post-Progressive Fridgecore"
		id: "789"
	}, "quux/id params"

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

test "Empty string params", sinon.test ->

	Finch.route "quux",      	quux = @stub()
	Finch.route "[quux]/:id",	quux_id = @stub()

	# Test routes

	Finch.call "/quux/123?x=&y="

	ok quux.called, "quux called"
	ok quux_id.called, "quux/id called"
	ok quux.calledBefore(quux_id), "quux called before quux/id"
	deepEqual quux_id.getCall(0).args[0], {
		x: ""
		y: ""
		id: "123"
	}, "quux params"

test "Collision between inlined and query string params", sinon.test ->

	Finch.route "foo/:bar/:baz", foo_bar_baz = @stub()

	# Test routes

	Finch.call "foo/abc/def?bar=123&baz=456&quux=789"

	ok foo_bar_baz.called, "foo/bar/baz called"
	deepEqual foo_bar_baz.getCall(0).args[0], {
		bar: "abc"
		baz: "def"
		quux: "789"
	}, "foo/bar/baz params"

test "Routing with setup/teardown", sinon.test ->

	cb = callbackGroup()

	Finch.route "foo",
		setup:   	cb.setup_foo = @stub()
		load:    	cb.load_foo = @stub()
		teardown:	cb.teardown_foo = @stub()
	Finch.route "[foo]/bar",
		setup:   	cb.setup_foo_bar = @stub()
		load:    	cb.load_foo_bar = @stub()
		teardown:	cb.teardown_foo_bar = @stub()
	Finch.route "[foo/bar]/:id",
		setup:   	cb.setup_foo_bar_id = @stub()
		load:    	cb.load_foo_bar_id = @stub()
		teardown:	cb.teardown_foo_bar_id = @stub()
	Finch.route "[foo]/baz",
		setup:   	cb.setup_foo_baz = @stub()
		teardown:	cb.teardown_foo_baz = @stub()
	Finch.route "[foo/baz]/:id",
		setup:   	cb.setup_foo_baz_id = @stub()
		teardown:	cb.teardown_foo_baz_id = @stub()

	# Test routes

	Finch.call "/foo"

	ok cb.setup_foo.called, "/foo: foo setup"
	ok cb.load_foo.called, "/foo: foo load"
	cb.reset()

	Finch.call "/foo/bar"

	ok !cb.setup_foo.called, "/foo/bar: no foo setup"
	ok !cb.load_foo.called, "/foo/bar: no foo load"
	ok !cb.teardown_foo.called, "/foo/bar: no foo teardown"
	ok cb.setup_foo_bar.called, "/foo/bar: foo/bar setup"
	ok cb.load_foo_bar.called, "/foo/bar: foo/bar load"
	cb.reset()

	Finch.call "/foo"

	ok cb.teardown_foo_bar.called, "/foo: foo/bar teardown"
	ok !cb.setup_foo.called, "/foo: no foo setup"
	ok cb.load_foo.called, "/foo: foo load"
	cb.reset()

	Finch.call "/foo/bar/123?x=abc"
	ok !cb.teardown_foo.called, "/foo/bar/123: no foo teardown"
	ok !cb.setup_foo.called, "/foo/bar/123: no foo setup"
	ok cb.setup_foo_bar.called, "/foo/bar/123: foo/bar setup"
	ok cb.setup_foo_bar_id.called, "/foo/bar/123: foo/bar/id setup"
	ok !cb.load_foo.called, "/foo/bar/123: no foo load"
	ok !cb.load_foo_bar.called, "/foo/bar/123: no foo/bar load"
	ok cb.load_foo_bar_id.called, "/foo/bar/123: foo/bar/id load"
	cb.reset()

	Finch.call "/foo/bar/456?x=abc"

	ok cb.teardown_foo_bar_id.called, "/foo/bar/456?x=abc: foo/bar/id teardown"
	ok cb.setup_foo_bar_id.called, "/foo/bar/456?x=abc: foo/bar/id setup"
	ok cb.load_foo_bar_id.called, "/foo/bar/456?x=abc: foo/bar/id load"
	cb.reset()

	Finch.call "/foo/bar/456?x=def"

	ok !cb.setup_foo_bar_id.called, "/foo/bar/456?x=def: no foo/bar/id setup"
	ok cb.load_foo_bar_id.called, "/foo/bar/456?x=def: foo/bar/id load"
	cb.reset()

	Finch.call "/foo/baz/789"

	ok cb.teardown_foo_bar_id.called, "/foo/baz/789: foo/baz/id teardown"
	ok cb.teardown_foo_bar.called, "/foo/baz/789: foo/bar teardown"
	ok !cb.teardown_foo.called, "/foo/baz/789: no foo teardown"
	ok !cb.setup_foo.called, "/foo/baz/789: no foo setup"
	ok cb.setup_foo_baz.calledOnce, "/foo/baz/789: foo/baz setup"
	ok cb.setup_foo_baz_id.calledOnce, "/foo/baz/789: foo/baz/id setup"
	ok !cb.load_foo.called, "/foo/baz/789: no foo load"
	cb.reset()

	Finch.call "/foo/baz/abc?term=Hello"

	ok cb.teardown_foo_baz_id.called, "/foo/baz/abc?term=Hello: foo/baz/id teardown"
	ok cb.setup_foo_baz_id.called, "/foo/baz/abc?term=Hello: foo/baz/id setup"
	cb.reset()

	Finch.call "/foo/baz/abc?term=World"

	ok !cb.teardown_foo_baz_id.called, "/foo/baz/abc?term=World: no foo/baz/id teardown"
	ok !cb.setup_foo_baz_id.called, "/foo/baz/abc?term=World: no foo/baz/id setup"