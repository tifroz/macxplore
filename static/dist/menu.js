// Generated by CoffeeScript 1.10.0
window.ReportMenuItem = React.createClass({displayName: "ReportMenuItem",
  render: function() {
    return React.createElement("div", {
      "className": "menu-item"
    }, React.createElement("a", {
      "onClick": this.selectItem
    }, this.props.report.name), React.createElement("div", {
      "className": "menu-item-details"
    }, React.createElement("div", null, React.createElement("span", null, this.props.report.database), React.createElement("span", null, "."), React.createElement("span", null, this.props.report.collection)), React.createElement("div", {
      "className": "dropdown"
    }, React.createElement("a", {
      "id": "dLabel",
      "data-target": "#",
      "data-toggle": "dropdown",
      "role": "button",
      "aria-haspopup": "true",
      "aria-expanded": "false"
    }, "\t\t\t\t\t\tActions", React.createElement("span", {
      "class": "caret"
    })), React.createElement("ul", {
      "className": "dropdown-menu",
      "aria-labelledby": "dLabel"
    }, React.createElement("li", null, React.createElement("a", {
      "onClick": this.deleteItem
    }, "delete")), React.createElement("li", null, React.createElement("a", {
      "onClick": this.duplicateItem
    }, "duplicate"))))));
  },
  duplicateItem: function(e) {
    var params;
    e.preventDefault();
    params = {
      url: "/report/duplicate/" + this.props.report._id,
      method: "POST"
    };
    return this.props.ajax(params);
  },
  deleteItem: function(e) {
    var params;
    e.preventDefault();
    if (confirm(this.props.report.name + " will be deleted permanently")) {
      params = {
        url: "/report/" + this.props.report._id,
        method: "DELETE"
      };
      return this.props.ajax(params);
    }
  },
  selectItem: function(e) {
    e.preventDefault();
    e = $.Event("didSelect", {
      report: this.props.report
    });
    return $("body").trigger(e);
  }
});

window.ReportCreate = React.createClass({displayName: "ReportCreate",
  render: function() {
    return React.createElement("form", {
      "onSubmit": this.onSubmit
    }, React.createElement("input", {
      "type": "text",
      "placeholder": "database",
      "className": "form-control",
      "onChange": this.dbnameDidChange
    }), React.createElement("select", {
      "className": "form-control"
    }, this.props.collections.map(function(c, i) {
      return React.createElement("option", {
        "key": i,
        "value": c
      }, c);
    })), React.createElement("button", {
      "type": "submit",
      "disabled": this.props.collections.length === 0,
      "className": "btn btn-primary btn-sm"
    }, "Create"));
  },
  getDefaultProps: function() {
    var props;
    return props = {
      collections: []
    };
  },
  componentWillMount: function() {
    return this.dbnameDidChangeDebounced = _.debounce(this.dbnameDidChangeDebounced, 300);
  },
  dbnameDidChange: function(e) {
    this.dbnameValue = e.target.value;
    return this.dbnameDidChangeDebounced();
  },
  dbnameDidChangeDebounced: function() {
    return this.props.ajax({
      url: "/" + this.dbnameValue + "/collections"
    });
  },
  onSubmit: function(e) {
    var params;
    e.preventDefault();
    params = {
      url: "/report",
      method: "POST",
      data: {
        database: $("input", e.target).val(),
        collection: $("select", e.target).val()
      }
    };
    return this.props.ajax(params);
  }
});

window.ReportMenuList = React.createClass({displayName: "ReportMenuList",
  render: function() {
    return React.createElement("nav", null, this.props.reports.map((function(_this) {
      return function(r, i) {
        return React.createElement(ReportMenuItem, {
          "key": r._id,
          "report": r,
          "ajax": _this.props.ajax
        });
      };
    })(this)));
  },
  getDefaultProps: function() {
    var props;
    return props = {
      reports: [],
      ajax: (function() {})
    };
  }
});

window.Menu = React.createClass({displayName: "Menu",
  mixins: [AjaxMixin],
  getInitialState: function() {
    var state;
    return state = {
      collections: [],
      reports: [],
      xhr: null
    };
  },
  componentDidMount: function() {
    return this.ajax({
      url: "/reports"
    });
  },
  render: function() {
    return React.createElement("div", null, React.createElement(XHRError, {
      "xhr": this.state.xhr
    }), React.createElement(ReportCreate, {
      "collections": this.state.collections,
      "ajax": this.ajax
    }), React.createElement(ReportMenuList, {
      "reports": this.state.reports,
      "ajax": this.ajax
    }));
  }
});
