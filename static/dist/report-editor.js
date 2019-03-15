// Generated by CoffeeScript 1.10.0
var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

window.JSEditor = React.createClass({displayName: "JSEditor",
  adjustRowHeight: function() {
    var lines;
    lines = this.editor.getSession().getScreenLength();
    this.editor.setOptions({
      maxLines: lines
    });
    $(this.aceEditorWrapper).attr("style", "height: " + (lines * 1.2 + 1) + "em");
    return console.log("OK getScreenLength=" + lines);
  },
  contentDidChange: function() {
    this.adjustRowHeight();
    return this.contentDidChangeDebounced();
  },
  contentDidChangeDebounced: function() {
    if (this.editor.getSession().getAnnotations().length === 0) {
      return this.props.didChange(this.props.path, this.props.type + ":" + (this.editor.getValue()));
    } else {
      return console.log("Editor in error (no changes)");
    }
  },
  componentDidUpdate: function() {
    return this.configureAceEditor();
  },
  shouldComponentUpdate: function() {
    return false;
  },
  componentDidMount: function() {
    this.configureAceEditor();
    this.contentDidChangeDebounced = _.debounce(this.contentDidChangeDebounced, 500);
    return this.adjustRowHeight();
  },
  componentWillUnmount: function() {},
  render: function() {
    return React.createElement("div", {
      "className": "editor-wrapper"
    }, React.createElement("div", {
      "className": "ace-editor-wrapper",
      "ref": ((function(_this) {
        return function(r) {
          return _this.aceEditorWrapper = r;
        };
      })(this))
    }, React.createElement("div", {
      "className": "ace-editor",
      "id": this.props.path
    }, this.props.value)));
  },
  configureAceEditor: function() {
    console.log("OK configureAceEditor for " + this.props.path);
    this.editor = ace.edit(this.props.path);
    this.editor.setTheme("ace/theme/monokai");
    this.editor.getSession().setMode("ace/mode/" + this.props.mode);
    this.editor.on("change", this.contentDidChange);
    return this.editor.session.setOptions({
      tabSize: 2,
      useSoftTabs: true,
      showInvisibles: true
    });
  }
});

window.EditableDiv = React.createClass({displayName: "EditableDiv",
  getInitialState: function() {
    var state;
    return state = {
      isEditing: false,
      text: this.props.initialText
    };
  },
  render: function() {
    console.log("EditableDiv rendering...", this.props, this.state);
    return React.createElement("div", {
      "className": "editableDiv"
    }, (this.state.isEditing ? React.createElement("input", {
      "type": "text",
      "value": this.state.text,
      "onBlur": this.inputDidEnd,
      "ref": ((function(_this) {
        return function(r) {
          return _this.textInput = r;
        };
      })(this)),
      "onChange": this.textDidChange
    }) : React.createElement("div", {
      "onClick": this.didClick
    }, this.state.text)));
  },
  textDidChange: function() {
    console.log("changed, value=" + this.textInput.value);
    return this.setState({
      text: this.textInput.value
    });
  },
  didClick: function() {
    return this.setState({
      isEditing: true
    });
  },
  inputDidEnd: function() {
    this.props.didChange(this.props.path, this.textInput.value);
    return this.setState({
      isEditing: false
    });
  }
});

window.MongoReportParamsEditor = React.createClass({displayName: "MongoReportParamsEditor",
  render: function() {
    var displayKey, displayPath, key, path, sortedKeys, typeValueSeparatorIndex, value, valueStr, valueType;
    console.log("MongoReportParamsEditor rendering...", this.props);
    return React.createElement("div", null, ((function() {
      var j, len, results;
      sortedKeys = _.keys(this.props.parameters).sort((function(_this) {
        return function(k1, k2) {
          if (_.isString(_this.props.parameters[k1])) {
            if (_.isString(_this.props.parameters[k2])) {
              return _this.props.parameters[k1] - _this.props.parameters[k2];
            } else {
              return -1;
            }
          }
          if (_.isString(_this.props.parameters[k2])) {
            return 1;
          }
        };
      })(this));
      results = [];
      for (j = 0, len = sortedKeys.length; j < len; j++) {
        key = sortedKeys[j];
        value = this.props.parameters[key];
        path = this.props.path + "." + key;
        displayPath = this.props.path;
        displayKey = key;
        if (_.isString(value)) {
          typeValueSeparatorIndex = value.indexOf(":");
          valueType = value.substring(0, typeValueSeparatorIndex).trim();
          valueStr = value.substring(typeValueSeparatorIndex + 1);
          console.log("OK valueType " + valueType + ", valueStr " + valueStr);
          results.push(React.createElement("div", {
            "key": path
          }, React.createElement("div", null, React.createElement("span", null, displayPath), React.createElement("span", null, React.createElement("b", null, ".", displayKey)), React.createElement("span", null, " ", React.createElement("i", null, valueType))), React.createElement(JSEditor, {
            "path": path,
            "mode": "coffee",
            "value": valueStr,
            "type": valueType,
            "mode": "coffee",
            "didChange": this.props.didChange
          })));
        } else {
          results.push(React.createElement(MongoReportParamsEditor, {
            "key": path,
            "parameters": value,
            "path": path,
            "didChange": this.props.didChange
          }));
        }
      }
      return results;
    }).call(this)));
  }
});

