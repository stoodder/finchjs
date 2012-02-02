# Advanced Topics
## Asynchronous routes
Sometimes (most of the time?) you'll want to load a parent route before any of the child routes are executed.  Most likely, you'll want to continue down the route call chain after an ajax request has returned a successful result.  To do this, you'll need to specify an **Asynchronous Callback**.  To do so is simple.  Just add a second parameter in your callback method for the child callback, like so:

	Finch.route "/home", (bindings, childCallback) ->
		console.log("Calling the home route")
		setTimeout(childCallback, 1000)

	Finch.route "[/home]/news", (bindings) ->
		console.log("Called /home/news")

Doing this will tell Finch that the /home route is asynchronous and will need to wait for the child callback to be executed.  Calling the /home/news route would yield:

	-- Finch.call "/home/news"
	> Calling the home route
	... waits for 1 second
	> Called /home/news

It should also be noted that callback method take in an optional parameters argument.  This allows us to append/change/remove values from the parameters list and pass it along to the child methods (by default, the parameters are passed down as-is).

For example:

	Finch.route "/home", (bindings, childCallback) ->
		console.log("Calling the home route")
		setTimeout( () ->
			bindings.hello = 'world'
			childCallback(bindings)
		, 1000)

	Finch.route "[/home]/news", (bindings) ->
		console.log("Called /home/news, hello = \"#{bindings.hello}\")

Again, calling the /home/news route would yield:

	-- Finch.call "/home/news"
	> Calling the home route
	... waits for 1 second
	> Called /home/news, hello = "world"

**NOTE** Because of Finch's caching abilities, if a call is interrupted (perhaps a user is clicking madly through your website... because they love it so much, of course), the current call will be aborted and once finished, will call the newly updated route.  This is useful for keeping things in sync and prevents firing off a ton of concurrent ajax requests (which could even lead to weird race conditions!)

## Setup, Load, and Teardown
The last topic to cover is advanced route creation with setup, load, and teardown functions.  Until now, we've seen the short hand version (Finch.route "route", callback), but there is also a more complex long hand notation.  The second parameter may, instead of being a function, be an object containing the keys setup, load, teardown.  Like so:

	Finch.route "/home", {
		setup: (bindings, childCallback) ->
		load: (bindings, childCallback) ->
		teardown: (bindings, childCallback) ->
	}

Typically, these pieces are called as follows:

* **setup** - is called when a route is called in the call stack.  Usually used for any setup code, such as loading initial page data or setting up a model.

* **load** - is only called at the top most level of a call stack after all of the setup methods are called.  This would typically be used for displaying some default page data (you know... the ones telling users to 'select something to do').

* **teardown** - is called when we leave the current route for a new route.  This is the opposite of setup so it will be called as the stack begins to step towards it's new path. This might be used for removing any intervals (ajax polling), necessary page data, or to tack a user's actions.

__Note:__ The second argument of these functions (childCallback) is optional. As with simple routes, this determines whether the function is asynchronous. If so, Finch will not execute its next step until you return control back to Finch by calling the childCallback().

So to dig in a bit more, pretend we had the following setup:

	Finch.route "/home", {
		setup: (bindings, childCallback) ->
			console.log("Setup home")
			childCallback()

		load: (bindings) ->
			console.log("Loaded home")

		teardown: () ->
			console.log("Teardown home")
	}

	Finch.route "[/home]/news", {
		setup: (bindings) ->
			console.log("Setup home/news")

		load: (bindings) ->
			console.log("Loaded home/news")

		teardown: () ->
			console.log("Teardown home/news")
	}

	Finch.route "[/home/news]/:id", {
		setup: (bindings) ->
			console.log("Setup home/news/:id, id = \"#{bindings.id}\"")

		load: (bindings) ->
			console.log("Loaded home/news/:id, id = \"#{bindings.id}\"")

		teardown: () ->
			console.log("Teardown home/news/:id")
	}

Then, with the above setup, if we called:

	Finch.call "/home/news/33"
	Finch.call "/home"
	Finch.call "/home/news/66"
	Finch.call "/home/news/99"

We would get the following:

	-- Finch.call "/home/news/33"
	> Setup home
	> Setup home/news
	> Setup home/news/:id, id = 33
	> Loaded home/news/:id, id = 33

	-- Finch.call "/home"
	> Teardown home/news/:id
	> Teardown home/news
	> Loaded home

	-- Finch.call "/home/news/66"
	> Setup home/news
	> Setup home/news/:id, id = 66
	> Loaded home/news/:id, id = 66

	-- Finch.call "/home/news/99"
	> Teardown home/news/:id
	> Setup home/news/:id, id = 99
	> Loaded home/news/:id, id = 99