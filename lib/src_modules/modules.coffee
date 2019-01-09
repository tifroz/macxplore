###*
* Modules dependencies
###
fs = require('fs'); _ = require('underscore'); path = require('path')

jsInclude=/(^[^\.].*)\.js/; jsExclude=/index.js|.*skip.js/ ; dirInclude=/^[^\.].*/; dirExclude=/\..*/

				
module.exports =
	###*
	* Recursively scans the directory for module files & module directories
	* @param {String} directory path
	* @param {Hash} {include: []} - include non-module files as buffers (e.g ['csv'] to include csv files)
	* @returns {Array} require-ready strings, eg ['./thismodule', './thatmoduledir']
	* The returned array is sorted consistently with module loading orders, aka:
	* 	- modules in directories closer to the root take precedence (loaded before subdirectories)
	*		- within the same directory modules are loaded in alphabetical order
	###
	scan: (dirname, options) ->
		ls = fs.readdirSync(dirname)

		# Load files first
		# Sort in ascending order (filename), files first, directories last
		ls = ls.sort (path1, path2)->
			isFilePath1 = fs.statSync(path.join(dirname,path1)).isFile()
			isFilePath2 = fs.statSync(path.join(dirname,path2)).isFile()
			if isFilePath1 and not isFilePath2
				return -1
			else if isFilePath2 and not isFilePath1
				return 1
			else if path1 < path2
				return -1
			else
				return 1 

		#Filters out non-module files and map the result to require-ready strings
		modules = _(ls)	.chain()
			.filter (name)->
				absoluteRef = path.join(dirname,name)
				isFile = fs.statSync(absoluteRef).isFile()
				isModuleFile = isFile and (name.match(jsInclude) and !name.match(jsExclude))
				isDataFile = false
				if options?.include?.length
					isDataFile = isFile and not isModuleFile and name.split('.').pop() in options.include
				isDir = (fs.statSync(absoluteRef).isDirectory() and name.match(dirInclude) and !name.match(dirExclude))
				isModuleDir = isDir and (_(fs.readdirSync(absoluteRef)).indexOf('index.js') >-1)
				include = isModuleFile or isDataFile or isModuleDir
				#console.log("module scan: #{name} #{if include then 'added' else 'excluded'}")
				return include
			.map (name) ->
				if (name.match(jsInclude))
					path.join(dirname,jsInclude.exec(name)[1])
				else 
					path.join(dirname,name)
			.value()