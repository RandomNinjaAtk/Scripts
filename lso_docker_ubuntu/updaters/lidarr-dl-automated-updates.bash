#!/bin/bash
echo "==========LIDARR DL AUTO INSTALLER AUTOMATED UPDATES==========="

if [ -f /config/custom-cont-init.d/lidarr_dl_auto_installer.bash ]; then
	echo "Previous version detected..."
	echo "removing....lidarr_dl_auto_installer.bash"
	rm /config/custom-cont-init.d/lidarr_dl_auto_installer.bash
else 
	echo "begining updated script installation..."
	echo "downloading lidarr_dl_auto_installer.bash from: https://github.com/RandomNinjaAtk/Scripts/raw/master/lso_docker_ubuntu/lidarr_dl_auto_installer.bash"  && \
	curl -o /config/custom-cont-init.d/lidarr_dl_auto_installer.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/lidarr_dl_auto_installer.bash && \
	echo "download complete" && \
	echo "running lidarr_dl_auto_installer.bash..." && \
	bash /config/custom-cont-init.d/lidarr_dl_auto_installer.bash && \
	rm /config/custom-cont-init.d/lidarr_dl_auto_installer.bash
fi

exit 0
