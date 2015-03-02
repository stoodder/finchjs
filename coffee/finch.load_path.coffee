class Finch.LoadPath
	nodes: null
	route_components: null
	length: 0
	is_traversing: false
	current_operation_queue: null
	bindings: null
	observers: null
	params: null
	coerce_types: false

	constructor: (nodes, route_components, params) ->
		nodes ?= []
		route_components ?= []

		unless isArray(nodes)
			throw new Finch.Error("nodes must be an Array")
		#END unless

		unless isArray(route_components)
			throw new Finch.Error("route_components must be an Array")
		#END unless

		for node in nodes when not (node instanceof Finch.Node)
			throw new Finch.Error("nodes must be an instanceof Finch.Node")
		#END for

		unless nodes.length is route_components.length
			throw new Finch.Error("nodes and route_components must have the same lengths")
		#END unless

		@nodes = nodes
		@route_components = route_components
		@length = @nodes.length
		@bindings = {}
		@observers = []

		params = {} unless isObject(params)
		@params = {}
		@params[key] = value for key, value of params
	#END constructor

	abort: ->
		if @current_operation_queue instanceof Finch.OperationQueue
			@current_operation_queue.abort()
			@current_operation_queue = null
		#END if

		return @
	#END abort

	push: (node, route_component) ->
		unless node instanceof Finch.Node
			throw new Finch.Error("node must be an instanceof Finch.Node")
		#END unless

		unless isString(route_component)
			throw new Finch.Error("route_component must be a string")
		#END unless

		@nodes.push(node)
		@route_components.push(route_component)
		@observers.push([])
		@length++

		if node.type is Finch.Node.VARIABLE
			name = node.name.slice(1)
			@bindings[name] = route_component
		#END if

		return @
	#END push

	pushUntil: (target_load_path, target_node) ->
		unless target_load_path instanceof Finch.LoadPath
			throw new Error("target_load_path must be an instanceof Finch.LoadPath")
		#END unless

		unless target_node instanceof Finch.Node
			throw new Error("target_node must be an instanceof Finch.Node")
		#END unless

		current_index = @length
		end_index = target_load_path.indexFor(target_node)+1
		return @ if current_index >= end_index

		nodes = target_load_path.nodes.slice(current_index, end_index)
		route_components = target_load_path.route_components.slice(current_index, end_index)

		for node, i in nodes
			route_component = route_components[i]
			@push(node, route_component)
		#END for

		return @
	#END pushUntil

	pop: (node) ->
		return null unless @length > 0

		node = @nodes.pop()
		route_component = @route_components.pop()
		@observers.pop()
		@length--

		if @length <= 0
			@bindings = {}
		else if node.type is Finch.Node.VARIABLE
			name = node.name.slice(1)
			@bindings[name] = undefined
			delete @bindings[name]
		#END if

		return [node, route_component]
	#END pop

	popUntil: (target_node) ->
		unless (target_node is null) or (target_node instanceof Finch.Node)
			throw new Finch.Error("target_node must be an instanceof Finch.Node")
		#END unless

		while @length > 0 and @nodes[@length-1] isnt target_node
			@pop()
		#END while

		return @
	#END popUntil

	indexFor: (node) ->
		return -1 unless node instanceof Finch.Node

		for n, i in @nodes when n is node
			return i
		#END for

		return -1
	#END indexFor

	nodeAt: (index) ->
		return null unless index >= 0 and index < @length
		return @nodes[index]
	#END nodeAt

	prepareParams: (params) ->
		@params = params ? @params
		output_params = {}
		output_params[key] = value for key, value of @params
		output_params[key] = value for key, value of @bindings
		return @coerceObject(output_params)
	#END prepareParams

	#TODO: Move this to the UriManager
	coerceObject: (obj) ->
		return obj unless @coerce_types

		output_obj = {}

		for key, value of obj
			#Is this a boolean
			if value is "true"
				output_obj[key] = true
			else if value is "false"
				output_obj[key] = false
			#Is this an int
			else if /^[0-9]+$/.test(value)
				output_obj[key] = parseInt(value)
			#Is this a float
			else if /^[0-9]+\.[0-9]*$/.test(value)
				output_obj[key] = parseFloat(value)
			else
				output_obj[key] = value
			#END if
		#END for

		return output_obj
	#END coerceObject

	createOperationQueue: ->
		return new Finch.OperationQueue({
			before_start: =>
				@is_traversing = true
			#END before_started

			after_finish: (did_abort) =>
				@is_traversing = false
				@current_operation_queue = null
				@notifyObservers() unless did_abort
			#END after_finish
		})
	#END createOperationQueue

	reload: ->
		return @ if @length <= 0
		
		node = @nodeAt(@length-1)

		@current_operation_queue ?= @createOperationQueue()
		
		@current_operation_queue.appendOperation(Finch.Operation.UNLOAD, node, {
			setup_params: (action, node) => @prepareParams()
		})

		@current_operation_queue.appendOperation(Finch.Operation.LOAD, node, {
			setup_params: (action, node) => @prepareParams()
		})

		@current_operation_queue.execute()

		return @
	#END reload
			
	traverseTo: (target_load_path) ->
		unless target_load_path instanceof Finch.LoadPath
			throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath")
		#END unless

		if @routesAreEqual(target_load_path)
			return @ if @paramsAreEqual(target_load_path)
			@params = target_load_path.params
			return @ if @current_operation_queue?
			@notifyObservers()
			return @
		#END if

		ancestor_node = @findCommonAncestor(target_load_path)
		start_node = @nodeAt(@length-1)
		end_node = target_load_path.nodeAt(target_load_path.length-1)

		@current_operation_queue ?= @createOperationQueue()

		if start_node instanceof Finch.Node and end_node instanceof Finch.Node
			if start_node is end_node
				@current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
					setup_params: (action, node) => @prepareParams()
				})

				@current_operation_queue.appendOperation(Finch.Operation.TEARDOWN, start_node, {
					setup_params: (action, node) => @prepareParams()
					after_step: (action, node) => @popUntil(ancestor_node)
				})
				
				@current_operation_queue.appendOperation(Finch.Operation.SETUP, end_node, {
					before_step: (action, node) => @pushUntil(target_load_path, end_node)
					setup_params: (action, node) => @prepareParams(target_load_path.params)
				})

				@current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
					setup_params: (action, node) => @prepareParams(target_load_path.params)
				})
			else
				@current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
					setup_params: (action, node) => @prepareParams()
				})

				current_node = start_node
				while current_node isnt ancestor_node
					@current_operation_queue.appendOperation(Finch.Operation.TEARDOWN, current_node, {
						setup_params: (action, node) => @prepareParams()
						after_step: (action, node) => @popUntil(node.parent)
					})

					current_node = current_node.parent
				#END while

				target_node_chain = []
				current_node = end_node
				while current_node instanceof Finch.Node and current_node isnt ancestor_node
					target_node_chain.push(current_node)
					current_node = current_node.parent
				#END while

				#Append the operations in reverse order
				while current_node = target_node_chain.pop()
					@current_operation_queue.appendOperation(Finch.Operation.SETUP, current_node, {
						before_step: (action, node) => @pushUntil(target_load_path, node)
						setup_params: (action, node) => @prepareParams(target_load_path.params)
					})
				#END while

				@current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
					setup_params: (action, node) => @prepareParams(target_load_path.params)
				})
			#END if
		else if end_node instanceof Finch.Node
			target_node_chain = []
			current_node = end_node
			while current_node instanceof Finch.Node and current_node isnt ancestor_node
				target_node_chain.push(current_node)
				current_node = current_node.parent
			#END while

			#Append the operations in reverse order
			while current_node = target_node_chain.pop()
				@current_operation_queue.appendOperation(Finch.Operation.SETUP, current_node, {
					before_step: (action, node) => @pushUntil(target_load_path, node)
					setup_params: (action, node) => @prepareParams(target_load_path.params)
				})
			#END while

			@current_operation_queue.appendOperation(Finch.Operation.LOAD, end_node, {
				setup_params: (action, node) => @prepareParams(target_load_path.params)
			})
		else if start_node instanceof Finch.Node
			@current_operation_queue.appendOperation(Finch.Operation.UNLOAD, start_node, {
				setup_params: (action, node) => @prepareParams()
			})

			current_node = start_node
			while current_node isnt ancestor_node
				@current_operation_queue.appendOperation(Finch.Operation.TEARDOWN, current_node, {
					setup_params: (action, node) => @prepareParams()
					after_step: (action, node) => @popUntil(node.parent)
				})

				current_node = current_node.parent
			#END while
		#END if

		@current_operation_queue.execute()

		return @
	#END traverseTo

	findCommonAncestor: (target_load_path) ->
		unless target_load_path instanceof Finch.LoadPath
			throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath")
		#END unless

		current_node = @nodes[@length-1]
		target_node = target_load_path.nodes[target_load_path.length-1]
		ancestor_node = null

		current_node_chain = []
		while current_node instanceof Finch.Node
			current_node_chain.unshift(current_node)
			current_node = current_node.parent
		#END while

		target_node_chain = []
		while target_node instanceof Finch.Node
			target_node_chain.unshift(target_node)
			target_node = target_node.parent
		#END while

		for current_node, i in current_node_chain
			target_node = target_node_chain[i]
			return ancestor_node unless current_node is target_node

			component_index = @indexFor(target_node)
			current_route = @route_components.slice(0,component_index+1).join("/")
			target_route = target_load_path.route_components.slice(0,component_index+1).join("/")
			return ancestor_node unless current_route is target_route

			ancestor_node = current_node
		#END for

		return ancestor_node
	#END findCommonAncestor

	routesAreEqual: (target_load_path) ->
		unless target_load_path instanceof Finch.LoadPath
			throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath")
		#END unless

		return false unless @length is target_load_path.length

		for route_component, i in @route_components
			target_route_component = target_load_path.route_components[i]
			return false unless route_component is target_route_component
		#END for

		return true
	#END routesAreEqual

	paramsAreEqual: (target_load_path) ->
		unless target_load_path instanceof Finch.LoadPath
			throw new Finch.Error("target_load_path must be an instanceof Finch.LoadPath")
		#END unless

		params_length = 0
		params_length++ for key, value of @params
		
		target_params_length = 0
		target_params_length++ for key, value of target_load_path.params

		return false unless params_length is target_params_length

		for key, value of @params
			return false if (v = target_load_path.params[key]) is undefined
			return false unless v is value
		#END for

		return true
	#END paramsAreEqual

	addObserver: (observer) ->
		return observer unless @length > 0
		return observer unless @nodes[@length-1].should_observe
		@observers[@length-1].push(observer)
		return observer
	#END addObserver

	notifyObservers: ->
		for observer_list, i in @observers
			new_observer_list = []
			for observer in observer_list when not observer.is_disposed
				observer.notify(@coerceObject(@params))
				new_observer_list.push(observer)
			#END for
			@observers[i] = new_observer_list
		#END for

		return @
	#END notifyObservers

	toString: ->
		url = @route_components.join("/")
		params = ("#{key}=#{value}" for key, value of @params).join("&")
		url += "?#{params}" if params.length > 0
		return url
	#END toString
#END LoadPath