window.TypeSelector = React.createClass({displayName: "TypeSelector",
  render: function() {
    return React.createElement("div", null, React.createElement("div", {
      "className": "btn-group query-options",
      "data-toggle": "buttons"
    }, this.props.types.sort().map((function(_this) {
      return function(t, i) {
        var checked, className;
        checked = t === _this.props.type;
        className = "btn btn-primary btn-xs";
        if (checked) {
          className += " active";
        }
        return React.createElement("label", {
          "key": i,
          "className": className,
          "onClick": _this.selectionDidChange
        }, React.createElement("input", {
          "type": "radio",
          "name": "type",
          "autoComplete": "off",
          "value": t,
          "checked": checked,
          "onChange": (function() {})
        }), React.createElement("span", null, " ", t, " "));
      };
    })(this))), React.createElement("div", null, ((function() {
      switch (this.props.type) {
        case "aggregate":
          React.createElement("a", {
            "href": "https://docs.mongodb.org/v3.0/meta/aggregation-quick-reference/",
            "target": "_blank"
          }, "Aggregation quick reference");
          return React.createElement("a", {
            "href": "https://docs.mongodb.org/v3.0/reference/operator/query/",
            "target": "_blank"
          }, "Aggregation query selectors \& operators");
        default:
          return React.createElement("div", null);
      }
    }).call(this))));
  },
  selectionDidChange: function(e) {
    var input;
    input = $("input", e.currentTarget)[0];
    input.checked = true;
    return this.props.didChange(this.props.path, input.value);
  }
});

window.ModeSelector = React.createClass({displayName: "ModeSelector",
  render: function() {
    var mode;
    return React.createElement("div", {
      "className": "run-options"
    }, React.createElement("div", {
      "className": "btn-group",
      "data-toggle": "buttons"
    }, (mode = this.props.report.mode, this.props.modes.sort().map((function(_this) {
      return function(t, i) {
        var checked, className;
        checked = t === mode;
        className = "btn btn-primary btn-xs";
        if (checked) {
          className += " active";
        }
        return React.createElement("label", {
          "key": i,
          "className": className,
          "onClick": _this.selectionDidChange
        }, React.createElement("input", {
          "type": "radio",
          "name": "mode",
          "autoComplete": "off",
          "value": t,
          "checked": checked,
          "onChange": (function() {})
        }), React.createElement("span", null, " ", t, " "));
      };
    })(this)))), React.createElement("div", {
      "className": "updateSampleButton btn-group",
      "onClick": this.didRequestSampleUpdate
    }, (this.props.report.mode === "manual" ? React.createElement("div", {
      "className": "btn btn-xs btn-danger"
    }, "\t\t\t\t\t\t\tUpdate sample result") : void 0)));
  },
  didRequestSampleUpdate: function(e) {
    e = $.Event("didRequestSampleUpdated", {
      reportId: this.props.report._id,
      updateSample: true
    });
    return $("body").trigger(e);
  },
  selectionDidChange: function(e) {
    var input;
    input = $("input", e.currentTarget)[0];
    input.checked = true;
    return this.props.didChange(this.props.path, input.value);
  }
});

