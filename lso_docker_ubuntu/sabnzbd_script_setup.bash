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
	chroma \
	python-dev \
	python-pip && \
apt-get purge --auto-remove -y && \
apt-get clean

pip install --no-cache-dir -U \
	beets \
	pyacoustid
	
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
	mkdir /config/scripts/beets
fi


if [ -f /config/scripts/beets/config.xml ]; then
	rm /config/scripts/beets/config.xml
	sleep 1s
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
	sleep 1s
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
	sleep 1s
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
