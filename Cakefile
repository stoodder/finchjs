
# Building Falcon requires coffee-script, uglify-js, wrench, and sass. For
# help installing, try:
#
# `npm install coffee-script uglify-js wrench -g`
# `gem install sass`
#
# Original Cake file from Chosen.js - modified for our use
#   https://github.com/harvesthq/chosen/blob/master/Cakefile
fs              	= require 'fs'
{spawn, exec}   	= require 'child_process'
CoffeeScript    	= require 'coffee-script'
UglifyJS 			= require("uglify-js")
wrench          	= require 'wrench'

# Get the version number
version_file = 'VERSION'
version = if fs.existsSync( version_file ) then "#{fs.readFileSync(version_file)}".replace( /[^0-9a-zA-Z.]*/gm, '' ) else ""
version_tag = -> "v#{version}"
build_file = "build.json"

extendArray = (_array, _ext) -> 
	ret = []
	ret.push( val ) for val in _array
	ret.push( val ) for val in _ext
	return ret
#END exendArray

# Method used to write a javascript file
write_file = (filename, body) ->
	body = body.replace(
		/\{\{VERSION\}\}/gi, version
	).replace(
		/\{\{VERSION_TAG\}\}/gi, version_tag
	)
	fs.writeFileSync filename, body
	console.log "Wrote #{filename}"

print_error = (error, file_name, file_contents) ->
	line = error.message.match /line ([0-9]+):/
	if line && line[1] && line = parseInt(line[1])
		contents_lines = ( file_contents ? "").split "\n"
		first = if line-4 < 0 then 0 else line-4
		last  = if line+3 > contents_lines.size then contents_lines.size else line+3
		console.log "Error compiling #{file_name}. \"#{error.message}\"\n"
		index = 0
		for line in contents_lines[first...last]
			index++
			line_number = first + 1 + index
			console.log "#{(' ' for [0..(3-(line_number.toString().length))]).join('')} #{line}"
	else
		console.log "Error compiling #{file_name}: #{error.message}"

