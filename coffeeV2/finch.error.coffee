class Finch.Error extends Error
	name: "Finch.Error"
	message: null
	stack: -> super(arguments...)
	toString: -> "#{@name}: @{message}"
#END FInch.Error