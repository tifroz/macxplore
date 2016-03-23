#!/bin/sh


# Initial setup
source ./env.sh
SCRIPT_FILE_NAME=`basename "$0"`
echo "${SCRIPT_FILE_NAME} script executed from: ${PWD}"

# Start children processes
pids=""
nodemon --watch "$LOCAL_ROOT/lib/dist" "$LOCAL_ROOT/lib/dist/server.js" --environment local --logfile "$SERVERLOGFILE" &
pids="$pids $!"

echo "${SCRIPT_FILE_NAME} started children processes with pids ${pids}"

# Cleanup on exit
trap "echo Terminating ${SCRIPT_FILE_NAME}, killing children processes ${pids};trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

echo tail "$SERVERLOGFILE"

# Tail
tail -n0 -F "$SERVERLOGFILE" | while read; do
		echo "$REPLY"
    csmsg=$(echo "$REPLY" | egrep -i "error")
    #echo "$msg" 
    if [ -n "$csmsg" ]; then
			growlnotify -s -t "Server Error" --html -m "$csmsg"  --image "/Users/hugo/Library/Growl/PNG/Error.png"
    fi
done &

wait


