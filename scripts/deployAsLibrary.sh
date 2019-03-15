#!/bin/sh
#

source ~/.profile
source ./env.sh


if [ $# -gt 0 ]; then
	REMOTE_HOST="$1"
else
	REMOTE_HOST="dev.swishly.com"
fi


echo ">> Copying source & config files" | growlnotify -s -t "$REMOTE_HOST deploy"
rsync -axSzv --copy-links --delete\
	--include="/package.json" \
	--include="/lib/" \
	--include="/static/" \
	--include="/views/" \
	--exclude=".*" \
	--exclude="/*" \
	"$LOCAL_ROOT/" "$REMOTE_HOST:~/.node_modules/macxplore"


echo ">> Installing npm modules" | growlnotify -s -t "$REMOTE_HOST deploy"
npmCmd="cd ~/.node_modules/macxplore; npm install"
ssh -t -t $REMOTE_HOST "$npmCmd"


#notifyMonitCmd="echo $TIMESTAMP > $REMOTE_ROOT/deploy_timestamp.txt"
#ssh -t -t $REMOTE_HOST "$notifyMonitCmd"

echo ">> Reached end of built script" | growlnotify -s -t "$REMOTE_HOST deploy"