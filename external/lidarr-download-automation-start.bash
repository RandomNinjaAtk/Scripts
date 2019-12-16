#!/bin/bash

if [ ! -d /config/scripts/lidarr-download-automation ]; then
    echo "setting up script lidarr-download-automation directory..."
    mkdir /config/scripts/lidarr-download-automation
    # Set Permissions
    echo "setting permissions..."
    chmod 0777 /config/scripts/lidarr-download-automation
    echo "done"
fi

# Download Scripts
if [ -f /config/scripts/lidarr-download-automation/lidarr-download-automation.bash ]; then
	rm /config/scripts/lidarr-download-automation/lidarr-download-automation.bash
	sleep 1s
fi

if [ ! -f /config/scripts/lidarr-download-automation/lidarr-download-automation.bash ]; then
    echo "downloading lidarr-download-automation.bash from: https://github.com/Migz93/lidarr-download-automation/blob/develop/lidarr-download-automation.bash"
    curl -o /config/scripts/lidarr-download-automation/lidarr-download-automation.bash https://raw.githubusercontent.com/Migz93/lidarr-download-automation/dremix/lidarr-download-automation.bash
    echo "done"
    chmod 0666 /config/scripts/lidarr-download-automation/lidarr-download-automation.bash
fi

if [ ! -f /config/scripts/lidarr-download-automation/config ]; then
    echo "downloading config from: https://github.com/RandomNinjaAtk/Scripts/blob/master/config/lidarr-dl-automation-config"
    curl -o /config/scripts/lidarr-download-automation/config https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/config/lidarr-dl-automation-config
    echo "done"
    chmod 0666 /config/scripts/lidarr-download-automation/config
fi

if [ -f /config/scripts/beets/config.xml ]; then
	rm /config/scripts/beets/config.xml
	sleep 1s
fi
if [ ! -f /config/scripts/beets/config.xml ]; then
	echo "downloading config.yaml from: https://github.com/RandomNinjaAtk/Scripts/blob/master/config/config.yaml"
	curl -o /config/scripts/beets/config.yaml https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/config/config.yaml
	echo "done"
	chmod 0666 /config/scripts/beets/config.yaml
fi


if [ -f /config/scripts/beets/import.bash ]; then
	rm /config/scripts/beets/import.bash
	sleep 1s
fi

if [ ! -f /config/scripts/beets/import.bash ]; then
    echo "downloading import.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/external/import.bash"
    curl -o /config/scripts/beets/import.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/external/import.bash
    echo "done"
    chmod 0666 /config/scripts/beets/import.bash
    sed -i "s/#INSERT/source \/config\/scripts\/beets\/import.bash/g" "/config/scripts/lidarr-download-automation/lidarr-download-automation.bash"
fi

if mkdir /config/scripts/00-lidarr-download-automation.exclusivelock; then
    rm /config/scripts/script-run.log
    cd /config/scripts/lidarr-download-automation/
    bash lidarr-download-automation.bash > /config/scripts/script-run.log
    sleep 10s
    rmdir /config/scripts/00-lidarr-download-automation.exclusivelock
else 
    echo "ERROR: /config/scripts/lidarr-download-automation/lidarr-download-automation.bash is still running..."
    exit 1
fi
exit 0
