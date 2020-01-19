## Scripts Usage

#### lsio-automated-installer-updater.bash
Updates and runs the "lsio-automated-installer.bash" script automatically<br />

#### lsio-automated-installer.bash
Script installs and configures all requirements for the: lidarr-automated-downloader.bash found here: https://github.com/RandomNinjaAtk/Scripts/tree/master/lidarr-automated-downloader

## Script Usage

1. Create a "custom-cont-init.d" folder in the "/config/" of your lidarr ls.io docker container
1. Download the scripts from this repo
1. Copy the scripts into the "/config/custom-cont-init.d/"
1. Restart docker container, scripts will automatically run on startup

For additional information, visit the following link:
https://blog.linuxserver.io/2019/09/14/customizing-our-containers/

## Recommendation
Use the lsio-automated-installer-updater.bash script only, this way you get automated updates to your scripts...
