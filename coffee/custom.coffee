#------------------------------------
#	Utility Methods
#------------------------------------
isString = (object) -> Object::toString.call(object) is "[object String]"
isFunction = (object) -> Object::toString.call(object) is "[object Function]"
trim = (str) -> str.replace(/^\s+/, '').replace(/\s+$/, '')
defer = (callback) ->
	callback = (->) unless isFunction(callback)
	setTimeout(callback, 1)

# Just some helper methods
sectionize = (input) -> trim(input ? "").toLowerCase().replace(/[^a-z0-9]+/g,"")

#Setup some jquery stuff
$.ajaxSetup( cache: false )

#------------------------------------
# Viewmodels
#------------------------------------
class LayoutViewModel
	@instance = null

	constructor: () ->
		LayoutViewModel.instance = this

		@ContentViewModel = ko.observable({})
		@ContentTemplate = ko.observable()

class DocsViewModel
	@instance = null

	constructor: () ->
		DocsViewModel.instance = this

		@ArticleViewModel = ko.observable({})
		@ArticleTemplate = ko.observable()

#------------------------------------
# Finch Routes
#------------------------------------
Finch.route "/", ({}, callback) -> 
	
	mixpanel.track("Viewing Home", {}, (->))
	
	$("#content").animate {'opacity':0}, complete: ->
		$.get "./pages/home.tmpl", (data) ->
			Layout = LayoutViewModel.instance
			Layout.ContentViewModel(new DocsViewModel)
			Layout.ContentTemplate(data)

			$("#content").animate({'opacity':1},{complete:callback})
		# END get
	#END fade

Finch.route "download", ({}, callback) ->
	
	mixpanel.track("Viewing Download", {}, (->))

	$("#content").animate {'opacity':0}, complete: ->
		$.get "./pages/download.tmpl", (data) ->
			Layout = LayoutViewModel.instance
			Layout.ContentViewModel({})
			Layout.ContentTemplate(data)

			$("#content").animate({'opacity':1},{complete:callback})
		# END get
	#END fade

Finch.route "docs", 
	setup: ({}, callback) ->
	
		mixpanel.track("Viewing Documentation", {}, (->))

		$("#content").animate {'opacity':0}, complete: ->
			$.get "./pages/docs.tmpl", (data) ->
				console.log(data)
				Layout = LayoutViewModel.instance
				Layout.ContentTemplate(data)
				Layout.ContentViewModel(new DocsViewModel)

				$("#content").animate({'opacity':1},{complete:callback})
			# END get
		#END fade
	
	load: () -> Finch.call("docs/introduction")


Finch.route "[docs]/:article", 
	setup: ({article}, callback) ->
	
		$.get "./pages/docs/#{article}.md", (data) ->
			Docs = DocsViewModel.instance
			Docs.ArticleViewModel({})
			Docs.ArticleTemplate(marked(data))

			$("#content").animate({'opacity':1},{complete:callback})
	
	load: ({article}) ->
		article = sectionize(article)

		for elm in $("h1")
			elm = $(elm) 
			if sectionize(elm.text()) is article
				return $.scrollTo(elm, {duration: 1000, offset: -$("#header").height()-30})


Finch.route "[docs/:article]/:section", 
	load: ({section}) ->
		section = sectionize(section)

		for elm in $("h2")
			elm = $(elm) 
			if sectionize(elm.text()) is section
				return $.scrollTo(elm, {duration: 1000, offset: -$("#header").height()-30})


Finch.route "[docs/:article/:section]/:subsection", 
	load: ({subsection}) ->
		subsection = sectionize(subsection)

		for elm in $("h3")
			elm = $(elm) 
			if sectionize(elm.text()) is subsection
				return $.scrollTo(elm, {duration: 1000, offset: -$("#header").height()-30})

#------------------------------------
# Initialize the page
#------------------------------------
$ ->
	ko.applyBindings( new LayoutViewModel )

	Finch.listen()