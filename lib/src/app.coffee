modules	= require 'modules'



express				= require 'express'
MongoDoc			= require 'macmodel'
Seq 					= require 'seq'
_							= require 'underscore'

xpressLogger			= require 'morgan'
xpressBodyParser	= require 'body-parser'
xpressJade				= require 'pug'
xpressCompress		= require 'compression'
xpressStatic			= require 'serve-static'

logger						= console


app = express()
app.set('view engine', 'pug')
app.set('views', "#{__dirname}/../../views")
app.set('view options', { layout: true, pretty: true })


app
	.use(xpressCompress())
	.use('/assets',xpressStatic("#{__dirname}/../../static/dist"))
	.use(xpressLogger())
	.use(xpressBodyParser())

xplore = 
	setLogger: (l)->
		logger = l

	start: (mongoConfig, port, fn)->
		logger.log "Modules: #{_.keys(modules)}"
		handlers = require 'handlers'

		if mongoConfig.databases is undefined
			mongoConfig.databases = {}
		mongoConfig.databases.xplore =
			"report": []

		Seq().seq ->
			MongoDoc.db.initialize mongoConfig, logger, this
		.seq ->
			logger.log "MongoDoc.db.report #{MongoDoc.db.report}, #{MongoDoc.db.databases.xplore.report}"
			handlers.main(app)
			app.listen(port)
			logger.log "Xplore server listening on port #{port}"
			fn?(null)
		.catch (boo)->
			logger.error boo
			fn?(boo)


module.exports = xplore