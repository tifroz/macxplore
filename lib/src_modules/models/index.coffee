###*
*	Scans the local directory for module js files and extends the exports object with the corresponding modules
###
_ = require('underscore')
modules = require('modules').scan(__dirname)

for m in modules
	moduleName = m.split('/').pop()
	module.exports[moduleName]= require(m)