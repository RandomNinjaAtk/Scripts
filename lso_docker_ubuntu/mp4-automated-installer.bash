#!/bin/bash
echo "==========MP4 AUTOMATOR INSTALLER==========="
echo ""
echo ""
echo "===INSTALLING PRE-REQS==="

apt-get update -qq && \
apt-get install -qq -y \
	git \
	openssl \
	python3-pip \
	libffi-dev \
	libssl-dev \
	libxml2-dev \
	libxslt1-dev \
	mkvtoolnix \
	zlib1g-dev \
	ffmpeg && \
	
apt-get purge --auto-remove -y && \
apt-get clean

pip3 install --no-cache-dir -U \
	requests \
	requests[security] \
	requests-cache \
	babelfish \
	guessit \
	subliminal \
	stevedore \
	python-dateutil \
	qtfaststart \
	tmdbsimple
	
echo ""
echo ""
echo "=========COMPLETE========"
echo ""
echo "===CHECKING FOR EXISTING CONFIG==="
if [ -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
	echo "Config found..." && \
	echo "Backup autoProcess.ini configuration..." && \
	mv /config/scripts/sickbeard_mp4_automator/autoProcess.ini /config/scripts/
else
	echo "No config found..."
fi
echo ""
echo "===INSTALLING & UPDATING SICKBEARD AUTOMATOR==="
if [ -d /config/scripts/sickbeard_mp4_automator ]; then
	echo "Removing previous installation..."
	rm -rf /config/scripts/sickbeard_mp4_automator
fi
echo "Downloading sickbeared_mp4_automator..." && \
git clone git://github.com/mdhiggins/sickbeard_mp4_automator.git /config/scripts/sickbeard_mp4_automator/ && \
touch /config/scripts/sickbeard_mp4_automator/index.log && \
chmod 0777 -R /config/scripts/sickbeard_mp4_automator
if [ ! -d /var/log/sickbeard_mp4_automator ]; then
	mkdir /var/log/sickbeard_mp4_automator
fi
rm -rf /var/log/sickbeard_mp4_automator/* && \
chmod 0777 -R /var/log/sickbeard_mp4_automator && \
ln -s /config/scripts/sickbeard_mp4_automator/index.log /var/log/sickbeard_mp4_automator/index.log  && \
if [ -f /config/scripts/autoProcess.ini ]; then
	echo "Restoring backup (autoProcess.ini) configuration..." && \
	mv /config/scripts/autoProcess.ini /config/scripts/sickbeard_mp4_automator/
fi

if [ ! -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
	echo "New installation detected..."
	echo "Downloading config from: https://github.com/RandomNinjaAtk/Scripts/blob/master/config/autoProcess.ini" && \
	curl -o /config/scripts/sickbeard_mp4_automator/autoProcess.ini https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/config/autoProcess.ini && \
	echo "done" && \
	chmod 0666 /config/scripts/sickbeard_mp4_automator/autoProcess.ini
fi

# Updating config files
if [ -f /config/config.xml ]; then
	# Update config file if radarr
	if grep -q 7878 /config/config.xml; then
		if [ -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
			if grep -q radarrkey /config/scripts/sickbeard_mp4_automator/autoProcess.ini; then
				echo "Radarr installation detected..."
				echo "Updating config with radarr api key..."
				search="radarrkey"
				apikey="$(grep "<ApiKey>" /config/config.xml | sed "s/\  <ApiKey>//;s/<\/ApiKey>//")"
				sed -i "s/${search}/${apikey}/g" /config/scripts/sickbeard_mp4_automator/autoProcess.ini
				chmod 0777 -R /config/scripts/sickbeard_mp4_automator
			fi
		fi
	fi

	# Update config file if sonarr
	if grep -q 8989 /config/config.xml; then
		if [ -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
			if grep -q sonarrkey /config/scripts/sickbeard_mp4_automator/autoProcess.ini; then
				echo "Sonarr installation detected..."
				echo "Updating config with sonarr api key..."
				search="sonarrkey"
				apikey="$(grep "<ApiKey>" /config/config.xml | sed "s/\  <ApiKey>//;s/<\/ApiKey>//")"
				sed -i "s/${search}/${apikey}/g" /config/scripts/sickbeard_mp4_automator/autoProcess.ini
				sed -i "s/Poster/Thumbnail/g" /config/scripts/sickbeard_mp4_automator/autoProcess.ini
				chmod 0777 -R /config/scripts/sickbeard_mp4_automator
			fi
		fi
	fi
else
	# Compensation for other scrips if using Sabnzbd
	
	if [ -f /config/scripts/sickbeard_mp4_automator/mp4-video-processing.bash ]; then
		rm /config/scripts/sickbeard_mp4_automator/mp4-video-processing.bash
	else
		echo "downloading mp4-video-processing.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/sabnzbd/mp4-video-processing.bash"
		curl -o /config/scripts/sickbeard_mp4_automator/mp4-video-processing.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/mp4-video-processing.bash
		echo "done"
		chmod 777 /config/scripts/sickbeard_mp4_automator/mp4-video-processing.bash
	fi

	if [ -f /config/scripts/video-processing.bash ]; then
		cp /config/scripts/video-processing.bash /config/scripts/sickbeard_mp4_automator/video-processing.bash
		chmod 777 /config/scripts/sickbeard_mp4_automator/video-processing.bash
	fi

	if [ -f /config/scripts/AudioPostProcessing.bash ]; then
		cp /config/scripts/AudioPostProcessing.bash /config/scripts/sickbeard_mp4_automator/AudioPostProcessing.bash
		chmod 777 /config/scripts/sickbeard_mp4_automator/AudioPostProcessing.bash
	fi

	if [ -f /config/scripts/MKV-Cleaner.bash ]; then
		cp /config/scripts/MKV-Cleaner.bash /config/scripts/sickbeard_mp4_automator/MKV-Cleaner.bash
		chmod 777 /config/scripts/sickbeard_mp4_automator/MKV-Cleaner.bash
	fi
fi

echo "=====MP4 AUTOMATOR INSTALLATION COMPLETE====="
exit 0
