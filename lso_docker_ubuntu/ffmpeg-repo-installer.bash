#!/bin/bash
echo "==========INSTALLING REPO FFMPEG==========="

if ! [ -x "$(command -v ffmpeg)" ]; then
	echo "INSTALLING FFMPEG"
	apt-get update -qq
	apt-get install -y ffmpeg
else
	echo "FFMPEG ALREADY INSTALLED"
fi

echo "=====REPO FFMPEG INSTALLATION COMPLETE====="
exit 0
