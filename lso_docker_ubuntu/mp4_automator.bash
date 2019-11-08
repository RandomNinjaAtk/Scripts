#!/bin/bash
echo "==========INSTALLING TOOLS==========="

if ! [ -x "$(command -v ffmpeg)" ]; then	
	echo "INSTALLING FFMPEG"
	apt-get update && \
	apt-get install -y \
		git \
		python-pip \
		openssl \
		python-dev \
		libffi-dev \
		libssl-dev \
		libxml2-dev \
		libxslt1-dev \
		mkvtoolnix \
		zlib1g-dev
		
	apt-get purge --auto-remove -y
	apt-get clean
	
	mkdir /tmp/ffmpeg
	curl -o /tmp/ffmpeg/ffmpeg-git-amd64-static.tar.xz https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz
	cd /tmp/ffmpeg
	tar xvf ffmpeg-git-amd64-static.tar.xz
	find "/usr/bin/" -type f -iname "ffmpeg" -exec rm {} \;
	find "/usr/bin/" -type f -iname "ffprobe" -exec rm {} \;
	find "/tmp/ffmpeg" -type f -iname "ffmpeg" -exec mv {} /usr/bin/ \;
	find "/tmp/ffmpeg" -type f -iname "ffprobe" -exec mv {} /usr/bin/ \;
	cd /
	rm -rf /tmp/ffmpeg
	
 	echo "INSTALLING PIP TOOLS"
	pip install --no-cache-dir -U \
		requests \
		requests[security] \
		requests-cache \
		babelfish \
		"guessit<2" \
		"subliminal<2" \
		stevedore==1.19.1 \
		python-dateutil \
		qtfaststart
		
	echo "DOWNLOAD SICKBEARD_MP4_AUTOMATOR"
	git clone git://github.com/mdhiggins/sickbeard_mp4_automator.git /config/scripts/sickbeard_mp4_automator/ && \
	touch /config/scripts/sickbeard_mp4_automator/info.log && \
	chmod a+rwx -R /config/scripts/sickbeard_mp4_automator && \

	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*
fi

echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
