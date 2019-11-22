#!/bin/bash
echo "==========LIDARR DL AUTOMATION SETUP==========="

if ! [ -x "$(command -v mp3val)" ]; then	
	echo "START MP3VAL INSTALLTION"
	apt-get update -qq
	if { apt-get install -y -qq mp3val; }; then
		apt-get purge --auto-remove -y
		apt-get clean
		echo "INSTALLATION SUCCESSFUL"
	else
		echo "ERROR: INSTALLTION UNSUCCESSFUL"
	fi
else
	echo "MP3VAL ALREADY INSTALLED"
fi
if ! [ -x "$(command -v flac)" ]; then	
	echo "START FLAC INSTALLTION"
	apt-get update -qq
	if { apt-get install -y -qq flac; }; then
		apt-get purge --auto-remove -y
		apt-get clean
		echo "INSTALLATION SUCCESSFUL"
	else
		echo "ERROR: INSTALLTION UNSUCCESSFUL"
	fi
else
	echo "FLAC ALREADY INSTALLED"
fi

if ! [ -x "$(command -v ffmpeg)" ]; then
	echo "INSTALLING FFMPEG"
	apt-get update -qq && \
	apt-get install -y xz-utils
	
	mkdir /tmp/ffmpeg
	curl -o /tmp/ffmpeg/ffmpeg-git-amd64-static.tar.xz https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz
	cd /tmp/ffmpeg
	tar xvf ffmpeg-git-amd64-static.tar.xz
	find "/usr/bin/" -type f -iname "ffmpeg" -exec rm {} \;
	find "/usr/bin/" -type f -iname "ffprobe" -exec rm {} \;
	find "/tmp/ffmpeg" -type f -iname "ffmpeg" -exec mv {} /usr/bin/ \;
	find "/tmp/ffmpeg" -type f -iname "ffprobe" -exec mv {} /usr/bin/ \;
	cd /
	rm -rf /tmp/ffmpeg
else
	echo "FFMPEG ALREADY INSTALLED"
fi

if ! [ -x "$(command -v crontab)" ]; then	
	echo "INSTALLING cron"
	apt-get update -qq && \
	apt-get install -qq -y \
		wget \
		nano \
		unzip \
		cron	
	apt-get purge --auto-remove -y && \
	apt-get clean
	service cron restart
else
	echo "cron ALREADY INSTALLED"
fi

if [ ! -d /config/scripts ]; then
	echo "setting up script directory"
	mkdir /config/scripts
	# Set Permissions
	echo "setting permissions..."
	chmod 0777 /config/scripts
	echo "done"
fi

if [ -f /config/scripts/lidarr-download-automation-start.bash ]; then
	rm /config/scripts/lidarr-download-automation-start.bash
	sleep 1s
fi

if [ ! -f /config/scripts/lidarr-download-automation-start.bash ]; then
	echo "downloading lidarr-download-automation-start.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/external/cron_lidarr_jobs.bash"
	curl -o /config/scripts/lidarr-download-automation-start.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/external/lidarr-download-automation-start.bash
	echo "done"
fi

if [ -x "$(command -v crontab)" ]; then	
	if grep "lidarr-download-automation-start.bash" /etc/crontab; then
		echo "job already added..."
	else
		echo "adding cron job to crontab..."
		echo "*/30 * * * *   root   bash /config/scripts/lidarr-download-automation-start.bash > /config/scripts/cron-job.log" >> "/etc/crontab"
	fi
else
	echo "cron NOT INSTALLED"
fi

# Remove lock file incase, system was rebooted before script finished
if [ -d /config/scripts/.lidarr-download-automation.exclusivelock ]; then
	rmdir /config/scripts/.lidarr-download-automation.exclusivelock
fi

service cron restart

echo "=====LIDARR DL AUTOMATION SETUP COMPLETE====="
exit 0
