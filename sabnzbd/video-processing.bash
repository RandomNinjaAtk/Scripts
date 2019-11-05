#!/bin/bash
cd /config/scripts

# Download Scripts
if [ ! -f /config/scripts/MKV-Cleaner.bash]; then
    curl -o MKV-Cleaner.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/MKV-Cleaner.bash
fi
if [ ! -f /config/scripts/Deobfuscate.py]; then
    curl -o Deobfuscate.py https://raw.githubusercontent.com/sabnzbd/sabnzbd/develop/scripts/Deobfuscate.py
fi

# Set Permissions
chmod +x Deobfuscate.py
chmod +x MKV-Cleaner.bash

# Execute on new downloads
timeout --foreground 1m python Deobfuscate.py
./MKV-Cleaner.bash "$1"
