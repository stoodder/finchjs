class Finch.OperationQueue
	queue: []

	before_start: null
	after_finish: null

	constructor: (options) ->
		options ?= {}

		@before_start = options.before_start ? (->)
		@after_finish = options.after_finish ? (->)

		@before_start = (->) unless isFunction(@before_start)
		@after_finish = (->) unless isFunction(@after_finish)
	#END constructor

	appendOperation: (action, node, step_callback) ->
		operation = new Finch.Operation(action, node, step_callback)
		@queue.push(operation)
		return operation
	#END appendOperation

	execute: ->
		@before_start()
		do recurse = =>
			operation = @queue.shift()
			if operation instanceof Finch.Operation
				operation.execute(recurse)
			else
				@after_finish(false)
			#END if
		#END recurse
		
		return @
	#END execute

	abort: ->
		@queue = []
		@after_finish(true)
		@before_start = (->)
		@after_finish = (->)
		return @
	#END abort
#END OperationQueue