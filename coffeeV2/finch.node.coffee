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

	setup_callback: null
	load_callback: null
	unload_callback: null
	teardown_callback: null

	constructor: (name, parent) ->
		@name = name
		@type = Finch.Node.resolveType(@name)
		@parent = parent ? null
		@params = {}
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

	updateCallbacks: (callbacks) ->
		if isFunction(callbacks)
			_callback = callbacks
			_has_executed = false

			downwards_callback = -> _has_executed = false
			upwards_callback = (params, continuation) ->
				return continuation() if _has_executed
				_has_executed = true
				
				if _callback.length is 2
					_callback.call(this, params, continuation)
				else
					_callback.call(this, params)
					continuation()
				#END if
			#END upwards_callback

			callbacks =
				setup: upwards_callback
				load: upwards_callback
				unload: downwards_callback
				teardown: downwards_callback
			#END callbacks
		#END if

		return @ unless isObject(callbacks)

		@setup_callback = callbacks.setup if isFunction(callbacks.setup)
		@load_callback = callbacks.load if isFunction(callbacks.load)
		@unload_callback = callbacks.unload if isFunction(callbacks.unload)
		@teardown_callback = callbacks.teardown if isFunction(callbacks.teardown)

		return @
	#END updateCallbacks

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
#END Finch.Node