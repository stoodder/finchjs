# Overview

## Finch.route()
Used to define a route and it's corresponding callback(s)

### Finch.route( route, callback )
The short hand, basic, form of Finch.route() utilized for simply responding to routes that match the given pattern here.

#### Arguments
* **route** _(string)_ - The route's pattern.

* **callback** _(function)_ - A callback to call when this route is matched.  A callback can take two parameters.  The first being the <a href="#docs/parameters/working with inline parameters (bindings">binding values</a> from the routes.  The second being an optional <a href="#docs/advancedTopics/Asynchronous routes">child callback</a> parameter used to handle asynchronous routes.

#### Example

__Basic Example__

	Finch.route "Hello/Route", () ->
		console.log("Well hello there! How you doin'?!")

__With Bindings__
	
	Finch.route "Hello/Route/:someId", (bindings) ->
		console.log("Hey! Here's Some Id: #{bindings.someId}")

__With an Asynchronous Callback__
	
	Finch.route "Hello/Route/:someId", (bindings, childCallback) ->
		console.log("Hey! Here's Some Id: #{bindings.someId}")
		childCallback()

#### See Also
<a href="#docs/introduction/basic usage" alt="Basic Usage" title="Basic Usage">Basic Usage</a>&nbsp; - &nbsp;
<a href="#docs/parameters/working with inline parameters (bindings)" alt="Working with Inline Parameters" title="Working with Inline Parameters">Working with Inline Parameters (Bindings)</a>&nbsp; - &nbsp;
<a href="#docs/parentRoutes" alt="Parent Routes" title="Parent Routes">Parent Routes</a>&nbsp; - &nbsp;
<a href="#docs/advancedTopics/Asynchronous routes" alt="Asynchronous Routes" title="Asynchronous Routes">Asynchronous Routes</a>

### &nbsp;
### Finch.route( route, {setup, load, teardown} )
Expanded form of Finch.route() which allows us to specify what to do when calling a parent route in the stack, what happens when a specific route is loaded, and what happens when we leave a route.

#### Arguments
* **route** _(string)_ - The route's pattern, same as above.  
Examples: "/hello/world", "/home/news/:id", "[/home]/news/:id/comments", etc.

* **{setup}** _(function)_ - A callback method to execute when this route is being called as part of the stack towards the highest level stack. The arguments are the same as the callback in the basic form of Finch.route().  

* **{load}** _(function)_ - A callback method to execute when this route is the current route.  In otherwords, this method duplicates a 'page load' event. The arguments are the same as the callback in the basic form of Finch.route().  

* **{unload}** _(function)_ - A callback method to execute when this route was the current route and is leaving to load a new route.

* **{teardown}** _(function)_ - A callback method to execute when the stack steps upwards towards its new node in the routing tree.  Think of this as the opposite of setup. The arguments are the same as the callback in the basic form of Finch.route().  

__Note:__ &nbsp; setup, load, and teardown all carry the same context for 'this'.  Therefore in a setup you could make an interval ( _this.interval = setInterval(...)_ ) and in the teardown you could clear it ( _clearTimeout(this.interval)_ )

#### Example
__Synchronous Form:__

	Finch.route "some/route", {
		setup: (bindings) ->
			console.log("Some Route has been setup! :)")

		load: (bindings) ->
			console.log("Some Route has been loaed! :D")

		teardown: (bindings) ->
			console.log("Some Route has been torndown! :(")
	}

__Asynchronous Form:__

	Finch.route "some/route", {
		setup: (bindings, childCallback) ->
			console.log("Some Route has been setup! :)")
			childCallback()

		load: (bindings, childCallback) ->
			console.log("Some Route has been loaed! :D")
			childCallback()

		teardown: (bindings, childCallback) ->
			console.log("Some Route has been torndown! :(")
			childCallback()
	}

#### See Also
<a href="#docs/advancedTopics/Setup, Load, and Teardown" alt="Setup, Load, and Teardown" title="Setup, Load, and Teardown">Setup, Load, and Teardown</a>

