#!/bin/bash

if [ ! -d /config/scripts/lidarr-automated-downloader ]; then
    echo "setting up script lidarr-automated-downloader directory..."
    mkdir -p /config/scripts/lidarr-automated-downloader
    # Set Permissions
    echo "setting permissions..."
    chmod 0777 /config/scripts/lidarr-automated-downloader
    echo "done"
fi

if mkdir /config/scripts/00-lidarr-download-automation.exclusivelock; then
	
	#hotio compatibility fix
	if [ ! -f /config/config.xml ]; then
		ln -s /config/app/config.xml /config/config.xml
		sleep 1s
	fi
	
	# Download Scripts
	if [ -f /config/scripts/lidarr-automated-downloader/lidarr-automated-downloader.bash ]; then
		rm /config/scripts/lidarr-automated-downloader/lidarr-automated-downloader.bash
		sleep 1s
	fi

	if [ ! -f /config/scripts/lidarr-automated-downloader/lidarr-automated-downloader.bash ]; then
	    echo "downloading lidarr-automated-downloader.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lidarr-automated-downloader/lidarr-automated-downloader.bash"
	    curl -o /config/scripts/lidarr-automated-downloader/lidarr-automated-downloader.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lidarr-automated-downloader/lidarr-automated-downloader.bash
	    echo "done"
	    chmod 0666 /config/scripts/lidarr-automated-downloader/lidarr-automated-downloader.bash
	fi

	if [ ! -f /config/scripts/lidarr-automated-downloader/config ]; then
	    echo "downloading config from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lidarr-automated-downloader/config"
	    curl -o /config/scripts/lidarr-automated-downloader/config https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lidarr-automated-downloader/config
	    echo "done"
	    chmod 0666 /config/scripts/lidarr-automated-downloader/config
	fi
  
	rm /config/scripts/script-run.log
	cd /config/scripts/lidarr-automated-downloader/
	bash lidarr-automated-downloader.bash > /config/scripts/script-run.log
	sleep 10s
	rmdir /config/scripts/00-lidarr-automated-downloader.exclusivelock
	
	find /config/scripts -type f -exec chmod 0666 {} \;
	find /config/scripts -type d -exec chmod 0777 {} \;
	
else
	echo "ERROR: /config/scripts/lidarr-automated-downloader/lidarr-automated-downloader.bash is still running..."
	exit 1
fi
exit 0
