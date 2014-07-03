describe "Finch.RouteNode", ->
	describe "Instance Methods", ->
		describe "findOrCreateNode", ->
			node = new Finch.RouteNode("!")
			child_literal_one = null
			child_literal_two = null
			child_variable = null
			great_great_grandchild_literal = null
			great_great_grandchild_variable = null

			settings = {}

			beforeEach ->
				sinonSpyOn( Finch.RouteNode::, "updateSettings" )
			#END beforeEach

			it "Should add a child literal properly", ->
				child_literal_one = node.findOrCreateNode(["hello"], settings)

				expect( node.literal_children.length ).toBe( 1 )
				expect( node.literal_children ).toEqual([child_literal_one])

				expect( child_literal_one.parent_node ).toBe( node )

				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOnce()
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOn( child_literal_one )
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledWith(settings)

				expect( child_literal_one ).toEqual( jasmine.any(Finch.RouteNode) )
			#END it

			it "Should add a second child literal properly", ->
				child_literal_two = node.findOrCreateNode(["foo"], settings)

				expect( node.literal_children.length ).toBe( 2 )
				expect( node.literal_children ).toEqual([child_literal_one, child_literal_two])
				
				expect( child_literal_two.parent_node ).toBe( node )

				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOnce()
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOn( child_literal_two )
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledWith(settings)

				expect( child_literal_two ).toEqual( jasmine.any(Finch.RouteNode) )
			#END it

			it "Should add a second child literal properly", ->
				child_variable = node.findOrCreateNode([":free"], settings)

				expect( node.variable_child ).toBe( child_variable )
				
				expect( child_variable.parent_node ).toBe( node )

				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOnce()
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOn( child_variable )
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledWith(settings)

				expect( child_variable ).toEqual( jasmine.any(Finch.RouteNode) )
			#END it

			it "Should find existing nodes", ->
				expect( node.findOrCreateNode(["hello"]) ).toBe( child_literal_one )
				expect( node.findOrCreateNode(["foo"]) ).toBe( child_literal_two )
				expect( node.findOrCreateNode([":free"]) ).toBe( child_variable )
				
				expect( Finch.RouteNode::updateSettings ).not.toHaveBeenCalledOnce()
			#END it

			it "Should add a great great grand child literal properly", ->
				great_great_grandchild_literal = node.findOrCreateNode(["hello", "world", "you", "rock"], settings)

				expect( great_great_grandchild_literal.name ).toBe( "rock" )
				
				expect( great_great_grandchild_literal.parent_node.name ).toBe( "you" )
				expect( great_great_grandchild_literal.parent_node.parent_node.name ).toBe( "world" )
				expect( great_great_grandchild_literal.parent_node.parent_node.parent_node.name ).toBe( "hello" )
				expect( great_great_grandchild_literal.parent_node.parent_node.parent_node.parent_node ).toBe( node )

				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOnce()
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOn( great_great_grandchild_literal )
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledWith(settings)

				expect( great_great_grandchild_literal ).toEqual( jasmine.any(Finch.RouteNode) )
			#END it

			it "Should add a great great grand child literal properly", ->
				great_great_grandchild_variable = node.findOrCreateNode([":free", "bird", ":rock", ":classics"], settings)

				expect( great_great_grandchild_variable.name ).toBe( ":classics" )
				
				expect( great_great_grandchild_variable.parent_node.name ).toBe( ":rock" )
				expect( great_great_grandchild_variable.parent_node.parent_node.name ).toBe( "bird" )
				expect( great_great_grandchild_variable.parent_node.parent_node.parent_node.name ).toBe( ":free" )
				expect( great_great_grandchild_variable.parent_node.parent_node.parent_node.parent_node ).toBe( node )
				
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOnce()
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledOn( great_great_grandchild_variable )
				expect( Finch.RouteNode::updateSettings ).toHaveBeenCalledWith(settings)

				expect( great_great_grandchild_variable ).toEqual( jasmine.any(Finch.RouteNode) )
			#END it

			it "Should find existing great great grand children", ->
				expect( node.findOrCreateNode(["hello", "world", "you", "rock"]) ).toBe( great_great_grandchild_literal )
				expect( node.findOrCreateNode([":foo", "bird", ":rock", ":classics"]) ).toBe( great_great_grandchild_variable )
				
				expect( Finch.RouteNode::updateSettings ).not.toHaveBeenCalledOnce()
			#END it
		#END describe

		describe "toString", ->
		#END describe
	#END describe
#END describe

describe "Finch.RouteTree", ->

	describe "constructor", ->
	#END describe

	describe "Static Methods", ->
		describe "_standardizeRouteString", ->
			tree = new Finch.RouteTree

			it "Should work properly without a parent", ->
				expect( Finch.RouteTree._standardizeRouteString("!") ).toEqual
					parent_route_string: null
					route_string: "!"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("/!/") ).toEqual
					parent_route_string: null
					route_string: "!/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("hello/world") ).toEqual
					parent_route_string: null
					route_string: "!/hello/world/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("/hello/world/") ).toEqual
					parent_route_string: null
					route_string: "!/hello/world/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("!/hello/world") ).toEqual
					parent_route_string: null
					route_string: "!/hello/world/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("/!/hello/world/") ).toEqual
					parent_route_string: null
					route_string: "!/hello/world/"
				#END toEqual
			#END it

			it "Should work properly with a parent", ->
				expect( Finch.RouteTree._standardizeRouteString("[!]") ).toEqual
					parent_route_string: "!"
					route_string: "!/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("[!]/") ).toEqual
					parent_route_string: "!"
					route_string: "!/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("/[!/]") ).toEqual
					parent_route_string: "!"
					route_string: "!/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("[hello]/world") ).toEqual
					parent_route_string: "!/hello"
					route_string: "!/hello/world/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("[/hello/]world/") ).toEqual
					parent_route_string: "!/hello"
					route_string: "!/hello/world/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("[!/hello]/world") ).toEqual
					parent_route_string: "!/hello"
					route_string: "!/hello/world/"
				#END toEqual

				expect( Finch.RouteTree._standardizeRouteString("[/!/hello]/world/") ).toEqual
					parent_route_string: "!/hello"
					route_string: "!/hello/world/"
				#END toEqual
			#END it
		#END describe

		describe "_splitRoute", ->
			tree = new Finch.RouteTree

			it "Should work properly", ->
				expect( Finch.RouteTree._splitRoute("!/hello/:world") ).toEqual(["!", "hello", ":world"])
				expect( Finch.RouteTree._splitRoute("/!/hello/:world/") ).toEqual(["", "!", "hello", ":world", ""])
				expect( Finch.RouteTree._splitRoute("!") ).toEqual(["!"])
				expect( Finch.RouteTree._splitRoute("") ).toEqual([])
				expect( Finch.RouteTree._splitRoute("/") ).toEqual(["", ""])
			#END it
		#END describe
	#END describe

	describe "Instance Methods", ->
		describe "addRoute", ->
		#END describe
	#END describe
#END describe