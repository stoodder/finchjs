class Finch.ParsedRouteString
	components: null
	parent_components: null

	constructor: (components, parent_components) ->
		unless isArray(components)
			throw new Finch.Error("components must be an Array")
		#END unless

		parent_components = [] unless isArray(parent_components)

		@components = components
		@parent_components = parent_components
	#END constructor
#END ParsedRouteString