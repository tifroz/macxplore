window.ReportMenuItem = React.createClass
	render: ->
		<div className="menu-item">
			<a onClick={@selectItem}>
				{@props.report.name}
			</a>
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
				<div class="dropdown">
					<button id="dLabel" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
						Action
						<span class="caret"></span>
					</button>
					<ul class="dropdown-menu" aria-labelledby="dLabel">
						<li>
							<a onClick={@deleteItem}>delete</a>
						</li>
						<li>
							<a onClick={@duplicateItem}>duplicate</a>
						</li>
					</ul>
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
		<nav>
			{@props.reports.map (r, i)=>(<ReportMenuItem key={r._id} report={r} ajax={@props.ajax} /> )}
		</nav>
	getDefaultProps: ->
		props = 
			reports: []
			ajax: (->)




window.Menu = React.createClass
	mixins: [AjaxMixin]
	getInitialState: ->
		state =
			collections: []
			reports: []
			xhr: null
	
	componentDidMount:->
		@ajax url: "/reports"

	render: ->
		<div>
			<XHRError xhr={@state.xhr}/>
			<ReportCreate collections={@state.collections} ajax={@ajax}/>
			<ReportMenuList reports={@state.reports}  ajax={@ajax}/>
		</div>
