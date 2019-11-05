#!/bin/bash
if [ ! -d /config/scripts]; then
  mkdir /config/scripts
  chmod 0777 /config/scripts
else
  echo "scripts directory exists"
fi

# Download Scripts
if [ ! -f /config/scripts/video-processing.bash]; then
  curl -o /config/scripts/video-processing.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/video-processing.bash
  # Set Permissions
  chmod +x /config/scripts/video-processing.bash
fi
if [ ! -f /config/scripts/Deobfuscate.py]; then
  curl -o /config/scripts/AudioPostProcessing.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/AudioPostProcessing.bash
  # Set Permissions
  chmod +x /config/scripts/AudioPostProcessing.bash
fi
exit 0
