class Finch.Observer
	@create: ->
		unless arguments.length > 0
			throw new Finch.Error("Invalid arguments given for creating an observer")
		#END unless

		if isFunction(arguments[0])
			return new Finch.Observer(arguments[0])
		else if isArray(arguments[0])
			[keys, _callback] = arguments
		else if isString(arguments[0])
			keys = Array::slice.call(arguments, 0, arguments.length-1)
			_callback = arguments[arguments.length-1]
		else
			throw new Finch.Error("Invalid arguments given for creating an observer")
		#END unless

		for key of keys when not isString(key)
			throw new Finch.Error("requested parameters must be string values")
		#END for

		unless isFunction(_callback)
			throw new Finch.Error("callback must be a function")
		#END unless

		callback = (accessor) ->
			values = []
			values.push(accessor(key)) for key in keys
			_callback.apply(this, values)
		#END callback

		return new Finch.Observer(callback)
	#END create

	callback: null
	dependencies: null
	is_disposed: false

	constructor: (callback) ->
		unless isFunction(callback)
			throw new Finch.Error("callback must be a Function")
		#END unless

		@callback = callback
	#END constructor

	willMutate: (params) ->
		return false unless isObject(params)
		return true unless isObject(@dependencies)
		return true for key, value of @dependencies when value isnt params[key]
		return false
	#END willMutate

	notify: (params) ->
		return @ if @is_disposed
		return @ unless isObject(params)
		return @ unless @willMutate(params)

		dependencies = {}
		@callback.call(this, (key) -> ( dependencies[key] = params[key] ))
		@dependencies = dependencies

		return @
	#END notify

	dispose: ->
		@is_disposed = true
		@dependencies = null
		@callback = null
		return @
	#END dispose
#END Finch.Observer