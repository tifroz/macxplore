mcache            	= require "memory-cache"
#logger				= require 'logger'

cache = 
  
  hit: (req, res, next) ->
    key = '__express__' + req.originalUrl or req.url
    cachedBody = mcache.get(key)
    if cachedBody
      console.log("ok returning _cached value for #{key}")
      res.send cachedBody
      return
    else
      console.log("ok no _cached value for #{key}, will process")
      next()
    return
  
  store: (duration) ->
    (req, res, next) ->
      key = '__express__' + req.originalUrl or req.url
      cachedBody = mcache.get(key)
      if cachedBody
        #logger.debug "OK responding with cached entry from '#{key}'"
        res.send cachedBody
        return
      else
        res.sendResponse = res.send

        res.send = (body) ->
          #logger.debug "OK storing cached value for '#{key}'"
          mcache.put key, body, duration * 1000
          res.sendResponse body
          return
        #logger.debug "OK no cache entry for '#{key}', will process"
        next()
      return
  
  cache: (duration)->
    (req, res, next) ->
      key = '__express__' + req.originalUrl or req.url
      cachedBody = mcache.get(key)
      if cachedBody
        console.log("ok returning _cached value for #{key}")
        res.send cachedBody
        return
      else
        res.sendResponse = res.send
        res.send = (body) ->
          console.log "OK storing _cached value for '#{key}'"
          mcache.put key, body, duration * 1000
          res.sendResponse body
          return
        console.log("ok no _cached value for #{key}, will process\n\nsend=#{res.send}")
        next()
      return


module.exports = cache.cache