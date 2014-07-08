class Finch.OperationQueue
	queue: null

	before_start: null
	after_finish: null
	is_executing: false

	constructor: (options) ->
		options ?= {}

		@before_start = options.before_start ? (->)
		@after_finish = options.after_finish ? (->)

		@before_start = (->) unless isFunction(@before_start)
		@after_finish = (->) unless isFunction(@after_finish)

		@queue = []
	#END constructor

	appendOperation: (action, node, step_callback) ->
		operation = new Finch.Operation(action, node, step_callback)
		@queue.push(operation)
		return operation
	#END appendOperation

	execute: ->
		return @ if @is_executing
		@is_executing = true
		@before_start()
		operation = null
		do recurse = =>
			previous_operation = operation
			operation = @queue.shift()
			if operation instanceof Finch.Operation
				operation.execute(recurse, previous_operation)
			else
				@after_finish(false)
				@is_executing = false
			#END if
		#END recurse
		
		return @
	#END execute

	abort: ->
		@queue = []
		@after_finish(true)
		@before_start = (->)
		@after_finish = (->)
		@is_executing = false
		return @
	#END abort
#END OperationQueue