#!/bin/bash
echo "==========INSTALLING AUDIO TOOLS==========="
if ! [ -x "$(command -v mp3val)" ]; then	
	echo "START MP3VAL INSTALLTION"
	apt-get update -qq
	if { apt-get install -y -qq mp3val; }; then
		apt-get purge --auto-remove -y
		apt-get clean
		echo "INSTALLATION SUCCESSFUL"
	else
		echo "ERROR: INSTALLTION UNSUCCESSFUL"
	fi
else
	echo "MP3VAL ALREADY INSTALLED"
fi
if ! [ -x "$(command -v flac)" ]; then	
	echo "START FLAC INSTALLTION"
	apt-get update -qq
	if { apt-get install -y -qq flac; }; then
		apt-get purge --auto-remove -y
		apt-get clean
		echo "INSTALLATION SUCCESSFUL"
	else
		echo "ERROR: INSTALLTION UNSUCCESSFUL"
	fi
else
	echo "FLAC ALREADY INSTALLED"
fi
if ! [ -x "$(command -v ffmpeg)" ]; then	
	echo "START FFMPEG INSTALLTION"
	apt-get update -qq
	if { apt-get install -y -qq ffmpeg; }; then
		apt-get purge --auto-remove -y
		apt-get clean
		echo "INSTALLATION SUCCESSFUL"
	else
		echo "ERROR: INSTALLTION UNSUCCESSFUL"
	fi
else
	echo "FFMPEG ALREADY INSTALLED"
fi
echo "=====AUDIO TOOLS INSTALLATION COMPLETE====="
exit 0
