# Introduction
Finch is a simple, yet powerful, javascript route handling library.  It focuses on easing the assignment of routes utilizing their natural hierarchical structure to add simplicity to your web apps.  It prides itself in its ability to handle route assignment/listening, working with parent routes, handling inline route parameters, and observing changes to query parameters.

## Basic Usage
To start, you'll need to include the Finch.js file on page load. Simple

	<html>
		<head>
			<title>Using Finch is Fun!</title>
			<script src="./scripts/Finch.js" type="text/javascript" language="javascript"></script>
		</head>
		<body>
			... Stuff ...
		</body>
	</html>

Once you've included Finch, start setting up your routes like so (we're using [CoffeeScript](http://coffeescript.org/) here, for those wondering):

	Finch.route "/home", ->
		console.log "Called home!"

	Finch.route "/home/news", ->
		console.log "Called home/news!"

Lastly, once you're done setting up your route patterns, start calling them!

	Finch.call "home"
	Finch.call "home/news"

Which would output to the console:

	> Called home!
	> Called home/news!

Simple, right?

## Responding to URL Changes

Okay, so obviously you won't want to be using Finch.call() all of the time, most likely you'll just want Finch to respond to changes in the url.  For this reason, Finch comes packed with three methods to interact with the hash (everything following the '#') of the url.  They are:

* Finch.listen()
* Finch.ignore()
* Finch.navigate()

### Finch.listen()
As its name implies, Finch.listen() will listen to changes in the hash of a url.  By default, Finch runs off the hash (we haven't implemented push state... yet) with the following pattern: "#/my/uri/?with=some&nifty=parameters".  This is a pretty common pattern as one would expect.

Finch.listen() takes no parameters and will attempt to utilize the browsers onhashchange event if present, if not, Finch.listen() will fallback to using a setInterval to handle its listening.

When we call Finch.listen() it will automatically run the current hash as the first Finch.call. Once we update the hash from here on out, as long as we're listening, Finch will execute Finch.call on the current hash. Of course, if the hash hasn't changed between requests, Finch will ignore the request.  

### Finch.ignore()
The sister to Finch.listen() is Finch.ignore() which will stop listening to changes in the url.  If we were using an interval to listen, it will be cleared.

Finch.ignore takes no parameters.

### Finch.navigate()
The last utility method to deal with the browser's url is Finch.navigate() which can be used to manipulate the url contents and change locations.  At its basic usage, Finch.navigate() is pretty straight forward.  

**Form 1:**

Finch.navigate() can take three parameters, the first for a uri, and an optional second parameter to deal with changing the query string, and the last is a flag to tell finch if we should update or overwite the current uri.  Finch.navigate looks like this:

	Finch.navigate "home"
	Finch.navigate "home", {hello: 'world'}
	Finch.navigate "home/news", {foo: 'bar'}
	Finch.navigate "home/news?hello=world", {foo: 'bar'}
	Finch.navigate "home/news?hello=world", {free: 'bird'}, true


Calling these would respectively change the hash to:

	#home
	#home?hello=world
	#home/news?foo=bar
	#home/news?hello=world&foo=bar
	#home/news?hello=world&foo=bar&free=bird

**Form 2:**

However, we can also use Finch.navigate in two other ways, the first is by sending in just a uri and the doUpdate flag.  Doing this will keep the current query params and only update the hash

For instance, so we were on "#home/news?hello=world" and called Finch.navigate() this way:

	Finch.navigate "/account", true

The above would yield the following hash:

	#account?hello=world

**Form 3:**

The last form of Finch.navigate() takes in an object and the doUpdate flag.  Using this form will ensure that the uri stays the same but the query params ar only updated/written depending on the value of the doUpdate flag.  Pretend we're on "#home/news" and called Finch.navigate like so:

	Finch.navigate {hello:'world2'}
	Finch.navigate {foo:'bar'}, true
	Finch.navigate {foo: 'baz'}, true
	Finch.navigate {hello:'world'}

Accordingly, we would see the following hashes:

	#home/news?hello=world2
	#home/news?hello=world2&foo=bar
	#home/news?hello=world&foo=baz
	#home/news?hello=world