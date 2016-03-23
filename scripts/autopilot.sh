#!/bin/sh

# Initial setup
source ./env.sh
SCRIPT_FILE_NAME=`basename "$0"`
echo "${SCRIPT_FILE_NAME} script executed from: ${PWD}"

# Start children processes
pids=""
sh ./autobuild.sh $$ &
pids="$pids $!"

sh ./autorun.sh $$ &
pids="$pids $!"

#echo "${SCRIPT_FILE_NAME} started children processes with pids ${pids}"
#trap 'echo Killing child scripts $pids; kill $pids;exit;' SIGINT SIGHUP SIGTERM SIGQUIT

# Keep alive as long as children processes are alive (or until Ctrl-c SIGINT)
#wait $pids

echo "Running child processes $pids from $$"

#trap 'echo $SCRIPT_FILE_NAME Killing child scripts $pids; kill $pids;exit;' SIGINT SIGHUP SIGTERM SIGQUIT

trap "echo Terminating ${SCRIPT_FILE_NAME}, killing children processes ${pids};trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

wait
echo "$SCRIPT_FILE_NAME exiting ${SCRIPT_FILE_NAME}"



#trap 'echo Autopilot Killing the scripts $pids; kill $pids; pkill -P $$ tail ;exit 0' SIGINT SIGHUP SIGTERM SIGQUIT TERM

#tail -n0 -F "$BUILDLOGFILE" | while read; do
#	echo Blah
#done


