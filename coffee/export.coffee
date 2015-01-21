# Thanks @ismell https://github.com/ismell for the help here
if module?.exports?
	module.exports = Finch
else if define?.amd? and isFunction(define)
	define(['Finch'], Finch)
else
	@Finch = Finch
#END if