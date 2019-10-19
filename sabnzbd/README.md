# Script Information
These scripts are designed to be used with sabzbd for post-processing on linux based systems

## Script Usage

1. Download the scripts from this repo
1. Copy the scripts into the configured "Scripts Folder" directory for sabnzbd, see sabnzbd "folders" configuratino page
1. Set the permissions on the file to executable (chmod +x <script_file_name>)
1. Add the post processing script to video download categories

For additional information, visit the following link:
https://sabnzbd.org/wiki/scripts/post-processing-scripts

# Script Descriptions

## MKV-Cleaner.bash
This script removes unwanted audio and subtitle tracks based on configured settings

### Configuration Options
Configuration options are found in the top few lines of the script<br /><br />
**RemoveNonVideoFiles** - Deletes non MKV/MP4/AVI files <br />
**Remux** - Remuxes MKV/MP4/AVI into mkv files and removes unwanted audio/subtitles based on the language preference settings <br />
**PerferredLanguage** - Keeps only the audio for the language selected, if not found, fall-back to unknown tracks and if also not found, a final fall-back to all other audio tracks  <br />
**SubtitleLanguage** - Removes all subtitles not matching specified language <br />
**SetUnknownAudioLanguage** - If enabled, sets found unknown (und) audio tracks to the language in the next setting <br />
**UnkownAudioLanguage** - Sets unknown language tracks to the language specified <br /><br />
Language Preferences require using "ISO 639-2" language codes, list of codes can be found here: https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes

### Requirements
* **mkvtoolnix**

### Compatibility Testing
* Linuxserver.io Sabnzbd Docker (To install requirements, use the mkvtoolnix_install.bash script found here: https://github.com/RandomNinjaAtk/Scripts/tree/master/lso_docker_ubuntu<br />

<hr />

## AudioPostProcessing.bash
This script can verify flac files for corruption, fix errors in mp3 files, transcode flac/alac files to another format, add replaygain tags to flac files

### Configuration Options
Configuration options are found in the top few lines of the script<br /><br />
**RemoveNonAudioFiles** - Deletes non FLAC/M4A/MP3/OPUS/OGG files<br />
**DuplicateFileCleanUp** - Deletes duplicate files, sabnzbd sometimes creates duplicates, or if a download contains both lossless and lossy version, it deletes lossy version <br />
**AudioVerification** -  Verifies FLAC/MP3 files for errors (fixes MP3's, deletes bad FLAC files)<br />
**Convert** - Only converts lossless FLAC/ALAC files to format in the next setting <br />
**ConversionFormat** - SET TO: OPUS or AAC or MP3 or FLAC - converts lossless FLAC files to set format<br />
**Threads** - SET TO: "0" to use maximum number of threads for multi-threaded operations<br />
**ReplaygainTagging** - adds replaygain tags for compatible players (FLAC ONLY)<br />

### Requirements
* **flac**
* **ffmpeg**
* **mp3val**

### Compatibility Testing
* Linuxserver.io Sabnzbd Docker (To install requirements, use the ffmpeg_install.bash & audio_tools_install.bash script found here: https://github.com/RandomNinjaAtk/Scripts/tree/master/lso_docker_ubuntu<br />
