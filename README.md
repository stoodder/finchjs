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
```js
Finch.route "/home", (params) ->
	console.log("Called home!")

Finch.route "/home/news", (params) ->
	console.log("Called home/news!")
```

Lastly, once you're done setting up the routes, start calling them:
```
Finch.call "/home"
Finch.call "/home/news"
```

Will output in the console:
```js
> Called home!
> Called home/news!
```


### What's a parent route?
A parent route is a route that is called before a child route is called.

For exmaple
Pretend we've assigned two routes in finch:
* /home
* [/home]/news

In this example, when we call the route "/home/news", /home will be executed first and then /home/news will be executed.

### Why use parent routes?
Parent routes are useful for setting up higher-level code.  

Imagine that we have a page (/home) with tabs on it for inbox, news, etc.  We could imagine that each of the tabs has a corresponding route (/home/inbox, /home/news, /home/etc).  Whenever we call one of the child route's we'd want to run any setup code for the /home route (such as loading in initial user data)