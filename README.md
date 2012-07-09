# Finch.js

## Powerfully Simple Javascript Routing
Finch.js is a whole new take on handling routes in javascript web apps. It utilizes the natural hierarchy of routes, simplified pattern matching, and powerful parameter dependencies in order to speed up and organize web apps that rely highly on interecting with the browser's url.

## Installation
First, [Download](http://stoodder.github.com/finchjs#download) Finch.js

Once you've gotten the files, simply include the javascript in your html &lt;head/&gt;> tags.

	<!doctype html>
	<html>
		<head>
			<script src="./scripts/finch.min.js" type="text/javascript" language="javascript"></script>
		</head>
		<body>
			... Stuff here ...
		</body>
	</html>

Since Finch is a standalone library, this is all you'll need.  From here, take a look at our [website](http://stoodder.github.com/finchjs) for more info on how to implement Finch.

## Documentation
Take a look at our [website](http://stoodder.github.com/finchjs) for the most up-to-date documention.

## Licenese
Finch is available for sue under the [MIT License](https://github.com/stoodder/finchjs/blob/master/LICENSE.md)

## TODO List
* __Splats__ - Sometimes we might want an undetermined number of parameters at the end of a url, splats are useful for grabbing any number of url bindings and must be the last binding in the route pattern.  Example: "/home/news/:variables..."
* __pushState__ - Add pushstate support ot finsh so that we don't always need to rely on the hash