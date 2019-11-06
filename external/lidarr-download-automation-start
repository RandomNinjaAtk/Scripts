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
if [ ! -f /config/scripts/lidarr-download-automation/lidarr-download-automation.bash ]; then
    echo "downloading lidarr-download-automation.bash from: https://github.com/Migz93/lidarr-download-automation/blob/develop/lidarr-download-automation.bash"
    curl -o /config/scripts/lidarr-download-automation/lidarr-download-automation.bash https://raw.githubusercontent.com/Migz93/lidarr-download-automation/develop/lidarr-download-automation.bash
    echo "done"
fi

if [ ! -f /config/scripts/lidarr-download-automation/config ]; then
    echo "downloading config from: https://github.com/Migz93/lidarr-download-automation/blob/develop/lidarr-download-automation.bash"
    curl -o /config/scripts/lidarr-download-automation/config https://raw.githubusercontent.com/Migz93/lidarr-download-automation/develop/lidarr-download-automation.bash
    echo "done"
fi

if mkdir /config/scripts/lidarr-download-automation/.lidarr-download-automation.exclusivelock; then
    cd /config/scripts/lidarr-download-automation/
    bash lidarr-download-automation.bash
    sleep 10s
    rmdir /config/scripts/lidarr-download-automation/.lidarr-download-automation.exclusivelock
else 
    echo "ERROR: /config/scripts/lidarr-download-automation/lidarr-download-automation.bash is still running..."
    exit 1
fi
exit 0