## &nbsp;
## Finch.call()
Used to call a specific route. There is currently only one form of Finch.call which taks in a single argument for the route to call.

### Finch.call( uri )

#### Arguments
* **uri** _(string)_ - The uri to have finch try to call.  
Examples: "/hello/world", "/home/news/33", "/home/news/33/comments", etc.

#### Returns
_(boolean)_ - Was the call for this route successful?

#### Example

	Finch.call "Some/Route"

## &nbsp;
## Finch.observe()
Used for explicitly or implicitly observing (listening to changes) in the query parameters or toue bindings.

### Finch.observe( 'arg1', ..., 'argN', callback )
The basic form of Finch.observe() that takes in N number of string arguments stating which parameters we should observe.  It passes these arguments into the callback method as it's arguments in the same order.

#### Arguments
* **arg1..N** _(string)_ - The name of the parameters to observe

* **callback** _(function)_ - The callback method to execute when any of the parameters in the argument list changes.  The arguments to the callback are the values of the parameter list in the same order as specified.

#### Example

	Finch.route "Some/Route", () ->
		Finch.observe "hello", "foo", (hello, foo) ->
			console.log "#{hello} and #{foo}"

#### See Also
<a href="#docs/parameters/working with query parameters/Explicit Dependencies" alt="Explicit Dependencies" title="Explicit Dependencies">Explicit Dependencies</a>

### &nbsp;
### Finch.observe( ["arg1", ..., "argN"], callback )
This is a mirror of the method above except that it accepts an array as the first argument rather than a list of arguments.

#### Arguments
* **[arg1..N]** _(array)_ - An array listing out the parameters to listen to

* **callback** _(function)_ - The callback method to execute when any of the parameters in the argument list changes.  The arguments to the callback are the values of the parameter list in the same order as specified.

#### Example

	Finch.route "Some/Route", () ->
		Finch.observe ["hello", "foo"], (hello, foo) ->
			console.log "#{hello} and #{foo}"

#### See Also
<a href="#docs/parameters/working with query parameters/Explicit Dependencies" alt="Explicit Dependencies" title="Explicit Dependencies">Explicit Dependencies</a>

### &nbsp;
### Finch.observe( callback )
If Finch.observe() is only given a callback method, it will assume that it's dependencies will be defined implicitly.  That is, you will be accessing the params as you need and Finch will only respond to changes in those parameters until of course the observing method is run again and new dependencies are defined.  Accessing parameters like this allows your code to be optimized to your needs and will always cover future code paths as you need.

#### Arguments
* **callback** _(function)_ - The callback method should have on parameter 'params', which can also be used as a method to access the different parameters from either the query string or the route bindings.

__Note:__ Finch.observe must exist inside of either a setup or load method (or a route method if using the basic form)

#### Example

	Finch.route "Some/Route", (bindings) ->
		Finch.observe (params) ->
			hello = params('hello')
			foo = params('foo')
			console.log "#{hello} and #{foo}"

#### See Also
<a href="#docs/parameters/working with query parameters/Implicit Dependencies" alt="Implicit Dependencies" title="Implicit Dependencies">Implicit Dependencies</a>


## &nbsp;
## Finch.navigate()
Finch.navigate() allows one to udpate the URL hash in a few different ways.

### &nbsp;
### Finch.navigate( uri, queryParams, doUpdate )
Calling Finch.navigate with a uri and optional queryParams will set the current browsers hash accordingly

#### Arguments
* **uri** _(string)_ - The uri to direct to

* **queryParams** _(object)_ - Optional query parameters to append on to the uri

* **doUpdate** _(boolean)_ - Optional flag to tell finch to just update the query params instead of overitting them.

#### Example

__Without Query Parameters__

	# Goes to #Some/Route
	Finch.navigate "Some/Route"

__With Query Parameters__

	# Goes to #Some/Route?hello=world&foo=bar
	Finch.navigate "Some/Route", {hello:'world', foo:'bar'}

__With Query Parameters and doUpdate__

	# From #Some/Route?hello=world
	# Goes to #Some/Route?hello=world&foo=bar
	Finch.navigate "Some/Route", {foo:'bar'}, true

