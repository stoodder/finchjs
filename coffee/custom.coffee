#------------------------------------
#	Utility Methods
#------------------------------------
isString = (object) -> Object::toString.call(object) is "[object String]"

#------------------------------------
# Viewmodels
#------------------------------------
class LayoutViewModel
	constructor: () ->
		@ContentViewModel = ko.observable()
		@ContentTemplate = ko.observable()
	
	@instance = new LayoutViewModel

#------------------------------------
# Finch Routes
#------------------------------------
Finch.route "/", -> Finch.call("/Home")

Finch.route "/:page", ({page}, callback) ->
	Layout = LayoutViewModel.instance
	page = "Home" unless isString(page)
	tmpl = page.toLowerCase()

	$.get "./pages/#{tmpl}.tmpl", (data) ->
		Layout.ContentTemplate( data )

		callback()

#------------------------------------
# Initialize the page
#------------------------------------
$ ->
	Layout = LayoutViewModel.instance
	Layout.ContentViewModel( {} )
	ko.applyBindings( Layout )

	Finch.listen()