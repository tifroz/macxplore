_							= require 'underscore'
MongoDoc			= require 'macmodel'
events				= require 'events'
Seq						= require 'seq'
coffee				= require 'coffeescript'
util					= require 'util'
streamify			= require "stream-array"
mr2FlatJson		= require("helpers").streams.mr2FlatJson

logger				= console



class Report extends MongoDoc
	init: ->
		#logger.info "OK initialized Report"

	getTargetedCollection: (fn)->
		if dbname = @_data.database and colname = @_data.collection
			if collection = MongoDoc.db.databases[dbname]?.collections[colname]
				fn?(null, collection)
		if @_data._id is undefined
			return fn?(new Error("Can't get collection without the report's _id"))

		dbname = null
		colname = null
		self = @
		Seq().seq ->
			logger.debug "getTargetedCollection will fillFromStorage"
			self.fillFromStorage this
		.seq (r)->
			logger.debug "getTargetedCollection will linkDatabaseIfExists"
			data = r.data()
			dbname = data.database
			colname = data.collection
			report = r
			MongoDoc.db.linkDatabaseIfExists dbname, this
		.seq ->
			logger.debug "getTargetedCollection will return collection"
			if collection = MongoDoc.db.databases[dbname]?.collections[colname]
				fn?(null, collection)
			else
				fn?(new Error("Database #{dbname} could not be linked for #{colname} (#{_.keys(MongoDoc.db.databases[dbname].collections)})"))
		.catch (boo)->
			fn?(boo)

	getParsedParameters: (qType)->
		if qType is undefined
			qType = "all"
		if @_parsedParameters is undefined
			@_parsedParameters = {}
		if @_parsedParameters[qType]
			return @_parsedParameters[qType]
		else if @_parsedParameters.all?[qType]
			return @_parsedParameters.all?[qType]
		else
			recursiveParse = (path, obj, result)->
				for key, value of obj
					if path is null
						p = key
					else
						p = "#{path}.#{key}"
					if _.isString value
						separatorIndex = value.indexOf(":")
						type = value.substring(0, separatorIndex)
						cscript = value.substring(separatorIndex+1).trim()
						if cscript.length > 0
							try
								jscript = coffee.compile cscript, bare: true
								logger.debug "#{p} jscript: #{jscript}"
								evaluated = undefined
								eval "evaluated = #{jscript}"
							catch err
								err.message = "Error compiling #{p}: #{err.message}"
								throw err
						
							if evaluated isnt undefined
								if evaluated isnt null
									switch type
										when 'function'
											unless _.isFunction evaluated
												throw new Error("Value for '#{p}' must evaluate to a function")
										when 'number'
											if isNaN evaluated
												throw new Error("Value for '#{p}' must evaluate to a number")
										when 'string'
											unless _.isString evaluated
												throw new Error("Value for '#{p}' must evaluate to a string")
								result[key] = evaluated
					else
						result[key] = {}
						recursiveParse("#{p}", value, result[key])

			@_parsedParameters = {}
			@_parsedParameters[qType] = {}
			if qType is "all"
				obj = @data().parameters
			else
				obj = @data().parameters[qType]
			if not obj
				throw new Error("No inputs for parameters of type '#{qType}'")
			recursiveParse(null, obj, @_parsedParameters[qType])

			return @_parsedParameters[qType]

	
	getSampleCursor: (fn)->
		self = @
		Seq().seq ->
			self.getTargetedCollection this
		.seq (c)->
			qType = self.data().type
			try
				params = self.getParsedParameters(qType)
			catch boo
				return fn?(boo)
			
			selector = {}
			options = {sort: {_id: -1}}
			switch qType
				when "find"
					selector = params.selector
					_.extend options, params.options
				when "aggregate"
					for cmd in params.pipeline
						if cmd.$match
							selector = cmd.$match
							break
				when "group"
					selector = params.condition
				when "count", "distinct"
					selector = params.query
				when "mapReduce"
					selector = params.options.query
				else
					return fn?(new Error("getCursor() can't be used with queries of type '#{qType}'"))
			if selector is undefined or selector is null
				selector = {}
			logger.debug util.format("SampleCursor with selector %j\nand options %j", selector, options)
			cursor = c.find(selector, options)
			fn?(null, cursor)
		.catch (boo)->
			fn?(boo)

	getCursor: (fn)->
		self = @
		Seq().seq ->
			self.getTargetedCollection this
		.seq (c)->
			qType = self.data().type
			try
				params = self.getParsedParameters(qType)
			catch boo
				return fn?(boo)
			
			switch qType
				when "find"
					cursor = c.find(params.selector, params.options)
					fn?(null, cursor)
				when "aggregate"
					cursor = c.aggregate(params.pipeline, {cursor: {batchSize:1}})
					fn?(null, cursor)
				else
					fn?(new Error("getCursor() can't be used with queries of type '#{qType}'"))
		.catch (boo)->
			fn?(boo)

	getStream: (fn)->
		self = @
		Seq().seq ->
			logger.debug util.format("Will get targeted collection")
			self.getTargetedCollection this
		.seq (c)->
			logger.debug util.format("OK have targeted collection")
			qType = self.data().type
			try
				params = self.getParsedParameters(qType)
			catch boo
				return fn?(boo)
			
			switch qType
				when "group"
					c.group params.keys, params.condition, params.initial, params.reduce, params.finalize, true, {}, (err, list)->
						if err
							fn?(err)
						else
							fn?(null, streamify(list))
				when "mapReduce"
					logger.debug util.format("mapReduce with map #{params.map}, reduce: #{params.reduce}, options keys: #{_.keys(params.options)}, options: %j", params.options)
					c.mapReduce params.map, params.reduce, params.options, (err, list)->
						if err
							fn?(err)
						else
							fn?(null, streamify(list).pipe(mr2FlatJson()))
					#c.mapReduce (->emit(this.locale,1)), (->return 1), {out: {inline: 1}}, fn
				when "distinct"
					c.distinct params.key, params.query, (err, list)->
						if err
							fn?(err)
						else
							makeKVJson = (key, value)->
								kv = {}
								kv[key] = value
								return kv
							json = (makeKVJson(params.key,v) for v in list)
							#logger.debug util.format("Distinct: %j", json)
							fn?(null, streamify(json))
				when "count"
					logger.debug util.format("count with query %j", params.query)
					c.count params.query, {}, (err, count)->
						if err
							fn?(err)
						else
							fn?(null, streamify([count: count]))
				else
					fn?(new Error("getReportData() can't be used with queries of type '#{qType}'"))
		.catch (boo)->
			fn?(boo)


