# Finch.js
Finch.js is a simple, yet powerful, route handling library.  It focuses on easing the assignment of routes, working with parent routes, and handling inline route parameters.

### Table of Contents
<ol><li><a href="#basicUsage">Basic Usage</a></li><ol><li><a href="#whereDoIStart">Sounds nifty, where do I start?</a></li></ol><li><a href="#parameters">Parameters</a></li><ol><li><a href="#inlineParameters">Okay, what about inline parameters?</a></li><li><a href="#queryStringParamaters">What about query string parameters, how do those work?</a></li></ol><li><a href="#parentRoutes">Parent Routes</a></li><ol><li><a href="#whatAreParentRoutes">What's a parent route?</a></li><li><a href="#parentRoutesMultiLevel">Parent routes are multi level</a></li><li><a href="#parentRoutesCached">Parent routes are cached</a></li><li><a href="#paramsInParentRoutes">And what about using parameters in parent routes?</a></li></ol><li><a href="#advancedTopcis">Advanced Topics</a></li><ol><li><a href="#asyncRoutes">Asynchronous routes</a></li><li><a href="#setupLoadTeardown">Setup, Load, and Teardown</a></li></ol></ol>

<a name="basicUsage"></a>
## Basic Usage
<a name="whereDoIStart"></a>
### Sounds nifty, where do I start?
To start, you'll need to include the Finch.js file on page load.

```html
<html>
	<head>
		<title>Using Finch is Fun!</title>
		<script src="./scripts/Finch.js" type="text/javascript" language="javascript"></script>
	</head>
	<body>
		... Stuff ...
	</body>
</html>
```

Once you've included Finch, start setting up the routes that you'd like:

	Finch.route "/home", (params) ->
		console.log("Called home!")

	Finch.route "/home/news", (params) ->
		console.log("Called home/news!")

Lastly, once you're done setting up the routes, start calling them:

	Finch.call "/home"
	Finch.call "/home/news"

Will output this to the console:

	> Called home!
	> Called home/news!

Simple, right?

<a name="parameters"></a>
## Parameters
<a name="inlineParameters"></a>
### Okay, what about inline parameters?
An inline parameter is a parameter that is found within the route (rather than in the query string)

Here's some examples of routes with parameters:

	/home/news/1 -> '1' could be a parameter for a news article id
	/home/news/33/comments -> again, we could get '33'
	/user/stoodder -> here we might want to extract 'stoodder'

For the examples above, we could setup Finch to listen for routes like these as follows:

	Finch.route "/home/news/:newsId", (params) ->
		console.log("Looking for news article #{params.newsId}")

	Finch.route "/home/news/:newsId/comments", (params) ->
		console.log("Looking for news article #{params.newsId}'s comments")

	Finch.route "/user/:username", (params) ->
		console.log("Looking up user #{params.username}")

Calling the example route with the route setup shown above, we'd expect to the the following in the console:

	-- Finch.call "/home/news/1"
	> Looking for news article 1

	-- Finch.call "/home/news/33/comments"
	> Looking for news article 33's comments

	-- Finch.call "/user/stoodder"
	> Looking up user stoodder

<a name="queryStringParamaters"></a>
### What about query string parameters, how do those work?
Query string parameters appear at the and of a uri with the following pattern:

	?key1=val1&key2=val2

Finch handles these similarly to inline parameters.  For example, pretend we had the following route set up:

	Finch.route "/home", (params) ->
		console.log("hello = \"#{params.hello}\"")

... And we called ...

	Finch.call "/home?hello=world"

... We would get the following output

	> hello = "world"

**NOTE** Inline query parameters will always overwrite query string query parameters.

	Finch.route "/home/news/:newsId", (params) ->
		console.log("Called news id #{params.newsId}")

	Finch.call "/home/news/33?newsId=666"
	> Called news id 33

<a name="parentRoutes"></a>
## Parent Routes
<a name="whatAreParentRoutes"></a>
### What's a parent route?
A parent route is a route that is called before a child route is called.

Okay, so what does that mean? Let me explain by example:

Imagine that we have a page (/home) with tabs on it for inbox, news, etc.  We could imagine that each of the tabs has a corresponding route (/home/inbox, /home/news, /home/etc).  Whenever we call one of the tabs' (child) routes we'd want to run any setup code for the /home route (such as loading in initial user data).  Typically, without parent routes, we'd need to do the same setup code in each of the child route calls.  However, with Finch we can easily specify a parent route to call:

	Finch.route "/home", (params) ->
		console.log("Setup the home route")

	Finch.route "[/home]/news", (params) ->
		console.log("Running /home/news")

	Finch.route "[/home]/inbox", (params) ->
		console.log("Running /home/inbox")

	Finch.route "[/home]/etc", (params) ->
		console.log("Running /home/etc")

Here, the piece of the route wrapped in [] is the parent route.  Running the following on this setup code:

	Finch.call "/home/news"

Would give us:

	-- Finch.call "/home/news"
	> Setup the home route
	> Running /home/news

**NOTE** Routes calling parent routes MUST start with the '['.  We cannot call routes with parent routes embedded in the middle of a route:

	Won't work:
	Finch.route "/home/[news]", () -> console.log("ARG!!!!")

<a name="parentRoutesMultiLevel"></a>
### Parent routes are multi level!
Pretend now that we wanted to go down another level to get a specific news article.

Extending on to our previous examples, we could make a new route:

	Finch.route "[/home/news]/:newsId", (params) ->
		console.log("Looking at news article #{params.newsId}")

