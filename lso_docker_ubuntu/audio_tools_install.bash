#!/bin/bash
echo "==========INSTALLING TOOLS==========="
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
if ! [ -x "$(command -v mp3gain)" ]; then
	echo "START MP3GAIN INSTALLATION"
	apt-get update -qq
	apt-get install -y libmpg123-dev wget cmake autoconf automake build-essential
	echo "**** compile mp3gain ****" && \
	mkdir -p \
		/tmp/mp3gain-src && \
	wget -O /tmp/mp3gain-src/mp3gain.zip https://sourceforge.net/projects/mp3gain/files/mp3gain/1.6.1/mp3gain-1_6_1-src.zip && \
	cd /tmp/mp3gain-src && \
	unzip -qq /tmp/mp3gain-src/mp3gain.zip && \
	sed -i "s#/usr/local/bin#/usr/bin#g" /tmp/mp3gain-src/Makefile && \
	make && \
	make install && \
	echo "**** compile mp3val ****"
	cd /
	rm -rf /tmp/mp3gain-src
	apt-get purge --auto-remove -y
	apt-get clean
	echo "INSTALLATION SUCCESSFUL"
else
	echo "MP3GAIN ALREADY INSTALLED"
fi
echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
