# Script Information
These scripts are designed to be used with LinuxServer.io Ubuntu based docker containers

## Script Descriptions

#### ffmpeg_install.bash
Compiles and installs ffmpeg

#### mkvtoolnix_install.bash
Installs mkvtoolnix

#### audio_tools_install.bash
Installs mp3val, flac

#### mp4_automator.bash
Installs mp4 automator script to the following location: /config/scripts/sickbeard_mp4_automator<br />
###### Important:
Do not use inconjuction with the mkvtoolnix_install.bash and ffmpeg_install.bash script. This script will also install both utlities

#### sabnzbd_script_setup.bash
Automatically downloads and installs sabnzbd post processing scripts found here: https://github.com/RandomNinjaAtk/Scripts/tree/master/sabnzbdr<br />
###### Important:
1. You need to use ffmpeg_install.bash, mkvtoolnix_install.bash, audio_tools_install.bash for full functionality. 
2. After initial run of the script, configure sabnzbd to point to the scripts directory location "/config/scripts"

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
