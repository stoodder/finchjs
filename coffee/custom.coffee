#------------------------------------
#	Utility Methods
#------------------------------------
isString = (object) -> Object::toString.call(object) is "[object String]"
isFunction = (object) -> Object::toString.call(object) is "[object Function]"

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
Finch.route "/", -> Finch.call("home")

Finch.route "/:page", ({page}, callback) ->
	page = "home" unless isString(page)
	page = page.toLowerCase()

	$.get "./pages/#{page}.tmpl", (html) ->
		Layout = LayoutViewModel.instance
		Layout.ContentViewModel({})
		Layout.ContentTemplate(html)

		callback()

Finch.route "/docs", (bindings, callback) ->

	$.get "./pages/docs.tmpl", (data) ->
		Layout = LayoutViewModel.instance
		Layout.ContentViewModel(new DocsViewModel)
		Layout.ContentTemplate(data)

		callback()

Finch.route "[/docs]/:article", ({article}, callback) ->
	
	$.get "./pages/docs/#{article}.md", (data) ->
		Docs = DocsViewModel.instance
		Docs.ArticleTemplate(markdown.toHTML(data))

		callback()


#------------------------------------
# Initialize the page
#------------------------------------
$ ->
	ko.applyBindings( new LayoutViewModel )

	Finch.listen()