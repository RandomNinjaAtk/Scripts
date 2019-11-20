  
#!/bin/bash
echo "==========MP4 AUTOMATOR AUTOMATED INSTALLER & UPDATER==========="

if [ -f /config/custom-cont-init.d/mp4-automated-installer.bash ]; then
	rm /config/custom-cont-init.d/mp4-automated-installer.bash
else 
	echo "downloading mp4-automated-installer.bashh from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/mp4-automated-installer.bash"  && \
	curl -o /config/custom-cont-init.d/mp4-automated-installer.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/mp4-automated-installer.bash  && \
	echo "download complete" && \
	echo "running mp4-automated-installer.bash..." && \
	bash /config/custom-cont-init.d/mp4-automated-installer.bash && \
	rm /config/custom-cont-init.d/mp4-automated-installer.bash
fi

exit 0
