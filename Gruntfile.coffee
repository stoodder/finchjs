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
npm install grunt-contrib-uglify --save-dev
npm install grunt-contrib-watch --save-dev

###
module.exports = (grunt) ->
	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-uglify')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.registerTask('default', [
		'coffee:banner'
		'update_banner'
		'coffee:dist'
		'uglify:dist'
		'coffee:test'
		'watch'
	])

	grunt.registerTask 'update_banner', 'updates the banner information', ->
		try
			banner = grunt.file.read('scripts/banner.js').toString()
		catch e
			banner = ""
		#END try

		uglfiy_cfg = grunt.config('uglify')
		uglfiy_cfg.dist.options.banner = banner

		grunt.config('uglify', uglfiy_cfg)
	#END registerTask
	
	grunt.initConfig
		'pkg': grunt.file.readJSON('package.json')

		'coffee':
			'banner':
				options:
					bare: true
				#END options

				files:
					'scripts/banner.js': ["coffee/banner.coffee"]
				#END files
			#END banner

			'dist':
				options:
					join: true
				#END options

				files:
					'<%= pkg.name %>.js': [
						"coffee/banner.coffee"
						"coffee/<%= pkg.name %>.coffee"
					]
				#END files
			#END coffee:dist

			'test':
				files:
					"tests/tests.js": "tests/tests.coffee"
				#END files
			#END coffee:test
		#END coffee

		'uglify':
			'dist':
				options:
					'banner': '' #Updated lated in the update_banner task
				#END options
				files:
					'<%= pkg.name %>.min.js': '<%= pkg.name %>.js'
				#END files
			#END uglifY:dist
		#END uglify

		'watch':
			'banner_coffee':
				'files': ["coffee/banner.coffee"]
				'tasks': ['coffee:banner', 'update_banner', 'coffee:dist', 'uglify:dist']
			#END watch:banner_coffee

			'dist_coffee':
				'files': ["coffee/<%= pkg.name %>.coffee"]
				'tasks': ['coffee:dist', 'uglify:dist']
			#END watch:dist_coffee

			'test_coffee':
				'files': ['tests/tests.coffee']
				'tasks': ['coffee:test']
			#END watch:test_coffee
		#END watch
	#END initConfig
#END exports
