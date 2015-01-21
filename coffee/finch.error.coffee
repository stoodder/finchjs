class Finch.Error
	name: "Finch.Error"
	event_name: "error"
	message: null
	constructor: (@message) ->
	toString: -> "#{@name}: #{@message}"
#END FInch.Error