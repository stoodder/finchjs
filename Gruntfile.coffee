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
npm install grunt --save-dev
npm install grunt-contrib-coffee --save-dev
npm install grunt-contrib-jasmine --save-dev

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
					"tests/jasmine2.0.0-sinon.js": "tests/jasmine2.0.0-sinon.coffee"
					"tests/tests.js": "tests/tests.coffee"
					"testsV2/tests.js": "testsV2/*.coffee"
				#END files
			#END coffee:test
		#END coffee

		'jasmine':
			'dist':
				src: 'finch.js'
				options:
					vendor: [
						'tests/sinon-1.7.3.js'
						'tests/jasmine2.0.0-sinon.js'
					]
					specs: ['tests/tests.js']
				#END options
			#END jasmine:dist
		#END jasmine
	#END initConfig
#END exports