#### See Also
<a href="#docs/introduction/responding to url changes" alt="Responding to URL Changes" title="Responding to URL Changes">Responding to URL Changes</a>

### &nbsp;
### Finch.navigate( uri, doUpdate )
Allows us to simply update the uri while keeping the same query parameters

#### Arguments
* **uri** _(string)_ - The uri to direct to

* **doUpdate** _(boolean)_ - Optional flag to tell finch to just update the query params instead of overitting them.

#### Example

	# From #This/Route?hello=world2&wow=wee
	# Goes to #Some/Route?hello=world2&wow=wee
	Finch.navigate SomeRoute, true

#### See Also
<a href="#docs/introduction/responding to url changes" alt="Responding to URL Changes" title="Responding to URL Changes">Responding to URL Changes</a>

### &nbsp;
### Finch.navigate( queryParams, doUpdate )
The last version of Finch.navigate takes two parameters.  One for the query paremters and the second to tell us if we're updating or overwritting the query parameters.  If called in this form, we will only modify the query parameters

#### Arguments
* **queryParams** _(object)_ - The query params to set in the uri

* **doUpdate** _(boolean)_ - Optional flag to tell finch to just update the query params instead of overitting them.

#### Example

	# Goes to Some/Route?hello=world2&wow=wee
	Finch.navigate {hello:'world2', wow:'wee'}

	# Goes to Some/Route?wow=wee!!!&foo=bar
	Finch.navigate {foo:'bar', wow:'wee!!!'}

	# Goes to Some/Route?wow=wee!!!&foo=bar&hello=world2
	Finch.navigate {hello:'world2'}, true

#### See Also
<a href="#docs/introduction/responding to url changes" alt="Responding to URL Changes" title="Responding to URL Changes">Responding to URL Changes</a>

## &nbsp;
## Finch.listen()
Finch.listen() listens for changes in the browser's hash value and responds by calling Finch.call() on the resultant hash.  When evoked Finch.listen() invokes and inital check on the hash, will only respond if the hash has changed, and will revert the hash back to a valid value if an invalid no route is matched.  Finch.listen() attempts to utilize the 'onhashchange' event and falls back to setInterval hash checking.

#### Returns
_(boolean)_ - Was Finch.listen() successful in setting up hash listening

#### See Also
<a href="#docs/introduction/responding to url changes" alt="Responding to URL Changes" title="Responding to URL Changes">Responding to URL Changes</a>

## &nbsp;
## Finch.ignore()
Finch.ignore() is the opposite of Finch.listen() and will stop listening to changes in the hash.

#### Returns
_(boolean)_ - Was Finch.ignore() successful in removing hash listening

#### See Also
<a href="#docs/introduction/responding to url changes" alt="Responding to URL Changes" title="Responding to URL Changes">Responding to URL Changes</a>

## &nbsp;
## Finch.abort()
Sometimes, especially when heavily utilizing asynchronous routes, we'll need to return contorl back to Finch even though we may be in the middle of currently processing a step in the route hierarchy.  This is usually the case when an unexpected error occurs in our program and fails to call the childCallback for any reason.  Finch.abort() brings control back to Finch for this very reason. 

#### See Also
<a href="#docs/advancedTopics/Asynchronous routes/How do I abort a call?" alt="How do I abort a call?" title="How do I abort a call?">How do I abort a call?</a>

## &nbsp;
## Finch.options()
Finch.options() is a method that assigns options to Finch in order to handle certain scenarios differently.

#### Arguments
* **options** _(object)_ - The options to update
 * **CoerceParameterTypes** _(boolean)_ - Should Finch attempt to coecre bindings and parameters to their appropriate types? Default: false

#### See Also
<a href="#docs/introduction/responding to url changes" alt="Responding to URL Changes" title="Responding to URL Changes">Responding to URL Changes</a>&nbsp; - &nbsp;
<a href="#docs/parameters/working with inline parameters (bindings)" alt="Working with Inline Parameters" title="Working with Inline Parameters">Working with Inline Parameters (Bindings)</a>

