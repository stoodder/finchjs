(function() {
  var LayoutViewModel, isString;

  isString = function(object) {
    return Object.prototype.toString.call(object) === "[object String]";
  };

  LayoutViewModel = (function() {

    function LayoutViewModel() {
      this.ContentViewModel = ko.observable();
      this.ContentTemplate = ko.observable();
    }

    LayoutViewModel.instance = new LayoutViewModel;

    return LayoutViewModel;

  })();

  Finch.route("/", function() {
    return Finch.call("/Home");
  });

  Finch.route("/:page", function(_arg, callback) {
    var Layout, page, tmpl;
    page = _arg.page;
    Layout = LayoutViewModel.instance;
    if (!isString(page)) page = "Home";
    tmpl = page.toLowerCase();
    return $.get("./pages/" + tmpl + ".tmpl", function(data) {
      Layout.ContentTemplate(data);
      return callback();
    });
  });

  $(function() {
    var Layout;
    Layout = LayoutViewModel.instance;
    Layout.ContentViewModel({});
    ko.applyBindings(Layout);
    return Finch.listen();
  });

}).call(this);
