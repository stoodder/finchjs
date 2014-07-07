class Finch.Operation
	@SETUP = "setup"
	@LOAD = "load"
	@UNLOAD = "unload"
	@TEARDOWN = "teardown"
	VALID_ACTIONS = [@SETUP, @LOAD, @UNLOAD, @TEARDOWN]

	action: null
	node: null
	before_step: null
	after_step: null
	setup_params: null

	constructor: (action, node, callbacks) ->
		unless action in VALID_ACTIONS
			throw new Finch.Error("Invalid action '#{action}' given")
		#END unless

		unless node instanceof Finch.Node
			throw new Finch.Error("node must be an instanceof Finch.Node")
		#END unless

		@action = action
		@node = node

		{before_step, after_step, setup_params} = (callbacks ? {})
		@before_step = if isFunction(before_step) then before_step else (->)
		@after_step = if isFunction(after_step) then after_step else (->)
		@setup_params = if isFunction(setup_params) then setup_params else (->{})
	#END constructor

	execute: (callback, previous_operation) ->
		continuation = =>
			@after_step(@action, @node)
			callback(@action, @node) if isFunction(callback)
		#END continuation

		@before_step(@action, @node)
		
		params = @setup_params(@action, @node)
		params = {} unless isObject(params)

		previous_node = previous_operation?.node ? null
		previous_action = previous_operation?.action ? null
		method = @node.getCallback(@action, previous_action, previous_node)
		
		if method.length is 2
			method(params, continuation)
		else
			method(params)
			continuation()
		#END if

		return @
	#END execute
#END Operation