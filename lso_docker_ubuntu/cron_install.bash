#!/bin/bash
echo "==========INSTALLING TOOLS==========="
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
echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
