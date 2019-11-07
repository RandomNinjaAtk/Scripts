#!/bin/bash
if [ -x "$(command -v crontab)" ]; then	
	if grep "lidarr-download-automation-start.bash" /etc/crontab; then
		echo "job already added..."
	else
		echo "adding cron job to crontab..."
		echo "*/5 * * * *   root   if [ ! -d /config/scripts/lidarr-download-automation/.lidarr-download-automation.exclusivelock ]; then rm /config/scripts/cron-job.log; fi; bash /config/scripts/lidarr-download-automation-start.bash > /config/scripts/cron-job.log"
	fi
else
	echo "cron NOT INSTALLED"
fi
exit 0
