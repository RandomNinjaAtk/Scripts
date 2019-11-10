#!/bin/bash
echo "==========INSTALLING SICKBEARD MP4 AUTOMATOR==========="

if ! [ -x "$(command -v mkvmerge)" ]; then
	echo "INSTALLING PRE-REQS"
	apt-get update && \
	apt-get install -y \
		git \
		openssl \
		python-dev \
		libffi-dev \
		libssl-dev \
		libxml2-dev \
		libxslt1-dev \
		mkvtoolnix \
		zlib1g-dev

	apt-get purge --auto-remove -y && \
	apt-get clean
fi

if ! [ -x "$(command -v ffmpeg)" ]; then
	if [ -f /config/custom-cont-init.d/ffmpeg_install.bash ]; then
		echo "running ffmpeg_install.bash..." && \
		bash /config/custom-cont-init.d/ffmpeg_install.bash && \
		rm /config/custom-cont-init.d/ffmpeg_install.bash
	else
		echo "downloading ffmpeg_install.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/lso_docker_ubuntu/ffmpeg_install.bash" && \
		curl -o /config/custom-cont-init.d/ffmpeg_install.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/lso_docker_ubuntu/ffmpeg_install.bash && \
		echo "done" && \
		echo "running ffmpeg_install.bash..." && \
		bash /config/custom-cont-init.d/ffmpeg_install.bash && \
		rm /config/custom-cont-init.d/ffmpeg_install.bash
	fi
fi

if ! [ -x "$(command -v pip)" ]; then
	echo "INSTALLING PIP TOOLS" && \
		apt-get update && \
		apt-get install -y \
			python-pip

		apt-get purge --auto-remove -y && \
		apt-get clean
		
	pip install --no-cache-dir -U \
		requests \
		requests[security] \
		requests-cache \
		babelfish \
		"guessit<2" \
		"subliminal<2" \
		stevedore==1.19.1 \
		python-dateutil \
		qtfaststart
fi

if [ -f /config/scripts/sickbeard_mp4_automator/autoProcess.ini ]; then
	echo "Backup autoProcess.ini configuration" && \
	mv /config/scripts/sickbeard_mp4_automator/autoProcess.ini /config/scripts/ && \
	echo "DOWNLOAD CURRENT SICKBEARD_MP4_AUTOMATOR" && \
	rm -rf /config/scripts/sickbeard_mp4_automator && \
	git clone git://github.com/mdhiggins/sickbeard_mp4_automator.git /config/scripts/sickbeard_mp4_automator/ && \
	touch /config/scripts/sickbeard_mp4_automator/index.log && \
	echo "Restore autoProcess.ini configuration" && \
	mv /config/scripts/autoProcess.ini /config/scripts/sickbeard_mp4_automator/ && \
	chmod 0777 -R /config/scripts/sickbeard_mp4_automator && \
	if [ -d /var/log/sickbeard_mp4_automator ]; then
		rm -rf /var/log/sickbeard_mp4_automator
	fi
	mkdir /var/log/sickbeard_mp4_automator && \
	chmod 0777 -R /var/log/sickbeard_mp4_automator && \
	ln -s /config/scripts/sickbeard_mp4_automator/index.log /var/log/sickbeard_mp4_automator/index.log
	echo "DONE"
else
	echo "DOWNLOAD CURRENT SICKBEARD_MP4_AUTOMATOR" && \
	if [ -d /config/scripts/sickbeard_mp4_automator ]; then
		rm -rf /config/scripts/sickbeard_mp4_automator && \
	fi
	git clone git://github.com/mdhiggins/sickbeard_mp4_automator.git /config/scripts/sickbeard_mp4_automator/ && \
	touch /config/scripts/sickbeard_mp4_automator/index.log && \
	chmod 0777 -R /config/scripts/sickbeard_mp4_automator && \
	if [ -d /var/log/sickbeard_mp4_automator ]; then
		rm -rf /var/log/sickbeard_mp4_automator && \
	fi
	mkdir /var/log/sickbeard_mp4_automator && \
	chmod 0777 -R /var/log/sickbeard_mp4_automator && \
	ln -s /config/scripts/sickbeard_mp4_automator/index.log /var/log/sickbeard_mp4_automator/index.log && \
	echo "DONE"
fi

echo "=====SICKBEARD MP4 AUTOMATOR INSTALLATION COMPLETE====="
exit 0
