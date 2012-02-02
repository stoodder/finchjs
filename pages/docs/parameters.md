# Parameters
Parameters are simple defined as in-route variables that can be extracted and passed into our route methods.  In Finch these are handles two ways: via inline parameters (or bingings) and through query parameters.

## Working with inline parameters (bindings)
Inline paramaters, or bindings as they're called in finch, are parameters found in the uri itself (rather than in the query string).

Here's some examples of routes with parameters:

	/home/news/1 -> '1' could be a parameter for a news article id
	/home/news/33/comments -> again, we could get '33'
	/user/stoodder -> here we might want to extract 'stoodder'

From the examples above, we could setup Finch to listen for routes like these as follows:

	Finch.route "/home/news/:newsId", (bindings) ->
		console.log("Looking for news article #{bindings.newsId}")

	Finch.route "/home/news/:newsId/comments", (bindings) ->
		console.log("Looking for news article #{bindings.newsId}'s comments")

	Finch.route "/user/:username", (bindings) ->
		console.log("Looking up user #{bindings.username}")

Calling the example route with the route setup shown above, we'd expect to see the following in the console:

	-- Finch.call "/home/news/1"
	> Looking for news article 1

	-- Finch.call "/home/news/33/comments"
	> Looking for news article 33's comments

	-- Finch.call "/user/stoodder"
	> Looking up user stoodder

## Working with Query Parameters
Query parameters in Finch are handled quite a bit differently than one might expect.  Typically, one might think that the query parameters would simply be appended on to the list of bindings passed into the route method.  However, Finch implements a dependency listener that will listen for changes to specific query parameters and will respond with a callback accordingly.  In order to handle these dependencies, Finch introduces another method **Finch.observe()**. Before we explain why we do this, let us demonstrate how Finch.observe() works.

### Explicit Dependencies
There are a few ways of utilizing query parameter dependencies, three to be exact. The first is to explicitly state the parameters. To begin, imagine we currently had the following setup:

	Finch.route "/home/news", ->
		console.log("Called home!")

However, we're now looking to add sorting to the mix, and so we've decided that we need to depend on the 'sort' parameter which will be found in the query string.  In order to make this modification we'll need to use the first form of Finch.observe()

	Finch.observe "arg1", ..., "argN", (arg1, ..., argN) ->
		... do stuff ...

Here Finch.observe assumes that each of the arguments specifies a dependency to a query string parameter.  Finch also assumes that the last argument will be a callback that takes in (using the CommonJS way) corresponding arguments containing the value of each dependency.

So, to implement this in out 'sorting' example above, we would have to make the following modification to the setup method:

	Finch.route "/home/news", ->
		console.log("Called home!")

		Finch.observe "sort", (sort) ->
			console.log("We're sorting  by #{sort}")

Hence calling the following:

	Finch.call "/home/news"
	Finch.call "/home/news?sort=alpha"
	Finch.call "/home/news?sort=numeric"

We could get the following console output:

	> Called home!
	> We're sorting by undefined
	> We're sorting by alpha
	> We're sorting by numeric

Perrty simple.

**NOTE:** If you wish, instead of listing out each of the dependencies, we can also pass in array of dependencies as the first argument to this method and achieve the same effect.  The pattern is as follows:

	Finch.observe ["arg1", ..., "argN"], (arg1, ..., argN) ->
		... do stuff ...

### Implicit Dependencies
The more powerful (and prefered?) way to handle query parameters is through implcit dependency tracking! Okay, so... that was a mouth full, let's explain.  Instead of explicitly defining each of the parameters we would like to track (as we did above) Finch allows us to use Finch.observe() with only a callback.  Inside of the callback, we can access the values of any parameter we would like (even those from the inline prameters).  Here is the form:

	Finch.observe (params) ->
		arg1 = params('arg1') #access arg1
		...
		argN = params('argN') #access argN

Here Finch.observe only take a callback method which accepts only one argument 'params'.  Params is actually an accessor method where that allows us to enter a key of a query parameter adn will return its current value of undefined if none is present. Finch will recognize which parameters we looked at and will only run our callback if any of the dependencies are updated in the future.  Lastly, each time we run teh callback, the dependency list is regenerated to ensure that we observe any possible code path.

To see this in action, consider our previous example.  Instead of explicitlty stating our 'sort' parameter we coudl use implicity dependencies as such:

	Finch.route "/home/news", ->
		console.log("Called home!")

		Finch.observe (params) ->
			console.log("We're sorting by #{params('sort')}")

Again running: 

	Finch.call "/home/news"
	Finch.call "/home/news?sort=alpha"
	Finch.call "/home/news?sort=numeric"

Would yield:

	> Called home!
	> We're sorting by undefined
	> We're sorting by alpha
	> We're sorting by numeric

It's the same!

Just to add a little bit more to this example, lets suppose that we went one step further with this setup method:

	Finch.route "/home/news", ->
		console.log("Called home!")

		Finch.observe (params) ->
			sort = params('sort')
			if sort is 'alpha'
				console.log("You're sorting alphanumerically! and hello is #{params('hello')}")
			else
				console.log("You must be sorting numerically! and foo is #{params('foo')}")

Then lets pretend we called:

	Finch.call "/home/news?sort=alpha&hello=world&foo=bar"
	Finch.call "/home/news?sort=alpha&hello=world&foo=DontShowMe!"
	Finch.call "/home/news?sort=numeric&hello=world&foo=bar"
	Finch.call "/home/news?sort=numeric&hello=DontShowMe!&foo=bar"

Would give us:

	> Called home!
	> You're sorting alphanumerically! and hello is world
	-- ignores second Finch.call
	> You must be sorting numerically! and foo is bar
	-- ignores fourth Finch.call

Notice in this example how we ignored two of the Finch.call methods that would have been executed if we were explicitly depending on sort, hello, and foo.  Instead, using implicit dependencies, we only re-ran the method once their respecitve dependicies were updated.