#Task to watch files (so they're built when saved)
task 'watch', 'watch coffee/ and tests/ for changes and build', ->
	console.log "Watching for changes"

	watchers = []

	watch = ->
		console.log("STARTING WATCH ROUTINE")

		try
			build = JSON.parse( "#{fs.readFileSync(build_file)}" ) ? {}
			build["COFFEE"] ?= {}
			build["SASS"] ?= {}
			build["COMBINED"] ?= {}
			build["COPIED"] ?= {}
			build["HAML"] ?= {}

			console.log "STARTING COMPILED COFFEE FILES"
			for d, ss of build["COFFEE"]
				do ->
					destination = d
					sources = ss
					sources = [sources] if (Object::toString.call(sources) is "[object String]")

					execute = ->
						code = minified_code = ""
						file_name = file_contents = ""
						
						try
							file_name = destination.replace("{{VERSION}}", version)
							file_contents = ""
							file_contents += "#{fs.readFileSync(source)}\r\n" for source in sources when fs.existsSync(source)

							code = CoffeeScript.compile(file_contents)
							minified_code = UglifyJS.minify(code, {fromString: true}).code
							# minified_code = parser.parse( code )
							# minified_code = uglify.ast_mangle( minified_code )
							# minified_code = uglify.ast_squeeze( minified_code )
							# minified_code = uglify.gen_code( minified_code )

							write_file(file_name, code)
							write_file(file_name.replace(/\.js$/,'.min.js'), minified_code)

							cb() if typeof cb is 'function'
						catch e
							print_error e, file_name, file_contents
						#END try
					#END execute

					for s in sources
						do ->
							source = s
							if fs.existsSync( source )
								console.log "Watching for changes in #{source}"

								watchers.push fs.watch( source, (curr, prev) ->
									console.log "#{new Date}: Saw change in #{source}"
									execute()
								)
							else
								console.error("\r\nERROR: Could not find file #{source} to compile\r\n")
							#END if
						#END do
					#END for

					execute()
				#END do
			#END for

			console.log "STARTING COMPILED SASS FILES"
			count = 0
			temp_prefix = "__temp_" + (new Date).valueOf()

			for d, ss of build["SASS"]
				do ->
					destination = d
					sources = ss

					execute = ->
						try
							file_name = destination.replace("{{VERSION}}", version)
							min_destination = destination.replace(/\.css$/,'.min.css')
							temp_destination = temp_prefix + "_#{count}__.sass"

							file_contents = ""
							file_contents += "#{fs.readFileSync(source)}\r\n" for source in sources when fs.existsSync(source)

							write_file(temp_destination, file_contents)

							exec "sass --update #{temp_destination}:#{destination} --style expanded", (messages) ->
								console.log("Wrote #{destination}")
								console.error( messages ) if messages?.code is 1
								exec "sass --update #{temp_destination}:#{min_destination} --style compressed", ->
									console.log("Wrote #{min_destination}")
									fs.unlink(temp_destination)
									console.log("Cleaning: #{temp_destination}")

									#lastly try to delete in .sass-cache directory
									try
										wrench.rmdirSyncRecursive('.sass-cache')
									catch error
									#END try/catch
								#END min exec
							#END exec

							count++
						catch error
							print_error error, file_name, file_contents
						#END try/catch
					#END return

					for s in sources
						do ->
							if fs.existsSync( s )
									source = s
									console.log "Watching for changes in #{source}"
									watchers.push fs.watch( source, (curr, prev) ->
										console.log "#{new Date}: Saw change in #{source}"
										execute()
									)
								#END do
							else
								console.error("\r\nERROR: Could not find file #{source} to compile\r\n")
							#END if
						#END do
					#END for

					execute()
				#END do
			#END for

			console.log "STARTING COMPILED HAML FILES"
			_require = "-r #{__dirname}/private/haml/helpers.rb"

			for d, s of build["HAML"]
				do ->
					destination = d
					source = s

					execute = ->
						try
							file_name = destination.replace("{{VERSION}}", version)

							exec "haml --double-quote-attributes --no-escape-attrs #{_require} --trace #{source} #{file_name}", (messages) ->
								console.log("Wrote #{file_name}")
								print_error( messages ) if messages?
						catch e
							print_error e
						#END try
					#END execute

					if fs.existsSync( source )
						console.log "Watching for changes in #{source}"
						watchers.push fs.watch( source, (curr, prev) ->
							console.log "#{new Date}: Saw change in #{source}"
							execute()
						)
					else
						console.error("\r\nERROR: Could not find file #{source} to copy\r\n")
					#END if

					execute()
				#END do
			#END for

			console.log "STARTING COMBINED FILES"
			for d, ss of build["COMBINED"]
				do ->
					destination = d
					sources = ss

					execute = ->
						try
							code = ( fs.readFileSync(source) for source in sources when fs.existsSync(source) ).join("\r\n")
							file_name = destination.replace("{{VERSION}}", version)
							write_file( file_name, code )
						catch e
							print_error e, file_name, destination
						#END try
					#END execute

					for s in sources
						do ->
							source = s
							if fs.existsSync( source )
								console.log "Watching for changes in #{source}"
								watchers.push fs.watch( source, (curr, prev) ->
									console.log "#{new Date}: Saw change in #{source}"
									execute()
								)
							else
								console.error("\r\nERROR: Could not find file #{source} to combine\r\n")
							#END if
						#END do
					#END for

					execute()
				#END do
			#END for

			console.log "STARTING COPIED FILES"
			for d, s of build["COPIED"]
				do ->
					destination = d
					source = s

					execute = ->
						try
							file_name = destination.replace("{{VERSION}}", version)
							write_file(file_name, "#{fs.readFileSync(source)}")
						catch e
							print_error e
						#END try
					#END execute

					if fs.existsSync( source )
						console.log "Watching for changes in #{source}"
						watchers.push fs.watch( source, (curr, prev) ->
							console.log "#{new Date}: Saw change in #{source}"
							execute()
						)
					else
						console.error("\r\nERROR: Could not find file #{source} to copy\r\n")
					#END if

					execute()
				#END do
			#END for
		catch e
			console.log("COULD NOT COMPILE. ERROR IN BUILD FILE.")
			print_error e
		#END catch
	#END watch

	fs.watch build_file, ->
		console.log("ENDING WATCH ROUTINE")

		watcher.close() for watcher in watchers
		watchers = []

		console.log("REBOOTING")
		watch()
	#END fs.watch

	if fs.existsSync( version_file )
		fs.watch version_file, ->
			console.log("ENDING WATCH ROUTINE")

			watcher.close() for watcher in watchers
			watchers = []

			console.log("REBOOTING")
			version = "#{fs.readFileSync(version_file)}".replace( /[^0-9a-zA-Z.]*/gm, '' )
			console.log "\r\n\r\n\r\n"
			console.log(version)
			console.log "\r\n\r\n\r\n"
			watch()
		#END fs.watch
	#END if

	watch()
