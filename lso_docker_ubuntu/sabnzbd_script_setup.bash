#!/bin/bash

echo "INSTALLING REQUIREMENTS"
apt-get update -qq && \
apt-get install -qq -y \
	mkvtoolnix \
	mp3val \
	flac \
	wget \
	nano \
	unzip \
	jq && \
apt-get purge --auto-remove -y && \
apt-get clean

if [ ! -f "/usr/local/bin/beet" ]; then
	apt-get update -qq && \
	apt-get install -qq -y \
		libchromaprint-tools \
		python3-pip && \
	apt-get purge --auto-remove -y && \
	apt-get clean

	pip3 install --no-cache-dir -U \
		beets \
		pyacoustid
else
	echo "BEETS ALREADY INSTALLED"
fi

if [ ! -f "/usr/local/bin/opusenc" ]; then 
	apt-get update -qq && \
	apt-get install -qq -y \
		autoconf \
		automake \
		libtool \
		gcc \
		make \
		pkg-config \
		openssl \
		libssl-dev && \
	apt-get purge --auto-remove -y && \
	apt-get clean

	set -e 
	set -o pipefail

	# Install packages needed

	apt update > /dev/null 2>&1 && apt install -y curl libflac-dev > /dev/null 2>&1

	# Remove packages that can cause issues

	apt -y purge opus* > /dev/null 2>&1 && apt -y purge libopus-dev > /dev/null 2>&1

	# Download necessary files

	TEMP_FOLDER="$(mktemp -d)"

	# Opusfile 0.11
	curl -Ls https://downloads.xiph.org/releases/opus/opusfile-0.11.tar.gz | tar xz -C "$TEMP_FOLDER"

	# Opus 1.3.1
	curl -Ls https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz | tar xz -C "$TEMP_FOLDER"

	# Libopusenc 0.2.1
	curl -Ls https://archive.mozilla.org/pub/opus/libopusenc-0.2.1.tar.gz | tar xz -C "$TEMP_FOLDER"

	# Opus Tools 0.2
	curl -Ls https://archive.mozilla.org/pub/opus/opus-tools-0.2.tar.gz | tar xz -C "$TEMP_FOLDER"

	# Compile

	cd "$TEMP_FOLDER"/opus-1.3.1 || exit

	./configure
	make && make install

	cd "$TEMP_FOLDER"/opusfile-0.11 || exit

	./configure
	make && make install

	cd "$TEMP_FOLDER"/libopusenc-0.2.1 || exit

	./configure
	make && make install

	cd "$TEMP_FOLDER"/opus-tools-0.2 || exit
	./configure
	make
	make install
	ldconfig

	# Cleanup

	rm -rf "$TEMP_FOLDER"

	cd /
else
	echo "OPUSENC ALREADY INSTALLED"
fi

if ! [ -x "$(command -v ffmpeg)" ]; then
	echo "INSTALLING FFMPEG"
	apt-get update -qq && \
	apt-get install -y xz-utils
	
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
else
	echo "FFMPEG ALREADY INSTALLED"
fi

if [ ! -d /config/scripts ]; then
	echo "setting up script directory"
	mkdir /config/scripts
	# Set Permissions
	echo "setting permissions..."
	chmod 0777 -R /config/scripts
	echo "done"
fi

if [ ! -d /config/scripts/beets ]; then
	mkdir -p /config/scripts/beets
fi

if [ ! -f /config/scripts/beets/config.xml ]; then
	echo "downloading config.yaml from: https://github.com/RandomNinjaAtk/Scripts/blob/master/config/config.yaml"
	curl -o /config/scripts/beets/config.yaml https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/config/config.yaml
	echo "done"
	chmod 0666 /config/scripts/beets/config.yaml
fi

# Download Scripts
echo "downloading scripts..."
if [ -f /config/scripts/video-processing.bash ]; then
	rm /config/scripts/video-processing.bash
	sleep 0.1
fi
if [ ! -f /config/scripts/video-processing.bash ]; then
  echo "downloading video-processing.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/sabnzbd/video-processing.bash"
  curl -o /config/scripts/video-processing.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/video-processing.bash
  echo "done"

  # Set Permissions
  echo "setting permissions..."
  chmod 777 /config/scripts/video-processing.bash
  echo "done"
fi

if [ -f /config/scripts/AudioPostProcessing.bash ]; then
	rm /config/scripts/AudioPostProcessing.bash
	sleep 0.1
fi
if [ ! -f /config/scripts/AudioPostProcessing.bash ]; then
  echo "downloading AudioPostProcessing.bash from: https://github.com/RandomNinjaAtk/Scripts/tree/master/sabnzbd/AudioPostProcessing.bash"
  curl -o /config/scripts/AudioPostProcessing.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/AudioPostProcessing.bash
  echo "done"

  # Set Permissions
  echo "setting permissions..."
  chmod 777 /config/scripts/AudioPostProcessing.bash
  echo "done"
fi
echo "script downloads complete..."
exit 0
