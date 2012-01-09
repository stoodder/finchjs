var http = require("http")
var fs = require("fs")
var path = require("path")
var url = require("url")

http.createServer(function(request, result){
	
	var requestedFile = path.join(__dirname, url.parse(request.url).path);

	path.exists(requestedFile, function(exists){
		if(exists)
		{
			result.writeHeader(200);
			console.log("200: " + requestedFile);
			result.end(fs.readFileSync(requestedFile));
		} else {
			result.writeHeader(404);
			console.log("404: " + requestedFile);
			result.end()
		}	
	});
	
}).listen(1337, '127.0.0.1');