#END watch task






# --------------------------------------------------------
# 
# --------------------------------------------------------
run = (cmd, args, cb, err_cb) ->
	exec "#{cmd} #{args.join(' ')}", (err, stdout, stderr) ->
		if err isnt null
			console.error stderr

			if typeof err_cb is 'function'
				err_cb()
			else
				throw "Failed command execution (#{err})."
		else
			cb(stdout) if typeof cb is 'function'

# --------------------------------------------------------
# 
# --------------------------------------------------------
with_clean_repo = (cb) ->
	run 'git', ['diff', '--exit-code'], cb, ->
		throw 'There are files that need to be committed first.'

# --------------------------------------------------------
#
# --------------------------------------------------------
without_existing_tag = (cb) ->
	run 'git', ['tag'], (stdout) ->
		if stdout.split("\n").indexOf( version_tag() ) >= 0
			throw 'This tag has already been committed to the repo.'
		else
			cb()

# --------------------------------------------------------
#
# --------------------------------------------------------
push_repo = (args=[], cb, cb_err) ->
	run 'git', ['push'].concat(args), cb, cb_err

# --------------------------------------------------------
#
# --------------------------------------------------------
git_commit = (message) ->
	run "git", ["commit", '-a', '-m', message]

# --------------------------------------------------------
#
# --------------------------------------------------------
git_tag = (cb, cb_err) ->
	run 'git', ['tag', '-a', '-m', "\"Version #{version}\"", version_tag()], cb, cb_err

# --------------------------------------------------------
#
# --------------------------------------------------------
git_untag = (e) ->
	console.log "Failure to tag caught: #{e}"
	console.log "Removing tag #{version_tag()}"
	run 'git', ['tag', '-d', version_tag()]


# --------------------------------------------------------
#
# --------------------------------------------------------
task 'major', 'Executing a major version update', () ->

	console.log "Trying to run a major version update"

	with_clean_repo ->
		v = version.match(/^([0-9]+)\.([0-9]+)\.([0-9]+)$/)
		v[1]++
		v[2] = v[3] = 0
		version = "#{v[1]}.#{v[2]}.#{v[3]}"

		fs.writeFileSync(version_file, version)

		git_commit("\"Updating to Major version #{version}\"")

		git_tag(->)

		console.log "Finished updating major version to #{version}"


# --------------------------------------------------------
#
# --------------------------------------------------------
task 'minor', 'Executing a minor version update', () ->

	console.log "Trying to run a minor versino update"

	with_clean_repo ->
		v = version.match(/^([0-9]+)\.([0-9]+)\.([0-9]+)$/)
		v[2]++
		v[3] = 0
		version = "#{v[1]}.#{v[2]}.#{v[3]}"

		fs.writeFileSync(version_file, version)

		git_commit("\"Updating to Minor version #{version}\"")

		git_tag(->)

		console.log "Finished updating minor version to #{version}"


# --------------------------------------------------------
#
# --------------------------------------------------------
task 'patch', 'Executing a patch version update', () ->

	console.log "Trying to run a patch version update"

	with_clean_repo ->
		v = version.match(/^([0-9]+)\.([0-9]+)\.([0-9]+)$/)
		v[3]++
		version = "#{v[1]}.#{v[2]}.#{v[3]}"

		fs.writeFileSync(version_file, version)

		git_commit("\"Updating to Patch version #{version}\"")

		git_tag(->)

		console.log "Finished updating patch version to #{version}"