Calling the route would give us:

	-- Finch.call "/home/news/33"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33

<a name="parentRoutesCached"></a>
### Parent routes are cached
Often, we'll be switching routes and we won't need to re-setup our parent's data/structure (in out example we could switch tabs or change news articles). Finch knows this, and will remember what we've called and will ensure that we don't re-call the setup of our routes.  Hence running the following (with our previous parent route examples):

	Finch.call "/home/news/33"
	Finch.call "/home/news/99"

Would give us

	-- Finch.call "/home/news/33"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33

	-- Finch.call "/home/news/99"
	> Looking at news article 99

Notice, we didn't re-execute the /home or /home/news routes (because we didn't need to).

It is also perfectly acceptable to call only to parent routes, doing something like this:

	Finch.call "/home/news/33"
	Finch.call "/home/news"

Would yield the following:

	-- Finch.call "/home/news/33"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33

	-- Finch.call "/home/news"
	> Running /home/news

<a name="paramsInParentRoutes"></a>
### And what about using parameters in parent routes?
Again, simple.  We can repeat the pattern above, and extend a new parent route for a news article to get its comments:

	Finch.route "[/home/news/:newsId]/comments", (params) ->
		console.log("Showing comments for #{params.newsId}")

Calling this would give us (again, still using our examples)

	-- Finch.call "/home/news/33/comments"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33
	> Showing comments for 33

Notice in our setup all we had to do was wrap the parent route in brackets.

<a name="advancedTopcis"></a>
## Advanced Topics
<a name="asyncRoutes"></a>
### Asynchronous routes
Sometimes (most of the time?) you'll want to load a parent route before any of the child routes are executed.  Most likely, you'll want to continue down the route call chain after an ajax request has returned a successful result.  To do this, you'll need to specify an **Asynchronous Callback**.  To do so is simple.  Just add a second parameter in your callback method for the child callback, like so:

	Finch.route "/home", (params, childCallback) ->
		console.log("Calling the home route")
		setTimeout(childCallback, 1000)

	Finch.route "[/home]/news", (params) ->
		console.log("Called /home/news")

Doing this will tell Finch that the /home route is asynchronous and will need to wait for the child callback to be executed.  Calling the /home/news route would yield:

	-- Finch.call "/home/news"
	> Calling the home route
	... waits for 1 second
	> Called /home/news

It should also be noted that callback method take in an optional parameters argument.  This allows us to append/change/remove values from the parameters list and pass it along to the child methods (by default, the parameters are passed down as-is).

For example:

	Finch.route "/home", (params, childCallback) ->
		console.log("Calling the home route")
		setTimeout( () ->
			params.hello = 'world'
			childCallback(params)
		, 1000)

	Finch.route "[/home]/news", (params) ->
		console.log("Called /home/news, hello = \"#{params.hello}\")

Again, calling the /home/news route would yield:

	-- Finch.call "/home/news"
	> Calling the home route
	... waits for 1 second
	> Called /home/news, hello = "world"

**NOTE** Because of Finch's caching abilities, if a call is interrupted (perhaps a user is clicking madly through your website... because they love it so much, of course), the current call will be aborted and once finished, will call the newly updated route.  This is useful for keeping things in sync and prevents firing off a ton of concurrent ajax requests (which could even lead to weird race conditions!)

<a name="setupLoadTeardown"></a>
### Setup, Load, and Teardown
The last topic to cover is advanced route creation with setup, load, and teardown functions.  Until now, we've seen the short hand version (Finch.route "route", callback), but there is also a more complex long hand notation.  The second parameter may, instead of being a function, be an object containing the keys setup, load, teardown.  Like so:

	Finch.route "/home", {
		setup: (params, childCallback) ->
		load: (params) ->
		teardown: () ->
	}

Typically, these pieces are called as follows:

- **setup** - is called when a route is called in the call stack.  Usually used for any setup code, such as loading initial page data or setting up a model.
- **load** - is only called at the top most level of a call stack after all of the setup methods are called.  This might typically be used for listening to query string changes.
- **teardown** - is called when we leave the current route for a new route.  This might be used for removing any intervals or necessary page data.

**NOTE** The second argument of the setup function (childCallback) is optional. As with simple routes, this determines whether the setup function is asynchronous.

So to dig in a bit more, pretend we had the following setup:

	Finch.route "/home", {
		setup: (params, childCallback) ->
			console.log("Setup home")
			childCallback()

		load: (params) ->
			console.log("Loaded home")

		teardown: () ->
			console.log("Teardown home")
	}

	Finch.route "[/home]/news", {
		setup: (params) ->
			console.log("Setup home/news")

		load: (params) ->
			console.log("Loaded home/news")

		teardown: () ->
			console.log("Teardown home/news")
	}

	Finch.route "[/home/news]/:newsId", {
		setup: (params) ->
			console.log("Setup home/news/:id, id = \"#{params.id}\"")

		load: (params) ->
			console.log("Loaded home/news/:id, id = \"#{params.id}\"")

		teardown: () ->
			console.log("Teardown home/news/:id")
	}

Then, with the above setup, if we called:

	Finch.call "/home/news/33"
	Finch.call "/home"
	Finch.call "/home/news/66"
	Finch.call "/home/news/99"
	Finch.call "/home/news/99?hello=world"

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

	-- Finch.call "/home/news/99?hello=world"
	> Loaded home/news/:id, id = 99