#!/bin/bash
echo "==========lidarr-automated-downloader setup==========="


if ! [ -x "$(command -v flac)" ]; then
	echo "INSTALLING REQUIREMENTS"
	curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
	apt-get update -qq && \
	apt-get install -qq -y \
		mp3val \
		flac \
		wget \
		nano \
		unzip \
		nodejs \
		git \
		jq \
		cron  && \
	apt-get purge --auto-remove -y && \
	apt-get clean
else
	echo "PRE-REQ ALREADY INSTALLED"
fi

if [ ! -f "/usr/local/bin/beet" ]; then
	apt-get update -qq && \
	apt-get install -qq -y \
		libchromaprint-tools \
		python-dev \
		python-pip && \
	apt-get purge --auto-remove -y && \
	apt-get clean

	pip install --no-cache-dir -U \
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

	
service cron restart

if [ ! -f "/usr/bin/ffmpeg" ]; then 
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
	mkdir -p /config/scripts
	# Set Permissions
	echo "setting permissions..."
	chmod 0777 /config/scripts
	echo "done"
fi

if [ -f /config/scripts/lidarr-download-automation-start.bash ]; then
	rm /config/scripts/lidarr-automated-downloader-start.bash
	sleep 1s
fi

if [ ! -f /config/scripts/lidarr-download-automation-start.bash ]; then
	echo "downloading lidarr-automated-downloader-start.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lidarr-automated-downloader/docker/lidarr-automated-downloader-start.bash"
	curl -o /config/scripts/lidarr-automated-downloader-start.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lidarr-automated-downloader/docker/lidarr-automated-downloader-start.bash
	echo "done"
fi

# Remove lock file incase, system was rebooted before script finished
if [ -d /config/scripts/00-lidarr-automated-downloader.exclusivelock ]; then
	rmdir /config/scripts/00-lidarr-automated-downloader.exclusivelock
fi

if [ -d "/config/scripts/lidarr-automated-downloader" ]; then
	find "/config/scripts/lidarr-automated-downloader" -type f -iname "*.json" -delete
fi

echo "INSTALLING DEEZLOADER-REMIX"

rm -rf /deezloaderremix && \

if [ -d "/config/xdg" ]; then
	rm -rf /config/xdg
fi

if [ ! -d /downloads/deezloaderremix ]; then
	mkdir /downloads/deezloaderremix
fi
ln -sf /downloads/deezloaderremix "/root/Deezloader Music" && \

cd / && \
if [ -f /development.zip  ]; then
	rm /development.zip 
	sleep 1s
fi

wget https://notabug.org/RemixDevs/DeezloaderRemix/archive/development.zip && \
unzip development.zip && \
rm development.zip && \

sed -i "s/\"trackNameTemplate\": \"%artist% - %title%\"/\"trackNameTemplate\": \"%disc%%number% - %title% %explicit%\"/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"albumTrackNameTemplate\": \"%number% - %title%\"/\"albumTrackNameTemplate\": \"%disc%%number% - %title% %explicit%\"/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"createAlbumFolder\": true/\"createAlbumFolder\": false/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"embeddedArtworkSize\": 800/\"embeddedArtworkSize\": 1000/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"localArtworkSize\": 1000/\"localArtworkSize\": 1400/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"saveArtwork\": false/\"saveArtwork\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"queueConcurrency\": 3/\"queueConcurrency\": 6/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"maxBitrate\": \"3\"/\"maxBitrate\": \"9\"/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"coverImageTemplate\": \"cover\"/\"coverImageTemplate\": \"folder\"/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"createCDFolder\": true/\"createCDFolder\": false/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"createSingleFolder\": false/\"createSingleFolder\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"removeAlbumVersion\": false/\"removeAlbumVersion\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"syncedlyrics\": false/\"syncedlyrics\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"logErrors\": false/\"logErrors\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"logSearched\": false/\"logSearched\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"trackTotal\": false/\"trackTotal\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"discTotal\": false/\"discTotal\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"explicit\": false/\"explicit\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"barcode\": false/\"barcode\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"unsynchronisedLyrics\": false/\"unsynchronisedLyrics\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"copyright\": false/\"copyright\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"musicpublisher\": false/\"musicpublisher\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"composer\": false/\"composer\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"mixer\": false/\"mixer\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"author\": false/\"author\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"writer\": false/\"writer\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"engineer\": false/\"engineer\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"producer\": false/\"producer\": true/g" "/deezloaderremix/app/default.json" && \
sed -i "s/\"multitagSeparator\": \"; \"/\"multitagSeparator\": \"andFeat\"/g" "/deezloaderremix/app/default.json" && \

cd /deezloaderremix && \
npm install && \
cd /deezloaderremix/app && \
npm install && \
cd / && \

echo "Starting Deezloader Remix"
nohup node /deezloaderremix/app/app.js &>/dev/null &
sleep 20s

if [ -d "/config/xdg" ]; then
	chmod 0777 -R /config/xdg
fi

if [ -x "$(command -v crontab)" ]; then	
	if grep "lidarr-automated-downloader-start.bash" /etc/crontab; then
		echo "job already added..."
	else
		echo "adding cron job to crontab..."
		echo "*/15 * * * *   root   bash /config/scripts/lidarr-automated-downloader-start.bash > /config/scripts/cron-job.log" >> "/etc/crontab"
	fi
	if grep "musicbrainzerror.log" /etc/crontab; then
		echo "job already added..."
	else
		echo "adding cron job to crontab..."
		echo "0 18 * * *   root   rm \"/config/scripts/lidarr-automated-downloader/musicbrainzerror.log\" && touch \"/config/scripts/lidarr-automated-downloader/musicbrainzerror.log\""  >> "/etc/crontab"
	fi
	if grep "daily.log" /etc/crontab; then
		echo "job already added..."
	else
		echo "adding cron job to crontab..."
		echo "5 18 * * *   root   rm \"/config/scripts/lidarr-automated-downloader/daily.log\" && touch \"/config/scripts/lidarr-automated-downloader/daily.log\""  >> "/etc/crontab"
	fi
	service cron restart
else
	echo "cron NOT INSTALLED"
fi

echo "==========lidarr-automated-downloader setup==========="
exit 0
