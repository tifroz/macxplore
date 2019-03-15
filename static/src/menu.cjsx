window.ReportMenuItem = React.createClass
	render: ->
		<div className="menu-item">
			<div className="menu-item-header">
				<div>
					<a onClick={@selectItem}>
						{@props.report.name}
					</a>
				</div>
				<div className="dropdown">
					<a id="dLabel" data-target="#" href="#" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">
						<span> </span>
						<span className="caret"></span>
						<span> </span>
					</a>
					<ul className="dropdown-menu" aria-labelledby="dLabel">
						<li>
							<a onClick={@deleteItem}>delete</a>
						</li>
						<li>
							<a onClick={@duplicateItem}>duplicate</a>
						</li>
					</ul>
				</div>
			</div>
			<div className="menu-item-details">
				<div>
					<span>
						{@props.report.database}
					</span>
					<span>.</span>
					<span>
						{@props.report.collection}
					</span>
				</div>
			</div>
		</div>

	duplicateItem: (e)->
		e.preventDefault()
		params = 
			url: "/report/duplicate/#{@props.report._id}"
			method: "POST"
		@props.ajax params
	
	deleteItem: (e)->
		e.preventDefault()
		if confirm "#{@props.report.name} will be deleted permanently"
			params = 
				url: "/report/#{@props.report._id}"
				method: "DELETE"
			@props.ajax params

	selectItem: (e)->
		e.preventDefault()
		e = $.Event( "didSelect", report: @props.report )
		$("body").trigger e


window.ReportCreate = React.createClass
	render: ->
		<form onSubmit={@onSubmit}>
			<input type="text" placeholder="database" className="form-control" onChange={@dbnameDidChange}></input>
			<select className="form-control">
				{@props.collections.map (c, i)->(<option key={i} value={c}>{c}</option>)}
			</select>
			<button type="submit" disabled={(@props.collections.length == 0)} className="btn btn-primary btn-sm">Create</button>
		</form>

	getDefaultProps: ->
		props = 
			collections: []

	componentWillMount: ->
		@dbnameDidChangeDebounced = _.debounce(@dbnameDidChangeDebounced, 300)

	dbnameDidChange: (e)->
		@dbnameValue = e.target.value
		@dbnameDidChangeDebounced()

	dbnameDidChangeDebounced: ->
		@props.ajax url: "/#{@dbnameValue}/collections"

	onSubmit: (e)->
		e.preventDefault()
		params = 
			url: "/report"
			method: "POST"
			data:
				database: $("input",e.target).val()
				collection: $("select",e.target).val()
		@props.ajax params


window.ReportMenuList = React.createClass
	render: ->
		console.log "Ok rendering ReportMenuList with tag", @props.tag
		tag = @props.tag
		filtered = @props.reports.filter (r)=> (r.tags.includes(tag) or not tag)
		<nav>
			{filtered.map (r, i)=>(<ReportMenuItem key={r._id} report={r} ajax={@props.ajax} /> )}
		</nav>
	getDefaultProps: ->
		props = 
			tag: null
			reports: []
			ajax: (->)


window.TagItem = React.createClass
	render: ->
		<span className={if (@props.selected is @props.tag or (not @props.selected and not @props.tag))  then "selected" else ""}>
			<a onClick={@selectItem}>
				{@props.tag or "All"}
			</a>
		</span>
	
	getDefaultProps: ->
		props =
			tag: ""

	selectItem: (e)->
		e.preventDefault()
		console.log "Ok update state with ", tag: @props.tag
		@props.onTagChanged @props.tag or null

window.ReportTagList = React.createClass
	render: ->
		tags = _.chain(@props.reports).pluck("tags").flatten().compact().uniq().value().sort()
		<div id="tagList">
			<TagItem key="_all" tag="" selected={@props.tag} onTagChanged={@props.onTagChanged}/>
			{tags.map (t, i)=>(<TagItem key={t} tag={t} selected={@props.tag} onTagChanged={@props.onTagChanged}/> )}
		</div>
	getDefaultProps: ->
		props = 
			reports: []


window.Menu = React.createClass
	mixins: [AjaxMixin]
	getInitialState: ->
		state =
			collections: []
			reports: []
			tag: null
			xhr: null
	tagDidChange: (tag)->
		@setState tag: tag
	componentDidMount:->
		@ajax url: "/reports"
		$("body").on "didUpdateQuery", (e)=>
			console.log "on didUpdateQuery", e
			if e.path is "tags"
				@ajax url: "/reports"

	render: ->
		<div>
			<XHRError xhr={@state.xhr}/>
			<ReportCreate collections={@state.collections} ajax={@ajax}/>
			<ReportTagList reports={@state.reports}  ajax={@ajax} onTagChanged={@tagDidChange} tag={@state.tag}/>
			<ReportMenuList reports={@state.reports}  ajax={@ajax} tag={@state.tag}/>
		</div>
