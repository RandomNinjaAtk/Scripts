#!/bin/bash

if mkdir /config/scripts/00-lidarr-automated-downloader.exclusivelock; then
  
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
