#!/bin/bash
APP_NAME="Google Docs Uploader"

# Function definitions
openBrowser() {
	# arg1 = url to open
	if which xdg-open > /dev/null; then
		xdg-open "$1"
	elif which gnome-open > /dev/null; then
		gnome-open "$1"
	elif [ -n $BROWSER ]; then
		$BROWSER "$1"
	else
		showMessage "Could not detect the web browser to use.\nOpen manually: $1" --error
	fi
}

showMessage() {
	if [ -n $2 ]; then
		msg_icon="--info"
	else
		msg_icon=$2
	fi

	zenity \
		$msg_icon \
		--text="$1" \
		--title="$APP_NAME" \
		--ok-label="OK"
		--window-icon="$curDir/icons/doc.svg"
}

# Checking dependencies
which curl 2>/dev/null 1>/dev/null
if [ $? != 0 ]; then
	showMessage "curl is not available!" --error
	exit 100
fi

which jq 2>/dev/null 1>/dev/null
if [ $? != 0 ]; then
	showMessage "jq is not available!" -error
	exit 100
fi

# App Start
curDir=`dirname "$(readlink -f "$0")"`
if [ "$1" = "" ]; then
	showMessage "You have to specify file to open!" --warning
	exit 2
fi

source $curDir/config

uploadFilePath=$1

if [ "$uploadFilePath" = "" ]; then
	showMessage "File is not specified!" --warning
	exit 2
fi

if [ ! -f $uploadFilePath ]; then
    showMessage "File not found!" --error
    exit 2
fi

echo "Uploading file '$uploadFilePath'..."
echo "Server: $UPLOAD_URL"

notify-send -u normal -t 2000 -a gdocsupload -i "$curDir/icons/doc.svg" "Google Docs Uploader" "Uploading file '$uploadFilePath'..."

uploadRes=`curl -sS \
	-F "_key=$UPLOAD_KEY" \
	-F "file=@$uploadFilePath" \
	--connect-timeout 5 \
	--retry 2 \
	--max-time 10 \
	$UPLOAD_URL
`

if [ $? != 0 ]; then
	showMessage "Upload failed!\n$uploadRes" --error
	exit 3
fi

resultUrl=`echo $uploadRes | jq -r .url`

if [ $? != 0 ]; then
	showMessage "Upload result parsing failed!\n$uploadRes" --error
	exit 3
fi

openBrowser "$resultUrl"
