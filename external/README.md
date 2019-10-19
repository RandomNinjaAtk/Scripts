# Script Information
These scripts are designed to be used  on linux based systems

## Script Usage

1. Download the scripts from this repo
1. Set the permissions on the file to executable (chmod +x <script_file_name>)
1. Run scipt by executing it (bash <script_file_name> or ./<script_file_name>)

# Script Descriptions

## MKVCleanup.bash
This script removes unwanted audio and subtitle tracks based on configured settings

### Configuration Options
Configuration options are found in the top few lines of the script<br /><br />
**StartingDirectory** - File path to start recursive video file processing <br />
**DestinationDirectory** - File path to move completed files, only used if next setting is set to enable it <br />
**MoveToDestination** - Moves files to destination directory, set to FALSE to keep in same location <br />
**RemoveNonVideoFiles** - Deletes non MKV/MP4/AVI files <br />
**Remux** - Remuxes MKV/MP4/AVI into mkv files and removes unwanted audio/subtitles based on the language preference settings <br />
**PerferredLanguage** - Keeps only the audio for the language selected, if not found, fall-back to unknown tracks and if also not found, a final fall-back to all other audio tracks  <br />
**SubtitleLanguage** - Removes all subtitles not matching specified language <br />
**SetUnknownAudioLanguage** - If enabled, sets found unknown (und) audio tracks to the language in the next setting <br />
**UnkownAudioLanguage** - Sets unknown language tracks to the language specified <br /><br />
Language Preferences require using "ISO 639-2" language codes, list of codes can be found here: https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes

### Requirements
**mkvtoolnix**
(if using linuxserver.io docker, use mkvtoolnix_install.bash script found here: https://github.com/RandomNinjaAtk/Scripts/tree/master/lso_docker_ubuntu<br />
