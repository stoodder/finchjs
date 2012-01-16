## Finch.js
Finch.js is a simple, yet powerful, route handling library.  It focusses on easing the assignment of routes, working with parent routes, and handling inline route parameters.

### Sounds nifty, where do I start?
To start, you'll need to incldue the Finch.js file on page load

```html
<html>
	<head>
		<title>Using Finch is Fun!</title>
		<script src="./scripts/finch.js" type="text/javascript" language="javascript"></script>
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

	Finch.call("/home")
	Finch.call("/home/news")

Will output this to the console:

	> Called home!
	> Called home/news!

Simple, right?

### Okay, what about inline parameters?
An inline parameter is a parameter that is found within the route (rather than in the query string)

here's some examples of routes with parameters
	
	/home/news/1 -> '1' could be a parameter for a news article id
	/home/news/33/comments -> again, we could get '33'
	/user/stoodder -> here we might want to extract 'stoodder'

For the examples above, we could setup funch to listen for routes like these as follows:

	Finch.route "/home/news/:newsId", (params) ->
		console.log("Looking for news article #{params.newsId}")
	
	Finch.route "/home/news/:newsId/comments", (params) ->
		console.log("Looking for news article #{params.newsId}'s comments")
	
	Finch.route "/user/:username", (params) ->
		console.log("Looking up user #{params.username}")

Calling the example route with the route setup shown above, we'd expect to the the following in the console:
	
	Finch.call("/home/news/1")
	> Looking for news article 1

	Finch.call("/home/news/33/comments")
	> Looking for news article 33's comments

	Finch.call("/user/stoodder")
	> Looking up user stoodder

### What about query string parameters, how do those work?
Query string parameters appear at the and of a uri with the following pattern:

	?key1=val1&key2=val2

Finch handles these similarly to inline parameters.  For exmaple, pretend we had the following route set up:

	Finch.route "/home", (params) ->
		console.log("hello = \"#{params.hello}\"")

... And we called ...

	Finch.call "/home?hello=world"

... We would get the following output

	> hello = "world"

**NOTE** Inline query parameters will always overwrite querystring query parameters

	Finch.route "/home/news/:newsId", (params) ->
		console.log("Called news id #{params.newsId}")
	
	Finch.call "/home/news/33?newsId=666"
	> Called news id 33

## Parent Routes
### What's a parent route?
A parent route is a route that is called before a child route is called.  

Okay, so what does that mean? Let me explain by example:

Imagine that we have a page (/home) with tabs on it for inbox, news, etc.  We could imagine that each of the tabs has a corresponding route (/home/inbox, /home/news, /home/etc).  Whenever we call one of the tabs (child) routes we'd want to run any setup code for the /home route (such as loading in initial user data).  typically, without parent routes, we'd need to do the same setup code in each of the child route calls.  However, with finch we can easily specify a parent route to call

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

**NOTE** Routes calling parent routes MUST start with the '[', we cannot call routes with parent routes embdedded in the middle of a route:

	Won't work:
	Finch.route("/home/[news]")

### Parent routes are multi level
Pretend now that we wanted to go down another level to get a specific news article

Extending on to our previous examples, we could make a new route:

	Finch.route "[/home/news]/:newsId", (params) ->
		console.log("Looking at news article #{params.newsId}")

Calling the route could give us:

	-- Finch.call "/home/news/33"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33

### Parent routes are cached
Often, we'll be switching routes and we won't need to re-setup our parent's data/structure. Finch knows this, and will remember what we've called and will ensure that we don't re-call the setup of our routes.  Hence running the following (with our previous parent route examples):

	Finch.call "/home/news/33"
	Finch.call "/home/news/99"

Would give us
	
	-- Finch.call "/home/news/33"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33

	-- Finch.call "/home/news/66"
	> Looking at news article 66

Notice, we didn't run re-execute the /home or /home/news rotues (because we didn't need to)

It is also perfectly acceptabkle to call only to upper routes, doing something like this:

	Finch.call "/home/news/33"
	Finch.call "/home/news"

Would yield the following:
	
	-- Finch.call "/home/news/33"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33

	-- Finch.call "/home/news"
	> Running /home/news

	

