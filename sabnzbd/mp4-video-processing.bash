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

if [ ! -f /config/scripts/sickbeard_mp4_automator/MKV-Cleaner.bash ]; then
    echo "downloading MKV-Cleaner.bash from: https://github.com/RandomNinjaAtk/Scripts/tree/master/sabnzbd/MKV-Cleaner.bash"
    curl -o /config/scripts/sickbeard_mp4_automator/MKV-Cleaner.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/MKV-Cleaner.bash
    echo "done"

    # Set Permissions
    echo "setting permissions..."
    chmod 777 /config/scripts/MKV-Cleaner.bash
    echo "done"
fi

set -e

# Execute on new downloads
cd /config/scripts/sickbeard_mp4_automator

# Run sabnzbd Deobfuscation script
timeout --foreground 1m python Deobfuscate.py

# Run Cleaner before processing wtih mp4 automator
bash MKV-Cleaner.bash "$1"

# Manual run of Sickbeard MP4 Automator
python3 manual.py -i "$1" -nt



echo "COMPLETE"

exit 0
