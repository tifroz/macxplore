window.JSEditor = React.createClass

	adjustRowHeight: ->
		lines = @editor.getSession().getScreenLength()
		@editor.setOptions maxLines: lines
		$(@aceEditorWrapper).attr("style", "height: "+(lines*1.2+1)+"em")
		console.log "OK getScreenLength=#{lines}"
	
	contentDidChange:->
		@adjustRowHeight()
		@contentDidChangeDebounced()

	contentDidChangeDebounced:->
		if @editor.getSession().getAnnotations().length is 0
			@props.didChange @props.path, "#{@props.type}:#{@editor.getValue()}"
		else
			console.log "Editor in error (no changes)"
	
	componentDidUpdate: ->
		@configureAceEditor()

	shouldComponentUpdate: ->
		return false

	componentDidMount:->
		@configureAceEditor()
		@contentDidChangeDebounced = _.debounce(@contentDidChangeDebounced, 1500)
		@adjustRowHeight()
	
	componentWillUnmount: ->
	
	render: ->
		<div className="editor-wrapper">
			<div className="ace-editor-wrapper" ref={(r)=>@aceEditorWrapper=r}>
				<div className="ace-editor" id={@props.path}>{@props.value}</div>
			</div>
		</div>

	configureAceEditor: ->
		console.log "OK configureAceEditor for #{@props.path}"
		@editor = ace.edit(@props.path)
		@editor.setTheme("ace/theme/monokai")
		@editor.getSession().setMode("ace/mode/"+@props.mode)
		@editor.on "change", @contentDidChange
		@editor.session.setOptions tabSize: 2, useSoftTabs: true, showInvisibles: true



window.EditableDiv = React.createClass
	getInitialState: ->
		state = 
			isEditing: false
			text: @props.initialText
	#componentWillReceiveProps:->
	#	@setState text: @props.initialText
	render: ->
		console.log "EditableDiv rendering...", @props, @state
		<div className="editableDiv">
		{
			if @state.isEditing
				<input type="text" value={@state.text} onBlur={@inputDidEnd} ref={(r)=>@textInput=r} onChange={@textDidChange}/>
			else
				<div onClick={@didClick}>{@state.text}</div>
		}
		</div>

	textDidChange:->
		console.log "changed, value=#{@textInput.value}"
		@setState text: @textInput.value

	didClick:->
		@setState isEditing: true
	
	inputDidEnd:->
		@props.didChange @props.path, @textInput.value
		@setState isEditing: false

		

window.MongoReportParamsEditor = React.createClass
	render: ->
		console.log "MongoReportParamsEditor rendering...", @props
		<div>
			{
				sortedKeys = _.keys(@props.parameters).sort (k1, k2)=>
					if _.isString @props.parameters[k1]
						if _.isString @props.parameters[k2]
							return @props.parameters[k1] - @props.parameters[k2]
						else
							return -1
					if _.isString @props.parameters[k2]
						return 1

				for key in sortedKeys
					value = @props.parameters[key]
					path = "#{@props.path}.#{key}"
					displayPath = @props.path
					displayKey = key
					if _.isString value
						typeValueSeparatorIndex = value.indexOf(":")
						valueType = value.substring(0, typeValueSeparatorIndex).trim()
						valueStr = value.substring(typeValueSeparatorIndex+1)
						console.log "OK valueType #{valueType}, valueStr #{valueStr}"
						<div key={path}>
							<div><span>{displayPath}</span><span><b>.{displayKey}</b></span><span> <i>{valueType}</i></span></div>
							<JSEditor path={path} mode="coffee" value={valueStr} type={valueType} mode="coffee" didChange={@props.didChange}/>
						</div>
					else
						<MongoReportParamsEditor key={path} parameters={value} path={path} didChange={@props.didChange}/>
			}
		</div>

window.TypeSelector = React.createClass
	render: ->
		<div>
			<div className="btn-group query-options" data-toggle="buttons">
				{

					@props.types.sort().map (t, i)=>
						checked = t is @props.type
						className = "btn btn-primary btn-xs"
						if checked
							className += " active"
						<label key={i} className={className} onClick={@selectionDidChange}>
							<input type="radio" name="type" autoComplete="off" value={t} checked={checked} onChange={(->)}/>
							<span> {t} </span>
						</label>

				}
			</div>
			<div>
				{
					switch @props.type
						when "aggregate"
							<a href="https://docs.mongodb.org/v4.0/meta/aggregation-quick-reference/" target="_blank"> Aggregation quick reference</a>
							<a href="https://docs.mongodb.org/v4.0/reference/operator/query/" target="_blank"> Aggregation query selectors &amp; operators</a>
						else
							<div></div>
				}
			</div>
		</div>

	selectionDidChange: (e)->
		input = $("input", e.currentTarget)[0]
		input.checked = true
		@props.didChange @props.path, input.value


