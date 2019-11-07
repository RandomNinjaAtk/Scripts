#!/bin/bash
echo "==========RADARR MP4 AUTOMATOR INSTALLER==========="

if [ ! -f /config/custom-cont-init.d/mp4_automator.bash ]; then
	echo "downloading ffmpeg_install.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/mp4_automator.bash"
	curl -o /config/custom-cont-init.d/mp4_automator.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/mp4_automator.bash
	echo "done"
	echo "running mp4_automator.bash..."
	bash /config/custom-cont-init.d/mp4_automator.bash
fi

if [ ! -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
	echo "downloading config from: https://github.com/RandomNinjaAtk/Scripts/blob/master/config/radarr-autoProcess.ini"
	curl -o /config/scripts/sickbeard_mp4_automator/autoProcess.ini https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/config/radarr-autoProcess.ini
	echo "done"
	chmod 0666 /config/scripts/lidarr-download-automation/config
fi

if [ -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
	echo "Updating config with radarr api key..."
	local search="radarrkey"
	local apikey="$(grep "<ApiKey>" /config/config.xml | sed "s/\  <ApiKey>//;s/<\/ApiKey>//")"
	sed -i "s/${search}/${apikey}/g" /config/scripts/sickbeard_mp4_automator/autoProcess.ini
	chmod a+rwx -R /config/scripts/sickbeard_mp4_automator
fi

echo "=====RADARR MP4 AUTOMATOR INSTALLER SETUP COMPLETE====="
exit 0
