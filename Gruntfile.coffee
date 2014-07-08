###
#=================================================
#
#  Setup
#
#=================================================

Install Ruby
Install Node.js (http://nodejs.org/)
npm install -g grunt-cli
npm install coffee-script
npm install

###
module.exports = (grunt) ->
	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-jasmine')

	grunt.registerTask 'test', ['coffee:test', 'jasmine:dist']
	
	grunt.initConfig
		'pkg': grunt.file.readJSON('package.json')

		'coffee':
			'test':
				files:
					"tests/tests.js": [
						"tests/*.test.coffee"
					]
				#END files
			#END coffee:test
		#END coffee

		'jasmine':
			'dist':
				src: 'finch.js'
				options:
					vendor: [
						'tests/sinon.js'
						'tests/jasmine-sinon.js'
					]
					specs: ['tests/tests.js']
				#END options
			#END jasmine:dist
		#END jasmine
	#END initConfig
#END exports
