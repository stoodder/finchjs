class Finch.ParsedRouteString
	components: null
	parent_components: null

	constructor: (components, parent_components) ->
		unless isArray(components)
			throw new Finch.Error("components must be an Array")
		#END unless

		parent_components = [] unless isArray(parent_components)

		for parent_component, i in parent_components
			unless components[i] is parent_component
				throw new Finch.Error("Parent components does not match the components")
			#END unless
		#END for

		@components = components
		@parent_components = parent_components
	#END constructor
#END ParsedRouteString