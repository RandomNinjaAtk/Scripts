#!/bin/bash

# Download Scripts

if [ ! -f /config/scripts/Deobfuscate.py ]; then
    echo "downloading Deobfuscate.py from: https://github.com/sabnzbd/sabnzbd/blob/develop/scripts/Deobfuscate.py"
    curl -o /config/scripts/Deobfuscate.py https://raw.githubusercontent.com/sabnzbd/sabnzbd/develop/scripts/Deobfuscate.py
    echo "done"

    # Set Permissions
    echo "setting permissions..."
    chmod +x /config/scripts/Deobfuscate.py
    echo "done"
fi

# Execute on new downloads
cd /config/scripts
timeout --foreground 1m python Deobfuscate.py
python manual.py -i "$1" -nt