Report.makeCopy = (original) ->
	og = original.data()
	data = 
		name: "#{og.name} copy"
	for attributeName in ["database", "collection", "comment", "type", "mode", "parameters"]
		data[attributeName] = og[attributeName]
	return new Report(data)

Report.makeDefaultReport = (dbname, colname) ->
	data = 
		name: "New #{colname}"
		database: dbname
		collection: colname
		comment: "(Enter comment here)"
		type: "find"
		mode: "manual"
		tags: [dbname, colname]
		parameters:
			find:
				selector: "object:{}"
				options:
					sort: "object:{}"
					fields: "object:{}"
			group:
				keys: "object:{_id:1}"
				condition: "object:{}"
				initial: "object:{\n\ttotal: 0\n\tcount: 0\n} # The initial aggregation object (result)"
				reduce: "function:(curr, result)->\n\t#result.total += curr.item.qty\n\t#result.count += 1\n"
				finalize: "function:(result)->\n\t#e.g compute and add an average count to the result\n\t#return result\n"
			mapReduce:
				map: "function:()->\n\t#emit(this.key, this.value)\n"
				reduce: "function:(key, values)->\n\treturn 1"
				options:
					query: "object:{}"
					sort: "object:{}"
					limit: "number:"
					out: "object:{inline: 1} # {replace:'collectionName'}, {merge:'collectionName'}, {reduce:'collectionName'}"
					finalize: "function:"
					scope: "object: {}"
			distinct:
				key: "string:\"_id\""
				query: "object:{}"
			count:
				query: "object:{}"
			aggregate:
				pipeline: "array:[]"

	return new Report(data)



_.extend Report, events.EventEmitter.prototype

Report.setLogger logger
Report.collectionName = "report"
MongoDoc.register(Report)


module.exports = Report
