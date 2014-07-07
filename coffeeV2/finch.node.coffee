class Finch.Node
	@LITERAL = "literal"
	@VARIABLE = "variable"
	VALID_TYPES = [@LITERAL, @VARIABLE]

	VARIABLE_REGEX = /^:[a-z0-9_-]+$/i

	@resolveType = (name) ->
		if (new RegExp(VARIABLE_REGEX).test(name))
			return Finch.Node.VARIABLE
		else
			return Finch.Node.LITERAL
		#END if
	#END resolveType

	type: null
	name: null
	parent: null
	params: null
	literal_children: null
	variable_child: null
	should_observe: true
	is_endpoint: false

	setup_callback: null
	load_callback: null
	unload_callback: null
	teardown_callback: null

	generalized_callback: null

	constructor: (name, parent) ->
		@name = name
		@type = Finch.Node.resolveType(@name)
		@parent = parent ? null
		@params = {}
		@context = {}
	#END constructor

	addChildNode: (node) ->
		unless node instanceof Finch.Node
			throw new Finch.Error("node must be an instanceof Finch.Node")
		#END unless

		if node.type is Finch.Node.VARIABLE
			@variable_child = node
		else
			@literal_children ?= {}

			if @literal_children[node.name]
				throw new Finch.Error("A node with the name '#{node.name}' is already a child of the node '#{@name}'")
			#END if

			@literal_children[node.name] = node
		#END if

		return @
	#END addChildNode

	findChildNode: (name) ->
		unless isString(name)
			throw new Finch.Error("name must be a String")
		#END unless

		type = Finch.Node.resolveType(name)

		if type is Finch.Node.VARIABLE
			child = @variable_child
		else
			child = @literal_children?[name]
		#END if

		return (child ? null)
	#END findChildNode

	findMatchingChildNode: (component) ->
		unless isString(component)
			throw new Finch.Error("component must be a String")
		#END unless

		return ( @literal_children?[component] ? @variable_child ? null )
	#END findMatchingChildNode

	setParentNode: (node) ->
		unless node is null or (node instanceof Finch.Node)
			throw new Finch.Error("node must be an instanceof Finch.Node")
		#END unless

		@parent = node

		return @
	#END setParentNode

	setCallbacks: (callbacks) ->
		if isFunction(callbacks)
			@generalized_callback = callbacks
			@setup_callback = @load_callback = @unload_callback = @teardown_callback = null
		else if isObject(callbacks)
			@generalized_callback = null
			@setup_callback = if isFunction(callbacks.setup) then callbacks.setup else (->)
			@load_callback = if isFunction(callbacks.load) then callbacks.load else (->)
			@unload_callback = if isFunction(callbacks.unload) then callbacks.unload else (->)
			@teardown_callback = if isFunction(callbacks.teardown) then callbacks.teardown else (->)
		#END if

		return @
	#END setCallbacks

	getCallback: (action, previous_action, previous_node) ->
		if isFunction(@generalized_callback)
			return (->) if action is Finch.Operation.UNLOAD
			return (->) if action is Finch.Operation.TEARDOWN
			return (->) if previous_action is Finch.Operation.SETUP and previous_node is @
			method = @generalized_callback
			@should_observe = action is Finch.Operation.SETUP
		else
			method = switch action
				when Finch.Operation.SETUP then @setup_callback
				when Finch.Operation.LOAD then @load_callback
				when Finch.Operation.UNLOAD then @unload_callback
				when Finch.Operation.TEARDOWN then @teardown_callback
				else throw new Finch.Error("Invalid action '#{action}' given")
			#END method
		#END if

		return (->) unless isFunction(method)

		_method = method.bind(@getContext())
		_method.length = method.length

		return _method
	#END getCallback

	getContext: ->
		context = @context
		context.parent = if @parent instanceof Finch.Node then @parent.context else null
		return context
	#END getContext

	findCommonAncestor: (target_node) ->
		unless target_node instanceof Finch.Node
			throw new Finch.Error("target_node must be an instanceof Finch.Node")
		#END unless

		active_hierarchy = []
		node = @
		while node instanceof Finch.Node
			active_hierarchy.push(node)
			node = node.parent
		#END while

		target_hierarchy = []
		node = target_node
		while node instanceof Finch.Node
			target_hierarchy.push(node)
			node = node.parent
		#END while

		for active_ancestor in active_hierarchy
			for target_ancestor in target_hierarchy
				return active_ancestor if active_ancestor is target_ancestor
			#END for
		#END for

		unless ancestor instanceof Finch.Node
			throw new Finch.Error("Could not find common ancestor between '#{@name}' and '#{target_node.name}'")
		#END unless
	#END findCommonAncestor

	toString: -> @name
#END Finch.Node