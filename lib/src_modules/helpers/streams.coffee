through 	= require 'through'
_					= require 'underscore'
logger		= require 'maclogger'
util			= require 'util'



valueForKeyPath = (obj, keyPath)->
	kp = keyPath.split(".")
	value = obj
	for k in kp
		value = value[k]
		unless _.isObject value
			break

	logger.debug "valueForKeyPath, for #{keyPath}=#{value}"
	return value

csvEscape = (any)->
	if any is undefined or any is null
		return any
	else
		keyPath = any.toString().split(".")
		str = any.toString()
	if str.indexOf("\"") >= 0
		str.replace("\"", "\"\"")
	if str.indexOf(",") >= 0 or str.indexOf("\n") >= 0 or str.indexOf("\"") >= 0
		return "\"#{str}\""
	else
		return str 


cursor2JsonArray = ->
	first = true
	write = (data)->
		logger.debug util.format("cursor2JsonArray data: %j", data)
		if first
			first = false
			@queue( "[\n" )
		else
			@queue(",\n")
		@queue(util.format("%j", data))

	end = (data)->
		if first
			@queue "[]"
		else
			@queue "\n]"
		@queue null

	stream = through( write, end )
	return stream

# Will convert from {attr1: "value1", attr2: "value2", attr3: {sub1: "v1", sub2: "v2"}} to 
# 
# attr1,		attr2,		attr3.sub1,		attr3.sub2
# value1, 	value2, 	v1,						v2

jsonToCsv = ->
	first = true
	cols = []
	
	write = (data)->
		logger.debug util.format("jsonToCsv data: %j", data)
		if first
			first = false
			cols = _.keys data
			for index in [(cols.length-1)..0]
				key = cols[index]
				obj = data[key]
				logger.debug util.format("For key #{key}, isObject #{_.isObject(obj)}, %j", obj)
				if _.isObject obj# and not _.isFunction obj and not _.isArray obj
					logger.debug "For key #{key}, sub-Keys #{_.keys(obj)}"
					subKeys = ( "#{key}.#{subkey}" for subkey in _.keys(obj) )
					logger.debug "For key #{key}, subKeys #{subKeys}"
					cols.splice index, 1, subKeys
			cols = _.flatten cols
			logger.debug "json2Csv columns: #{cols}"
			@queue( cols.join(",")+"\n" )

		row = (csvEscape(valueForKeyPath(data, key)) for key in cols)
		@queue( row.join(",")+"\n" )
	
	end = (data)->
		logger.debug util.format("jsonToCsv done")
		@queue null

	stream = through( write, end )
	return stream


mr2FlatJson = ->
	first = true
	valueIsObject = false
	write = (data)->
		if first
			first = false
			valueIsObject = _.isObject data.value
		if valueIsObject
			result = _id: data._id
			_.extend result, data.value
			@queue result
		else
			@queue data
	end = (data)->
		@queue null

	stream = through( write, end )
	return stream




truncate = (max)->
	count = 0
	write = (data)->
		count++
		if count <= max
			@queue data
	end = (data)->
		@queue null

	stream = through( write, end )
	return stream

module.exports =
	json2Csv: jsonToCsv
	mr2FlatJson: mr2FlatJson
	cursor2JsonArray: cursor2JsonArray
	truncate: truncate
