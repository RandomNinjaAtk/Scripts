#!/bin/bash
echo "==========LIDARR DL AUTOMATION SETUP==========="

if [ ! -f /config/custom-cont-init.d/audio_tools_install.bash ]; then
    echo "downloading audio_tools_install.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/audio_tools_install.bash"
    curl -o /config/custom-cont-init.d/audio_tools_install.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/audio_tools_install.bash
    echo "done"
	echo "running audio_tools_install.bash..."
	bash /config/custom-cont-init.d/audio_tools_install.bash
fi

if [ ! -f /config/custom-cont-init.d/ffmpeg_install.bash ]; then
    echo "downloading ffmpeg_install.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/ffmpeg_install.bash"
    curl -o /config/custom-cont-init.d/ffmpeg_install.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/ffmpeg_install.bash
    echo "done"
	echo "running ffmpeg_install.bash..."
	bash /config/custom-cont-init.d/ffmpeg_install.bash
fi

if [ ! -f /config/custom-cont-init.d/cron_install.bash ]; then
    echo "downloading cron_install.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/cron_install.bash"
    curl -o /config/custom-cont-init.d/cron_install.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/cron_install.bash
    echo "done"
	echo "running cron_install.bash..."
	bash /config/custom-cont-init.d/cron_install.bash
fi

echo "setting up script directory"
if [ ! -d /config/scripts ]; then
  mkdir /config/scripts
    # Set Permissions
  echo "setting permissions..."
  chmod 0777 /config/scripts
  echo "done"
fi

if [ ! -f /config/scripts/lidarr-download-automation-start.bash ]; then
    echo "downloading lidarr-download-automation-start.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/external/cron_lidarr_jobs.bash"
    curl -o /config/scripts/lidarr-download-automation-start.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/external/lidarr-download-automation-start.bash
    echo "done"
fi

if [ ! -f /config/custom-cont-init.d/cron_lidarr_jobs.bash ]; then
    echo "downloading cron_lidarr_jobs.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/external/cron_lidarr_jobs.bash"
    curl -o /config/custom-cont-init.d/cron_lidarr_jobs.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/external/cron_lidarr_jobs.bash
    echo "done"
	echo "running cron_lidarr_jobs.bash..."
	bash /config/custom-cont-init.d/cron_lidarr_jobs.bash
fi
echo "=====LIDARR DL AUTOMATION SETUP COMPLETE====="
exit 0
