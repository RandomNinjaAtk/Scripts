#!/bin/bash
echo "==========INSTALLING TOOLS==========="
if ! [ -x "$(command -v ffmpeg)" ]; then	
	echo "INSTALLING FFMPEG"
	apt-get update -qq && \
	apt-get install -y ffmpeg && \		
	apt-get purge --auto-remove -y && \
	apt-get clean
else
	echo "FFMPEG ALREADY INSTALLED"
fi
echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
