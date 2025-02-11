window.CSVHead  = React.createClass
	render: ->
		console.log "Rendering head with ", @props
		<thead>
		{
			cols = @props.data
			<tr>
				{cols.map (v, i)-> <th key={i}>{v}</th>}
			</tr>
		}
		</thead>

window.CSVBody = React.createClass
	render: ->
		console.log "Rendering body with ", @props
		<tbody>
		{
			@props.data.map (r, i)->
				<CSVRow key={i} data={r}/>
		}
		</tbody>

window.CSVRow = React.createClass
	render: ->
		#cols = @props.data.split(",")
		#cols = xplore.util.CSVToArray(@props.data, ",")
		cols = @props.data
		<tr>
			{cols.map (v, i)-> <td key={i}>{v}</td>}
		</tr>


window.CSVTable = React.createClass
	render: ->
		console.log "Rendering table with ", @props
		if @props.csv
			#rows = @props.csv.split("\n")
			rows = xplore.util.csv2Array(@props.csv, ",")
			if rows.length > 0
				head = rows.shift()
				<table className="table-striped table-condensed table-responsive">
					<CSVHead key="head" data={head}/>
					<CSVBody key="body" data={rows}/>
				</table>
		else
			return null

window.JsonViewer = React.createClass
	componentDidMount:->
		window.IsCollapsible  = true
		window.TAB = window.SINGLE_TAB
		console.log "@props.doc", @props.doc
		html = ProcessObject(@props.doc, 0, false, false, false);
		$id("Canvas").innerHTML = "<PRE class='CodeContainer'>"+html+"</PRE>";
	shouldComponentUpdate: ->
		return true
	componentDidUpdate: ->
		html = ProcessObject(@props.doc, 0, false, false, false);
		$id("Canvas").innerHTML = "<PRE class='CodeContainer'>"+html+"</PRE>";
	render: ->
		<div id="Canvas"></div>





window.PreviewSelector = React.createClass
	render: ->
		<div className="btn-group" data-toggle="buttons">
			{
				@props.types.sort().map (t, i)=>
					checked = t is @props.type
					className = "btn btn-primary btn-xs"
					if checked
						className += " active"
					<label key={i} className={className}  onClick={@selectionDidChange}>
						<input type="radio" name="type" autoComplete="off" value={t} checked={checked} onChange={(->)}/>
						<span> {t} </span>
					</label>
			}
		</div>

	selectionDidChange: (e)->
		input = $("input", e.currentTarget)[0]
		input.checked = true
		@props.didChange @props.path, input.value



window.ReportPreview = React.createClass
	mixins: [AjaxMixin]
	getInitialState: ->
		state =
			waiting: []
			type: "sample doc"
			tags: []
			doc: null
			csv: null
			xhr: null
			reportId: null
			reportName: null

	componentDidMount:->
		$("body").on "didSelect", (e)=>
			console.log "didSelect", e
			@setState reportId: e.report._id
			@setState reportName: e.report.name
			if e.report.mode is "automatic"
				@fetch e.report._id
			else
				@fetchSampleDoc e.report._id
			
		$("body").on "didUpdateQuery", (e)=>
			console.log "on didUpdateQuery", e
			if e.shouldUpdatePreview
				@fetch e.reportId
			else
				@fetchSampleDoc e.reportId

		$("body").on "didRequestSampleUpdated", (e)=>
			console.log "on didRequestSampleUpdated", e
			if e.updateSample
				if @state.waiting.length > 0
					alert "A query for sampled results is already in progress"
				else
					@fetch e.reportId
		
		$("body").on "didUpdateMaxDocs", (e)=>
			console.log "on didUpdateMaxDocs", e
			if e.maxDocs
				@setState maxDocs: e.maxDocs

		@sizeMonitor = setInterval @monitorSize, 500

	componentWillUnmount: ->
		clearInterval @sizeMonitor

	
	render: ->
		<div>
			<XHRError xhr={@state.xhr}/>
			{
				if @state.doc or @state.csv
					activityClasses = "activity"
					if @state.waiting.length > 0
						console.log "Waiting for #{@state.waiting}"
						activityClasses += " on"
					<div>
						<PreviewSelector types={["sample doc", "sample result"]} path="type" type={@state.type} didChange={@didChange}/>
						<div className="ouputLinks">
							<a href={"/report/output/"+@state.reportId+"/"+@state.reportName+".csv"} target="_blank">csv file</a>
						</div>
						<div className={activityClasses}>
							<img src="https://swishly.nyc3.cdn.digitaloceanspaces.com/static/assets/webtv/app/gif-load.gif"/>
						</div>
						{
							if @state.type is "sample doc"
								<JsonViewer doc={@state.doc}/>
							else if @state.type is "sample result"
								<CSVTable csv={@state.csv}/>
						}
					</div>
				else
					<div></div>
			}
		</div>

	didChange: (path, value)->
		console.log "ok Changed #{path}, #{value}"
		@setState type: value

	monitorSize: ->
		if (h = $("#preview").height()) isnt @height
			@height = h
			e = $.Event( "previewPanelResized", height: h )
			$("body").trigger(e)

	fetch: (reportId)->
		@fetchSampleDoc reportId
		@fetchSampleOutput reportId


	fetchSampleDoc: (reportId)->
		console.log "on fetchSampleDoc", @state
		limit = @state.maxDocs || 10
		path = "/report/sampledoc/#{reportId}?limit=#{limit}"
		@ajax path, (xhr, update)=>
			@doneWithFetch path
			if xhr.status > 0 and xhr.status < 400
				console.log "xhr.responseText", doc: JSON.parse(xhr.responseText)
				@setState doc: JSON.parse(xhr.responseText), xhr: "#{path}": xhr
			else
				@setState xhr: "#{path}": xhr	
		@waitingForFetch [path]

	fetchSampleOutput: (reportId)->
		path = "/report/output/#{reportId}/__sample.csv"
		@ajax path, (xhr, update)=>
			@doneWithFetch path
			if xhr.status > 0 and xhr.status < 400
				@setState csv: xhr.responseText, xhr: "#{path}": xhr
			else
				@setState xhr: "#{path}": xhr 
		@waitingForFetch [path]

	waitingForFetch: (paths)->
		waiting = @state.waiting
		waiting = waiting.concat paths
		@setState waiting: waiting

	doneWithFetch: (path)->
		waiting = @state.waiting
		waiting = _.without waiting, path
		@setState waiting: waiting




