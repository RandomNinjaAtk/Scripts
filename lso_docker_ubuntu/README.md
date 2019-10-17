# Script Information
These scripts are designed to be used with LinuxServer.io Ubuntu based docker containers

## Script Usage

1. Create a "custom-cont-init.d" folder in the "/config/" of your desired ls.io docker container
1. Download the scripts from this repo
1. Copy the scripts into the "/config/custom-cont-init.d/"
1. Restart docker container, scripts will automatically run on startup

For additional information, visit the following link:
https://blog.linuxserver.io/2019/09/14/customizing-our-containers/

## Compatibility Testing
These scripts have been tested to successfully install on the following containers:

1. sabnzbd
1. lidarr
1. sonarr
