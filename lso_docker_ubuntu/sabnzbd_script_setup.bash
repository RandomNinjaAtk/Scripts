#!/bin/bash
echo "setting up script directory"
if [ ! -d /config/scripts ]; then
  mkdir /config/scripts
  
  # Set Permissions
  echo "setting permissions..."
  chmod 0777 /config/scripts
  echo "done"
else
  echo "scripts directory exists"
fi

# Download Scripts
echo "downloading scripts..."
if [ ! -f /config/scripts/video-processing.bash ]; then
  echo "downloading video-processing.bash from: https://github.com/RandomNinjaAtk/Scripts/blob/master/sabnzbd/video-processing.bash"
  curl -o /config/scripts/video-processing.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/video-processing.bash
  echo "done"

  # Set Permissions
  echo "setting permissions..."
  chmod +x /config/scripts/video-processing.bash
  echo "done"
fi
if [ ! -f /config/scripts/AudioPostProcessing.bash ]; then
  echo "downloading AudioPostProcessing.bash from: https://github.com/RandomNinjaAtk/Scripts/tree/master/sabnzbd/AudioPostProcessing.bash"
  curl -o /config/scripts/AudioPostProcessing.bash https://raw.githubusercontent.com/RandomNinjaAtk/Scripts/master/sabnzbd/AudioPostProcessing.bash
  echo "done"

  # Set Permissions
  echo "setting permissions..."
  chmod +x /config/scripts/AudioPostProcessing.bash
  echo "done"
fi
echo "script downloads complete..."
exit 0
