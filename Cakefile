fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

outputFile = "scripts/finch.min.js"

task 'min', "Minifying FInsh.js", (options) ->
	exec(
		'uglifyjs scripts/finch.js', 
		(err, stdout, stderr) -> 
			fs.writeFileSync(outputFile,stdout)
	)