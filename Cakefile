fs = require 'fs'
path = require 'path'
http = require 'http'
url = require 'url'
{exec} = require 'child_process'

task 'run', "Running node server", (options) -> 
	http.createServer( (request, result) ->
		requestedFile = path.join(__dirname, url.parse(request.url).path)
		path.exists requestedFile, (exists) ->
			if exists
				result.writeHeader(200)
				console.log("200: #{requestedFile}")
				result.end(fs.readFileSync(requestedFile))
			else
				result.writeHeader(404)
				console.log("404: #{requestedFile}")
				result.end()
	).listen(1337, '127.0.0.1')
	console.log("Server running atr 127.0.0.1:1337")
	
task 'build', "Running node server", () -> 
	exec 'coffee -o scripts/ -wc coffee/ tests/', (->)

task 'min', "Minifying Finch.js", (options) ->
	inputFile = "scripts/finch.js"
	outputFile = "scripts/finch.min.js"

	exec(
		"uglifyjs #{inputFile}", 
		(err, stdout, stderr) -> 
			fs.writeFileSync(outputFile,stdout)
	)