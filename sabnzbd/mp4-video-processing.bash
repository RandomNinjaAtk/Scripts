#!/bin/bash

# Download Scripts

if [ ! -f /config/scripts/sickbeard_mp4_automator/Deobfuscate.py ]; then
    echo "downloading Deobfuscate.py from: https://github.com/sabnzbd/sabnzbd/blob/develop/scripts/Deobfuscate.py"
    curl -o /config/scripts/sickbeard_mp4_automator/Deobfuscate.py https://raw.githubusercontent.com/sabnzbd/sabnzbd/develop/scripts/Deobfuscate.py
    echo "done"

    # Set Permissions
    echo "setting permissions..."
    chmod +x /config/scripts/sickbeard_mp4_automator/Deobfuscate.py
    echo "done"
fi

# Execute on new downloads
cd /config/scripts/sickbeard_mp4_automator

# Run sabnzbd Deobfuscation script
timeout --foreground 1m python Deobfuscate.py

# Check for video files, if none found error out
if find "$1" -type f -iregex ".*/.*\.\(mp4\|mkv\|avi\|ts\|mov\|vob\|mpg\|mts\)" | read; then
	echo "REMOVE NON VIDEO FILES"
	find "$1"/* -type f -not -iregex ".*/.*\.\(webvtt\|ass\|srt\|mp4\|mkv\|ts\|avi\|mov\|vob\|mpg\|mts\)" -delete
	echo "REMOVE NON VIDEO FILES COMPLETE"
else
	echo "ERROR: NO VIDEO FILES FOUND"
	exit 1
fi

# Manual run of Sickbeard MP4 Automator
python manual.py -i "$1" -nt
echo "COMPLETE"
