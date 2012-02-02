(function() {
  var DocsViewModel, LayoutViewModel, defer, isFunction, isString, sectionize, trim;

  isString = function(object) {
    return Object.prototype.toString.call(object) === "[object String]";
  };

  isFunction = function(object) {
    return Object.prototype.toString.call(object) === "[object Function]";
  };

  trim = function(str) {
    return str.replace(/^\s+/, '').replace(/\s+$/, '');
  };

  defer = function(callback) {
    if (!isFunction(callback)) callback = (function() {});
    return setTimeout(callback, 1);
  };

  sectionize = function(input) {
    return trim(input != null ? input : "").toLowerCase().replace(/[^a-z0-9]+/g, "");
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

  Finch.route("/", function(_arg, callback) {
    _arg;
    return mpq.track("Viewing Home", {}, function() {
      return $("#content").fadeTo('fast', 0, function() {
        return $.get("./pages/home.tmpl", function(data) {
          var Layout;
          Layout = LayoutViewModel.instance;
          Layout.ContentViewModel(new DocsViewModel);
          Layout.ContentTemplate(data);
          console.log(data);
          return $("#content").fadeTo('fast', 1, callback);
        });
      });
    });
  });

  Finch.route("download", function(_arg, callback) {
    _arg;
    return mpq.track("Viewing Download", {}, function() {
      return $("#content").fadeTo('fast', 0, function() {
        return $.get("./pages/download.tmpl", function(data) {
          var Layout;
          Layout = LayoutViewModel.instance;
          Layout.ContentViewModel({});
          Layout.ContentTemplate(data);
          return $("#content").fadeTo('fast', 1, callback);
        });
      });
    });
  });

  Finch.route("docs", {
    setup: function(_arg, callback) {
      _arg;
      return mpq.track("Viewing Documentation", {}, function() {
        return $("#content").fadeTo('fast', 0, function() {
          return $.get("./pages/docs.tmpl", function(data) {
            var Layout;
            Layout = LayoutViewModel.instance;
            Layout.ContentViewModel(new DocsViewModel);
            Layout.ContentTemplate(data);
            return defer(callback);
          });
        });
      });
    },
    load: function() {
      return Finch.call("docs/introduction");
    }
  });

  Finch.route("[docs]/:article", {
    setup: function(_arg, callback) {
      var article;
      article = _arg.article;
      return $.get("./pages/docs/" + article + ".md", function(data) {
        var Docs;
        Docs = DocsViewModel.instance;
        Docs.ArticleViewModel({});
        Docs.ArticleTemplate(marked(data));
        return $("#content").fadeTo('fast', 1, callback);
      });
    },
    load: function(_arg) {
      var article, elm, _i, _len, _ref;
      article = _arg.article;
      article = sectionize(article);
      _ref = $("h1");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        elm = _ref[_i];
        elm = $(elm);
        if (sectionize(elm.text()) === article) {
          return $.scrollTo(elm, {
            duration: 1000,
            offset: -$("#header").height() - 30
          });
        }
      }
    }
  });

  Finch.route("[docs/:article]/:section", {
    load: function(_arg) {
      var elm, section, _i, _len, _ref;
      section = _arg.section;
      section = sectionize(section);
      _ref = $("h2");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        elm = _ref[_i];
        elm = $(elm);
        if (sectionize(elm.text()) === section) {
          return $.scrollTo(elm, {
            duration: 1000,
            offset: -$("#header").height() - 30
          });
        }
      }
    }
  });

  Finch.route("[docs/:article/:section]/:subsection", {
    load: function(_arg) {
      var elm, subsection, _i, _len, _ref;
      subsection = _arg.subsection;
      subsection = sectionize(subsection);
      _ref = $("h3");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        elm = _ref[_i];
        elm = $(elm);
        if (sectionize(elm.text()) === subsection) {
          return $.scrollTo(elm, {
            duration: 1000,
            offset: -$("#header").height() - 30
          });
        }
      }
    }
  });

  $(function() {
    ko.applyBindings(new LayoutViewModel);
    return Finch.listen();
  });

}).call(this);
