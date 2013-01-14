# Parent Routes

## Whats a parent route?
A parent route is a route that is called before a child route is called.

Okay, so what does that mean? Let me explain by example:

Imagine that we have a page (/home) with tabs on it for inbox, news, etc.  We could imagine that each of the tabs has a corresponding route (/home/inbox, /home/news, /home/etc).  Whenever we call one of the tabs' (child) routes we'd want to run any setup code for the /home route (such as loading in initial user data).  Typically, without parent routes, we'd need to do the same setup code in each of the child route calls.  However, with Finch we can easily specify a parent route to call:

	Finch.route "/home", (bindings) ->
		console.log("Setup the home route")

	Finch.route "[/home]/news", (bindings) ->
		console.log("Running /home/news")

	Finch.route "[/home]/inbox", (bindings) ->
		console.log("Running /home/inbox")

	Finch.route "[/home]/etc", (bindings) ->
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

## Parent routes are multi-leveled!
Pretend now that we wanted to go down another level to get a specific news article.

Extending on to our previous examples, we could make a new route:

	Finch.route "[/home/news]/:newsId", (bindings) ->
		console.log("Looking at news article #{params.newsId}")

Calling the route would give us:

	-- Finch.call "/home/news/33"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33

## Parent routes are cached
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

## What about using bindings in parent routes?
Again, simple.  We can repeat the pattern above, and extend a new parent route for a news article to get its comments:

	Finch.route "[/home/news/:newsId]/comments", (bindings) ->
		console.log("Showing comments for #{bindings.newsId}")

Calling this would give us (again, still using our examples)

	-- Finch.call "/home/news/33/comments"
	> Setup the home route
	> Running /home/news
	> Looking at news article 33
	> Showing comments for 33

Notice in our setup all we had to do was wrap the parent route in brackets.
