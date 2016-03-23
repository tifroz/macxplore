window.AjaxMixin =

	ajax: (params, fn) ->
		defaultParams =
			cache: false
			timeout: 20000
			complete: (jqXHR, textStatus)=>
				parser = document.createElement('a');
				parser.href = params.url

				update = xhr: @state.xhr or {}
				update.xhr[parser.pathname] = jqXHR

				if jqXHR.status >= 200 and jqXHR.status < 400
					mimeType = jqXHR.getResponseHeader("content-type").split(";")[0]
					switch mimeType
						when "application/json"
							try
								payload = JSON.parse jqXHR.responseText
								_.extend update, payload
							catch boo
								boo.message = "#{boo.message} (error with: #{parser.pathname})"
								console.error boo
						else
							update[parser.pathname] = jqXHR.responseText

				if fn is undefined
					@setState update
				else
					fn(jqXHR, update)


		if _.isString params
			params =
				url: params
		p = _.extend {}, defaultParams, params
		$.ajax p




window.XHRError = React.createClass
	getDefaultProps: ->
		defaults =
			xhr: null
	render: ->
		console.info "Rendering xhrError", @props.xhr
		if @props.xhr is undefined or @props.xhr is null
			return null

		<div>
			{
				for pathname, xhr of @props.xhr
					if xhr.readyState < 4
						console.log "Network error"
						<div className="error-wrapper" key={pathname}>Network Error, readyState is {xhr.readyState} ({pathname})</div>
					else if xhr.status < 200 or xhr.status >= 400
						mimeType = xhr.getResponseHeader("content-type").split(";")[0]
						console.log "mimeType ", mimeType
						switch mimeType
							when "application/json"
								try
									json = JSON.parse(xhr.responseText)
								catch boo
									json = message: boo.message, stack: boo.stack
								if json.message and json.stack
									console.log "json ", json
									<div className="error-wrapper" key={pathname}>
										<div className="message">HTTP Code {xhr.status}, {json.message} ({pathname})</div>
										<div className="stack">
											{
												json.stack.split("\n").map (line)->
													<div>{line}</div>
											}
										</div>
									</div>
							else
								console.log "markup"
								createMarkup = =>
									return __html: xhr.responseText
								<div key={pathname}> 
									<div>HTTP Code {xhr.status} ({pathname})</div>
									<div dangerouslySetInnerHTML={createMarkup()}/>
								</div>
					}
		</div>