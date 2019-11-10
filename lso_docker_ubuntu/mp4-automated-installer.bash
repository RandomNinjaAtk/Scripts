#!/bin/bash
echo "==========MP4 AUTOMATOR INSTALLER==========="

if [ -f /config/custom-cont-init.d/mp4_automator.bash ]; then
	rm /config/custom-cont-init.d/mp4_automator.bash
fi
echo "downloading ffmpeg_install.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/mp4_automator.bash"
curl -o /config/custom-cont-init.d/mp4_automator.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/mp4_automator.bash
echo "done"
echo "running mp4_automator.bash..."
bash /config/custom-cont-init.d/mp4_automator.bash

if [ ! -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
	echo "downloading config from: https://github.com/RandomNinjaAtk/Scripts/blob/master/config/autoProcess.ini"
	curl -o /config/scripts/sickbeard_mp4_automator/autoProcess.ini https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/config/autoProcess.ini
	echo "done"
	chmod 0666 /config/scripts/sickbeard_mp4_automator/autoProcess.ini
fi

# Updating config files
if [ -f /config/config.xml ]; then
	# Update config file if radarr
	if grep -q 7878 /config/config.xml; then
		if [ -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
			echo "Updating config with radarr api key..."
			search="radarrkey"
			apikey="$(grep "<ApiKey>" /config/config.xml | sed "s/\  <ApiKey>//;s/<\/ApiKey>//")"
			sed -i "s/${search}/${apikey}/g" /config/scripts/sickbeard_mp4_automator/autoProcess.ini
			chmod 0777 -R /config/scripts/sickbeard_mp4_automator
		fi
	fi

	# Update config file if sonnarr
	if grep -q 8989 /config/config.xml; then
		if [ -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
			echo "Updating config with sonarr api key..."
			search="sonarrkey"
			apikey="$(grep "<ApiKey>" /config/config.xml | sed "s/\  <ApiKey>//;s/<\/ApiKey>//")"
			sed -i "s/${search}/${apikey}/g" /config/scripts/sickbeard_mp4_automator/autoProcess.ini
			sed -i "s/Poster/Thumbnail/g" /config/scripts/sickbeard_mp4_automator/autoProcess.ini
			chmod 0777 -R /config/scripts/sickbeard_mp4_automator
		fi
	fi
fi

# Compensation for other scrips if using Sabnzbd

if [ -f /config/scripts/video-processing.bash ]; then
	ln -s /config/scripts/video-processing.bash /config/scripts/sickbeard_mp4_automator/video-processing.bash
fi

if [ -f /config/scripts/AudioPostProcessing.bash ]; then
	ln -s /config/scripts/AudioPostProcessing.bash /config/scripts/sickbeard_mp4_automator/AudioPostProcessing.bash
fi

if [ -f /config/scripts/Deobfuscate.py ]; then
	ln -s /config/scripts/Deobfuscate.py /config/scripts/sickbeard_mp4_automator/Deobfuscate.py
fi

if [ -f /config/scripts/MKV-Cleaner.bash ]; then
	ln -s /config/scripts/MKV-Cleaner.bash /config/scripts/sickbeard_mp4_automator/MKV-Cleaner.bash
fi

echo "=====MP4 AUTOMATOR INSTALLER SETUP COMPLETE====="
exit 0
