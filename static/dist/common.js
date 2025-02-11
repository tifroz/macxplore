// Generated by CoffeeScript 1.12.7
window.AjaxMixin = {
  ajax: function(params, fn) {
    var defaultParams, p;
    defaultParams = {
      cache: false,
      timeout: 0,
      complete: (function(_this) {
        return function(jqXHR, textStatus) {
          var boo, mimeType, parser, payload, update;
          parser = document.createElement('a');
          parser.href = params.url;
          update = {
            xhr: _this.state.xhr || {}
          };
          update.xhr[parser.pathname] = jqXHR;
          if (jqXHR.status >= 200 && jqXHR.status < 400) {
            mimeType = jqXHR.getResponseHeader("content-type").split(";")[0];
            switch (mimeType) {
              case "application/json":
                try {
                  payload = JSON.parse(jqXHR.responseText);
                  _.extend(update, payload);
                } catch (error) {
                  boo = error;
                  boo.message = boo.message + " (error with: " + parser.pathname + ")";
                  console.error(boo);
                }
                break;
              default:
                update[parser.pathname] = jqXHR.responseText;
            }
          }
          if (fn === void 0) {
            return _this.setState(update);
          } else {
            return fn(jqXHR, update);
          }
        };
      })(this)
    };
    if (_.isString(params)) {
      params = {
        url: params
      };
    }
    p = _.extend({}, defaultParams, params);
    return $.ajax(p);
  }
};

window.XHRError = React.createClass({displayName: "XHRError",
  getDefaultProps: function() {
    var defaults;
    return defaults = {
      xhr: null
    };
  },
  render: function() {
    var boo, createMarkup, json, mimeType, pathname, xhr;
    console.info("Rendering xhrError", this.props.xhr);
    if (this.props.xhr === void 0 || this.props.xhr === null) {
      return null;
    }
    return React.createElement("div", null, (function() {
      var ref, results;
      ref = this.props.xhr;
      results = [];
      for (pathname in ref) {
        xhr = ref[pathname];
        if (xhr.readyState < 4) {
          console.log("Network error");
          results.push(React.createElement("div", {
            "className": "error-wrapper",
            "key": pathname
          }, "Network Error, readyState is ", xhr.readyState, " (", pathname, ")"));
        } else if (xhr.status < 200 || xhr.status >= 400) {
          mimeType = xhr.getResponseHeader("content-type").split(";")[0];
          console.log("mimeType ", mimeType);
          switch (mimeType) {
            case "application/json":
              try {
                json = JSON.parse(xhr.responseText);
              } catch (error) {
                boo = error;
                json = {
                  message: boo.message,
                  stack: boo.stack
                };
              }
              if (json.message && json.stack) {
                console.log("json ", json);
                results.push(React.createElement("div", {
                  "className": "error-wrapper",
                  "key": pathname
                }, React.createElement("div", {
                  "className": "message"
                }, "HTTP Code ", xhr.status, ", ", json.message, " (", pathname, ")"), React.createElement("div", {
                  "className": "stack"
                }, json.stack.split("\n").map(function(line) {
                  return React.createElement("div", null, line);
                }))));
              } else {
                results.push(void 0);
              }
              break;
            default:
              console.log("markup");
              createMarkup = (function(_this) {
                return function() {
                  return {
                    __html: xhr.responseText
                  };
                };
              })(this);
              results.push(React.createElement("div", {
                "key": pathname
              }, React.createElement("div", null, "HTTP Code ", xhr.status, " (", pathname, ")"), React.createElement("div", {
                "dangerouslySetInnerHTML": createMarkup()
              })));
          }
        } else {
          results.push(void 0);
        }
      }
      return results;
    }).call(this));
  }
});
