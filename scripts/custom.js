(function() {
  var DocsViewModel, LayoutViewModel, isFunction, isString, makeCallback,
    __slice = Array.prototype.slice;

  isString = function(object) {
    return Object.prototype.toString.call(object) === "[object String]";
  };

  isFunction = function(object) {
    return Object.prototype.toString.call(object) === "[object Function]";
  };

  makeCallback = function(func, cb) {
    return function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (isFunction(func)) func.apply(null, args);
      if (isFunction(cb)) return cb();
    };
  };

  LayoutViewModel = (function() {

    LayoutViewModel.instance = null;

    function LayoutViewModel() {
      LayoutViewModel.instance = this;
      this.ContentViewModel = ko.observable({});
      this.ContentTemplate = ko.observable();
    }

    return LayoutViewModel;

  })();

  DocsViewModel = (function() {

    DocsViewModel.instance = null;

    function DocsViewModel() {
      DocsViewModel.instance = this;
      this.ArticleViewModel = ko.observable({});
      this.ArticleTemplate = ko.observable();
    }

    return DocsViewModel;

  })();

  Finch.route("/", function() {
    return Finch.call("home");
  });

  Finch.route("/:page", function(_arg, callback) {
    var page;
    page = _arg.page;
    if (!isString(page)) page = "home";
    page = page.toLowerCase();
    return $.get("./pages/" + page + ".tmpl", function(html) {
      var Layout;
      Layout = LayoutViewModel.instance;
      Layout.ContentViewModel({});
      Layout.ContentTemplate(html);
      return callback();
    });
  });

  Finch.route("/docs", function(bindings, callback) {
    return $.get("./pages/docs.tmpl", function(data) {
      var Layout;
      Layout = LayoutViewModel.instance;
      Layout.ContentViewModel(new DocsViewModel);
      Layout.ContentTemplate(data);
      return callback();
    });
  });

  Finch.route("[/docs]/:article", function(_arg, callback) {
    var article;
    article = _arg.article;
    return $.get("./pages/docs/" + article + ".md", function(data) {
      var Docs;
      Docs = DocsViewModel.instance;
      Docs.ArticleTemplate(markdown.toHTML(data));
      return callback();
    });
  });

  $(function() {
    ko.applyBindings(new LayoutViewModel);
    return Finch.listen();
  });

}).call(this);