window.ModeSelector = React.createClass
	render: ->
		<div className="run-options" style={{display: 'flex', alignItems: 'center', gap: '10px'}}>
			<div>
				{
					<label style={{marginRight: '10px'}}>
						max docs
						<input id="maxDocs" type="number" defaultValue="10" min="1" max="300" style={{marginLeft: '5px', width: '60px'}} onChange={@maxDocsDidChange} ref="maxDocs"/>
					</label>
				}
			</div>
			<div className="updateSampleButton btn-group">
				{
					if @props.report.mode is "manual"
						<div className="btn btn-xs btn-danger" onClick={@didRequestSampleUpdate}>
							Update sample result
						</div>
				}
			</div>
		</div>

	didRequestSampleUpdate: (e)->
		e = $.Event( "didRequestSampleUpdated", {reportId: @props.report._id, updateSample: true} )
		$("body").trigger e
	
	maxDocsDidChange: (e)->
		maxDocs = parseInt($(@refs.maxDocs).val(), 10)
		e = $.Event( "didUpdateMaxDocs", {reportId: @props.report._id, maxDocs: maxDocs} )
		$("body").trigger e


window.MongoReportEditor = React.createClass
	tagsDidChange: (path, value)->
		console.log "OK Changed #{path}, #{value}"
		values = value.split(" ").map( (v)->v.trim() )
		for mustHave in [@props.report.database, @props.report.collection]
			if mustHave not in values
				values.unshift mustHave
		@setState tags: values
		@props.didChange "tags", values
	
	render: ->
		console.log "MongoReportEditor rendering...", @props
		types = _.keys @props.report.parameters
		tagsStr = @props.report.tags.join(" ") or "no tags"
		console.log "parameters", types
		
		<div>
			<div>
				<h4 style={{display: "inline-block", marginBottom: "2px"}}>
					<EditableDiv initialText={@props.report.name} path="name" didChange={@props.didChange}/>
				</h4>
				<div style={{display: "inline-block", color: "#666", marginLeft: "15px"}}>
					<EditableDiv initialText={@props.report.comment}  path="comment" didChange={@props.didChange}/>
				</div>
				<div style={{display: "inline-block", color: "#666", fontFamily: "Heiti SC", marginLeft: "15px", fontSize: "11px", backgroundColor: "#F8F8F8"}}>
					<EditableDiv initialText={tagsStr} path="tags" didChange={@tagsDidChange}/>
				</div>
			</div>
			<hr/>
			<div className="queryControls">
				<div>
					<TypeSelector type={@props.report.type} types={types} path="type" didChange={@props.didChange}/>
				</div>
				<div style={{paddingLeft: "50px"}}>
					<ModeSelector report={@props.report} path="mode" didChange={@props.didChange}/>
				</div>
			</div>
			<div>
				<MongoReportParamsEditor key={@props.report.type} parameters={@props.report.parameters[@props.report.type]} path={"parameters.#{@props.report.type}"} didChange={@props.didChange}/>
			</div>
		</div>



window.ReportEditor = React.createClass
	mixins: [AjaxMixin]
	getInitialState: ->
		return {}
	componentDidMount:->
		$("body").on "didSelect", (e)=>
			console.log "didSelect", e
			if e.report
				@ajax "/report/#{e.report._id}"
		previewPanelHeight = 0
		adjustHeight = =>
			$("#editor").height(window.innerHeight - previewPanelHeight - 100)
		$("body").on "previewPanelResized", (e)=>
			previewPanelHeight = e.height
			adjustHeight()
		$(window).on "resize", ->
			adjustHeight()
	render: ->
		if @state.report
			<MongoReportEditor key={@state.report._id} report={@state.report} ajax={@ajax} didChange={@didChange} ref={(r)=>@reportEditorWrapper=r}/>
		else
			<div>Select a report from the menu</div>

	didChange: (path, value)->
		params = 
			url: "/report/#{@state.report._id}"
			method: "PUT"
			data: 
				$set: {}
		params.data["$set"][path] = value

		@ajax params, (xhr, update)=>
			@setState update
			params = 
				reportId: @state.report._id,
				shouldUpdatePreview: @state.report.mode is "automatic"
				path: path
			e = $.Event( "didUpdateQuery", params )
			$("body").trigger e

