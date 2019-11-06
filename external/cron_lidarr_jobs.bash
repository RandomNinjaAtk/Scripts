#!/bin/bash
if [ -x "$(command -v crontab)" ]; then	
	if grep "lidarr-download-automation-start.bash" /etc/crontab; then
		echo "job already added..."
	else
		echo "adding cron job to crontab..."
		echo "*/5 * * * *   root    cd /config/scripts && bash lidarr-download-automation-start.bash" >> "/etc/crontab"
	fi
else
	echo "cron NOT INSTALLED"
fi
exit 0
