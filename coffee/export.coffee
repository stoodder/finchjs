finch_export = new Finch
if jasmine?
	finch_export.Tree = Finch.Tree
	finch_export.Node = Finch.Node
	finch_export.LoadPath = Finch.LoadPath
	finch_export.OperationQueue = Finch.OperationQueue
	finch_export.Operation = Finch.Operation
	finch_export.Error = Finch.Error
	finch_export.NotFoundError = Finch.NotFoundError
	finch_export.ParsedRouteString = Finch.ParsedRouteString
#END if

if module?.exports?
	module.exports = finch_export
else
	@Finch = finch_export
#END if