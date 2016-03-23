_							= require 'underscore'
Report				= require('models').Report
util					= require 'util'
Seq						= require 'seq'
logger				= require 'maclogger'
MongoDoc			= require 'macmodel'
json2Csv			= require("helpers").streams.json2Csv
truncate			= require("helpers").streams.truncate
cursor2JsonArray= require("helpers").streams.cursor2JsonArray


handleError = (res, boo)->
	res.setHeader "Content-Type", "application/json"
	res.send 500, util.format("%j", message: boo.message, stack: boo.stack)


main = (app)->


	app.get "/", (req, res)->
		res.render("main")

	
	app.get "/sandbox", (req, res)->
		res.render("sandbox")

	

	app.get "/preview", (req, res)->
		res.render("preview")
	
	

	app.get "/reports", sendReportList

	

	app.get "/report/:_id", sendReport



	app.get "/report/output/:_id/:name", (req, res)->
		report = new Report(_id: req.params._id)
		Seq().seq ->
			report.fillFromStorage this
		.seq ->
			reportType = report.data().type
			switch reportType
				when "find", "aggregate"
					report.getCursor this
				when "group", "distinct", "mapReduce", "count"
					report.getStream this
				else
					this(new Error("Report type '#{reportType}' not handled"))
		.seq (obj)->
			if _.isFunction obj.limit
				cursor = obj
				res.writeHead 200, "Content-Type": "text/csv"
				if req.params.name is "__sample.csv"
					cursor.limit(10).stream().pipe(json2Csv()).pipe(res)
				else
					cursor.stream().pipe(json2Csv()).pipe(res)
			else
				stream = obj
				res.writeHead 200, "Content-Type": "text/csv"
				if req.params.name is "__sample.csv"
					stream.pipe(truncate(10)).pipe(json2Csv()).pipe(res)
				else
					stream.pipe(json2Csv()).pipe(res)
		.catch (boo)->
			handleError res, boo

	
	###
	app.get "/report/recentdoc/:_id", (req, res)->
		dbname = null
		colname = null
		report = new Report(_id: req.params._id)
		Seq().seq ->
			report.getTargetedCollection this
		.seq (c)->
			c.findOne {}, {sort:{_id: -1}}, this
		.seq (doc)->
			res.setHeader "Content-Type", "application/json"
			res.send util.format("%j", doc: doc)
		.catch (boo)->
			handleError res, boo
	###

	

	app.get "/report/sampledoc/:_id", (req, res)->
		dbname = null
		colname = null
		report = new Report(_id: req.params._id)
		Seq().seq ->
			report.fillFromStorage this
		.seq ->
			report.getSampleCursor this
		.seq (cursor)->
			res.writeHead 200, "Content-Type": "application/json"
			cursor.limit(3).stream().pipe(cursor2JsonArray()).pipe(res)
	

	app.get "/:dbname/collections", (req, res)->
		dbname = req.params.dbname
		Seq().seq ->
			if MongoDoc.db.databases[dbname] is undefined
				MongoDoc.db.linkDatabaseIfExists dbname, this
			else
				this()
		.seq ->
			payload =
				collections: []
			if MongoDoc.db.databases[dbname] isnt undefined
				payload.collections = _.keys(MongoDoc.db.databases[dbname].getCollections())
			res.setHeader "Content-Type", "application/json"
			res.send util.format("%j", payload)
		.catch (boo)->
			handleError res, boo

	

	app.post "/report", (req, res)->
		logger.info "handling..."
		logger.log util.format("body: %j", req.body)
		Seq().seq ->
			r = Report.makeDefaultReport req.body.database, req.body.collection
			report  = new Report(r.data(), this)
		.seq ->
			sendReportList(req, res)
		.catch (boo)->
			handleError res, boo

	

	app.delete "/report/:_id", (req, res)->
		Seq().seq ->
			report  = new Report({_id: req.params._id})
			report.remove this
		.seq ->
			sendReportList(req, res)
		.catch (boo)->
			handleError res, boo

	

	app.put "/report/:_id", (req, res)->
		Seq().seq ->
			report  = new Report({_id: req.params._id})
			report.update req.body, this
		.seq ->
			sendReport(req, res)
		.catch (boo)->
			handleError res, boo
		

getReport = (_id, fn)->
		Seq().seq ->
			logger.log "fetching report #{_id}"
			Report.fetchOne {_id: _id}, this
		.seq (report)->
			logger.log "fetched report #{_id}"
			if report
				fn?(null, report)
			else
				fn?(new Error("No report found with id #{req.params._id}"))
		.catch (boo)->
			fn?(boo)


sendReport = (req, res)->
		Seq().seq ->
			logger.log "getting report"
			getReport req.params._id, this
		.seq (report)->
			logger.log "sending report"
			res.setHeader "Content-Type", "application/json"
			res.send util.format("%j", report: report.data())
		.catch (boo)->
			handleError res, boo

sendReportList = (req, res)->
		Seq().seq ->
			logger.info util.format("Report.resolveCollection: #{Report.resolveCollection()}")
			Report.fetch {}, {sort: {name: -1}, fields: ["_id", "name", "comments"]}, this
		.seq (reports)->
			logger.info "db\n#{_.keys(MongoDoc.db)}"
			payload =
				reports: (r.data() for r in reports)
			res.setHeader "Content-Type", "application/json"
			res.send util.format("%j", payload)
		.catch (boo)->
			handleError res, boo

module.exports = main