#!/bin/bash
echo "==========START SABNZBD SCRIPTS AUTOMATED UPDATES==========="

if [ -f /config/custom-cont-init.d/sabnzbd_script_setup.bash ]; then
	echo "Previous version detected..."
	echo "removing....sabnzbd_script_setup.bash"
	rm /config/custom-cont-init.d/sabnzbd_script_setup.bash
else 
	echo "begining updated script installation..."
	echo "downloading sabnzbd_script_setup.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/sabnzbd_script_setup.bash"  && \
	curl -o /config/custom-cont-init.d/sabnzbd_script_setup.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/sabnzbd_script_setup.bash && \
	echo "download complete" && \
	echo "running sabnzbd_script_setup.bash..." && \
	bash /config/custom-cont-init.d/sabnzbd_script_setup.bash && \
	rm /config/custom-cont-init.d/sabnzbd_script_setup.bash
fi
echo "==========END SABNZBD SCRIPTS AUTOMATED UPDATES==========="
exit 0
