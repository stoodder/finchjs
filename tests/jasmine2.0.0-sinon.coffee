sinonMatchers = {}
sinonToJasmineMap =
	'called': 'toHaveBeenCalled'
	'calledOnce': 'toHaveBeenCalledOnce'
	'calledTwice': 'toHaveBeenCalledTwice'
	'calledThrice': 'toHaveBeenCalledThrice'
	'calledBefore': 'toHaveBeenCalledBefore'
	'calledAfter': 'toHaveBeenCalledAfter'
	'calledOn': 'toHaveBeenCalledOn'
	'alwaysCalledOn': 'toHaveBeenAlwaysCalledOn'
	'calledWith': 'toHaveBeenCalledWith'
	'alwaysCalledWith': 'toHaveBeenAlwaysCalledWith'
	'calledWithExactly': 'toHaveBeenCalledWithExactly'
	'alwaysCalledWithExactly': 'toHaveBeenAlwaysCalledWithExactly'
	'calledWithMatch': 'toHaveBeenCalledWithMatch'
	'alwaysCalledWithMatch': 'toHaveBeenAlwaysCalledWithMatch'

	'returned': 'toHaveReturned'
	'alwaysReturned': 'toHaveAlwaysReturned'
	'threw': 'toHaveThrown'
	'alwaysThrew': 'toHaveAlwaysThrown'
#END sinonToJasmineMap

jasmineMessageGenerator =
	'toHaveBeenCalled': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveBeenCalled"
		return message.trim()
	#END toHaveBeenCalled	

	'toHaveBeenCalledOnce': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have been called once"
		return message.trim()
	#END toHaveBeenCalledOnce	

	'toHaveBeenCalledTwice': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have been called twice"
		return message.trim()
	#END toHaveBeenCalledTwice	

	'toHaveBeenCalledThrice': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have been called thrice"
		return message.trim()
	#END toHaveBeenCalledThrice	

	'toHaveBeenCalledBefore': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have been called before "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was CalledBefore #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenCalledBefore	

	'toHaveBeenCalledAfter': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have been calld after "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was CalledAfter #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenCalledAfter	

	'toHaveBeenCalledOn': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have been called on "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was CalledOn #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenCalledOn	

	'toHaveBeenAlwaysCalledOn': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have always been called on "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was always called on #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenAlwaysCalledOn	

	'toHaveBeenCalledWith': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "to have been called with "
		if other_args?.length > 0
			message += jasmine.pp(other_args)
		#END if

		if spy?.lastCall?.args?
			message += " but was called with #{jasmine.pp spy.lastCall.args}"
		#END if

		return message.trim()
	#END toHaveBeenCalledWith	

	'toHaveBeenAlwaysCalledWith': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveBeenAlwaysCalledWith "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was AlwaysCalledWith #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenAlwaysCalledWith	

	'toHaveBeenCalledWithExactly': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveBeenCalledWithExactly "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was CalledWithExactly #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenCalledWithExactly	

	'toHaveBeenAlwaysCalledWithExactly': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveBeenAlwaysCalledWithExactly "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was AlwaysCalledWithExactly #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenAlwaysCalledWithExactly	

	'toHaveBeenCalledWithMatch': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveBeenCalledWithMatch "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was CalledWithMatch #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenCalledWithMatch	

	'toHaveBeenAlwaysCalledWithMatch': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveBeenAlwaysCalledWithMatch "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but was AlwaysCalledWithMatch #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveBeenAlwaysCalledWithMatch	


	'toHaveReturned': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveReturned "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but returned #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveReturned	

	'toHaveAlwaysReturned': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveAlwaysReturned "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but returned #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveAlwaysReturned	

	'toHaveThrown': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveThrown "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but threw #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveThrown	

	'toHaveAlwaysThrown': (passed, spy, other_args) ->
		message = "Expected spy '#{spy}' "
		message += "not " if passed
		message += "toHaveAlwaysThrown "
		if other_args?.length > 0
			message += jasmine.pp(other_args) + " but threw #{jasmine.pp spy.lastCall.args}"
		#END if
		return message.trim()
	#END toHaveAlwaysThrown	
#END jasmineMessageGenerator



createCustomMatcher = (arg, util, customEqualityTesters) ->
	sinon.match (val) -> util.equals(val, arg, customEqualityTesters)
#END createCustomMatcher

createMatcher = (sinonName, jasmineName) ->
	original = jasmineRequire[jasmineName]

	return (util, customEqualityTesters) ->
		compare: (args...) ->
			spy = args[0]

			if original and jasmine.isSpy(spy)
				{compare} = original(jasmine)(util, customEqualityTesters)
				return compare(args...)
			#END if

			sinonProperty = spy[sinonName]

			for arg, i in args when arg?
				if (typeof arg.jasmineMatches is 'function') or (arg instanceof jasmine.ObjectContaining) 
					args[i] = createCustomMatcher(arg, util, customEqualityTesters)
				#END if
			#END for

			if (typeof sinonProperty is 'function')
				pass = sinonProperty.apply(spy, args[1..])
			else
				pass = sinonProperty
			#END if

			message = jasmineMessageGenerator[jasmineName](pass, spy, args[1..])

			return {pass, message}
		#END compare
	#END return
#END createMatcher

for sinonName, jasmineName of sinonToJasmineMap
	sinonMatchers[jasmineName] = createMatcher(sinonName, jasmineName)
#END for

jasmine.Expectation.addCoreMatchers(sinonMatchers)

spies = []
@sinonSpyOn = (obj, method) -> spies.push(sinon.spy(obj, method))

afterEach ->
	spy.restore() for spy in spies
	spies = []
#END afterEach