#!/bin/bash
echo "==========INSTALLING TOOLS==========="

# global environment settings
ENV DEBIAN_FRONTEND="noninteractive"

apt-get update && \
	apt-get install -y \
		ffmpeg \
		git \
		python-pip \
		openssl \
		python-dev \
		libffi-dev \
		libssl-dev \
		libxml2-dev \
		libxslt1-dev \
		zlib1g-dev
  
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

git clone git://github.com/mdhiggins/sickbeard_mp4_automator.git /config/scripts/sickbeard_mp4_automator/ && \
touch /config/scripts/sickbeard_mp4_automator/info.log && \
chmod a+rwx -R /config/scripts/sickbeard_mp4_automator && \

rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

exit 0
