cmd					 	= require 'commander'
logger					= console


cmd
	.option('-e, --environment [value]', 'local, test or production')
	.option('-l, --logfile [value]', 'path to the logfile, e.g. /var/log/apps/access.log')
	.parse(process.argv)

if cmd.logfile
	logger.addLogFile filename: cmd.logfile, level: "log" 



mongoConfig = 
	host: '127.0.0.1'
	port: 27017
	options:
		auto_reconnect: true
		poolSize: 2

app = require "./app"
app.setLogger logger

app.start mongoConfig, 4280