window.MongoReportEditor = React.createClass({displayName: "MongoReportEditor",
  tagsDidChange: function(path, value) {
    var j, len, mustHave, ref, values;
    console.log("OK Changed " + path + ", " + value);
    values = value.split(" ").map(function(v) {
      return v.trim();
    });
    ref = [this.props.report.database, this.props.report.collection];
    for (j = 0, len = ref.length; j < len; j++) {
      mustHave = ref[j];
      if (indexOf.call(values, mustHave) < 0) {
        values.unshift(mustHave);
      }
    }
    this.setState({
      tags: values
    });
    return this.props.didChange("tags", values);
  },
  render: function() {
    var modes, tagsStr, types;
    console.log("MongoReportEditor rendering...", this.props);
    types = _.keys(this.props.report.parameters);
    modes = ["manual", "automatic"];
    tagsStr = this.props.report.tags.join(" ") || "no tags";
    console.log("parameters", types);
    console.log("modes ", modes);
    return React.createElement("div", null, React.createElement("div", null, React.createElement("h4", {
      "style": {
        display: "inline-block",
        marginBottom: "2px"
      }
    }, React.createElement(EditableDiv, {
      "initialText": this.props.report.name,
      "path": "name",
      "didChange": this.props.didChange
    })), React.createElement("div", {
      "style": {
        display: "inline-block",
        color: "#666",
        marginLeft: "15px"
      }
    }, React.createElement(EditableDiv, {
      "initialText": this.props.report.comment,
      "path": "comment",
      "didChange": this.props.didChange
    })), React.createElement("div", {
      "style": {
        display: "inline-block",
        color: "#666",
        fontFamily: "Heiti SC",
        marginLeft: "15px",
        fontSize: "11px",
        backgroundColor: "#F8F8F8"
      }
    }, React.createElement(EditableDiv, {
      "initialText": tagsStr,
      "path": "tags",
      "didChange": this.tagsDidChange
    }))), React.createElement("hr", null), React.createElement("div", {
      "className": "queryControls"
    }, React.createElement("div", null, React.createElement(TypeSelector, {
      "type": this.props.report.type,
      "types": types,
      "path": "type",
      "didChange": this.props.didChange
    })), React.createElement("div", {
      "style": {
        paddingLeft: "50px"
      }
    }, React.createElement(ModeSelector, {
      "report": this.props.report,
      "modes": modes,
      "path": "mode",
      "didChange": this.props.didChange
    }))), React.createElement("div", null, React.createElement(MongoReportParamsEditor, {
      "key": this.props.report.type,
      "parameters": this.props.report.parameters[this.props.report.type],
      "path": "parameters." + this.props.report.type,
      "didChange": this.props.didChange
    })));
  }
});

window.ReportEditor = React.createClass({displayName: "ReportEditor",
  mixins: [AjaxMixin],
  getInitialState: function() {
    return {};
  },
  componentDidMount: function() {
    var adjustHeight, previewPanelHeight;
    $("body").on("didSelect", (function(_this) {
      return function(e) {
        console.log("didSelect", e);
        if (e.report) {
          return _this.ajax("/report/" + e.report._id);
        }
      };
    })(this));
    previewPanelHeight = 0;
    adjustHeight = (function(_this) {
      return function() {
        return $("#editor").height(window.innerHeight - previewPanelHeight - 100);
      };
    })(this);
    $("body").on("previewPanelResized", (function(_this) {
      return function(e) {
        previewPanelHeight = e.height;
        return adjustHeight();
      };
    })(this));
    return $(window).on("resize", function() {
      return adjustHeight();
    });
  },
  render: function() {
    if (this.state.report) {
      return React.createElement(MongoReportEditor, {
        "key": this.state.report._id,
        "report": this.state.report,
        "ajax": this.ajax,
        "didChange": this.didChange,
        "ref": ((function(_this) {
          return function(r) {
            return _this.reportEditorWrapper = r;
          };
        })(this))
      });
    } else {
      return React.createElement("div", null, "Select a report from the menu");
    }
  },
  didChange: function(path, value) {
    var params;
    params = {
      url: "/report/" + this.state.report._id,
      method: "PUT",
      data: {
        $set: {}
      }
    };
    params.data["$set"][path] = value;
    return this.ajax(params, (function(_this) {
      return function(xhr, update) {
        var e;
        _this.setState(update);
        params = {
          reportId: _this.state.report._id,
          shouldUpdatePreview: _this.state.report.mode === "automatic",
          path: path
        };
        e = $.Event("didUpdateQuery", params);
        return $("body").trigger(e);
      };
    })(this));
  }
});
