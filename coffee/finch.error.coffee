class Finch.Error
	name: "Finch.Error"
	message: null
	constructor: (@message) ->
	toString: -> "#{@name}: #{@message}"
#END FInch.Error