#!/bin/bash
echo "==========start lsio-automated-installer automated updates==========="

# Check for folder, create folder if needed (hotio docker image compatibility)
if [ ! -d /config/custom-cont-init.d ]; then
	mkdir -p /config/custom-cont-init.d
fi

if [ -f /config/custom-cont-init.d/lsio-automated-installer.bash ]; then
	echo "Previous version detected..."
	echo "removing....lsio-automated-installer.bash"
	rm /config/custom-cont-init.d/lsio-automated-installer.bash
fi
if [ ! -f /config/custom-cont-init.d/lsio-automated-installer.bash ]; then
	echo "begining updated script installation..."
	echo "downloading lsio-automated-installer.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lidarr-automated-downloader/docker/lsio-automated-installer.bash"  && \
	curl -o /config/custom-cont-init.d/lsio-automated-installer.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lidarr-automated-downloader/docker/lsio-automated-installer.bash && \
	echo "download complete" && \
	echo "running lsio-automated-installer.bash..." && \
	bash /config/custom-cont-init.d/lsio-automated-installer.bash && \
	rm /config/custom-cont-init.d/lsio-automated-installer.bash
fi
echo "==========end start lsio-automated-installer automated updates==========="
exit 0
