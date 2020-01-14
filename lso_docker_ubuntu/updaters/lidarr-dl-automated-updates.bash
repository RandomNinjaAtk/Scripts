#!/bin/bash
echo "==========START LIDARR DL AUTO INSTALLER AUTOMATED UPDATES==========="

# Check for folder, create folder if needed (hotio docker image compatibility)
if [ ! -d /config/custom-cont-init.d ]; then
	mkdir /config/custom-cont-init.d
fi

if [ -f /config/custom-cont-init.d/lidarr_dl_auto_installer.bash ]; then
	echo "Previous version detected..."
	echo "removing....lidarr_dl_auto_installer.bash"
	rm /config/custom-cont-init.d/lidarr_dl_auto_installer.bash
fi
if [ ! -f /config/custom-cont-init.d/lidarr_dl_auto_installer.bash ]; then
	echo "begining updated script installation..."
	echo "downloading lidarr_dl_auto_installer.bash from: https://github.com/RandomNinjaAtk/Scripts/raw/master/lso_docker_ubuntu/lidarr_dl_auto_installer.bash"  && \
	curl -o /config/custom-cont-init.d/lidarr_dl_auto_installer.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/lidarr_dl_auto_installer.bash && \
	echo "download complete" && \
	echo "running lidarr_dl_auto_installer.bash..." && \
	bash /config/custom-cont-init.d/lidarr_dl_auto_installer.bash && \
	rm /config/custom-cont-init.d/lidarr_dl_auto_installer.bash
fi
echo "==========END LIDARR DL AUTO INSTALLER AUTOMATED UPDATES==========="
exit 0
