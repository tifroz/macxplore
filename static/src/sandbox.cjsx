HelloWorld = React.createClass
	render: ->
		<p>
			Hello, <input type="text" placeholder="Your name here" />!
			It is {this.props.date.toTimeString()}
		</p>

setInterval (-> ReactDOM.render(<HelloWorld date={new Date()} />, document.getElementById('example'))), 1000
