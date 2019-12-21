#!/bin/bash
#######################################
#    MKV Audio & Subtitle Cleanup     #
#             Bash Script             #
#            Version 1.2.0            #
#######################################
#            Description:             #
#  This script removes unwated audio  #
#  and subtitles based on configured  #
#  preferences...                     #
#=============REQUIREMENTS=============
#        mkvtoolsnix (mkvmerge)       #
#============CONFIGURATION=============
PerferredLanguage="eng" # Keeps only the audio for the language selected, if not found, fall-back to unknown tracks and if also not found, a final fall-back to all other audio tracks
SubtitleLanguage="eng" # Removes all subtitles not matching specified language
SetUnknownAudioLanguage="TRUE" # TRUE = ENABLED, if enabled, sets found unknown (und) audio tracks to the language in the next setting
UnkownAudioLanguage="eng" # Sets unknown language tracks to the language specified
#===============FUNCTIONS==============

#cleanup unwanted files
if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "REMOVE NON VIDEO FILES"
	find "$1"/* -type f -not -iregex ".*/.*\.\(webvtt\|ass\|srt\|mkv\|mp4\|avi\)" -delete
	echo "REMOVE NON VIDEO FILES COMPLETE"
else
	echo "ERROR: NO VIDEO FILES FOUND" && exit 1
fi

#check for required applications
if [ ! -x "$(command -v mkvmerge)" ]; then
	echo "mkvmerge utility not installed" && exit 1
fi

if [ ! -x "$(command -v jq)" ]; then
	echo "jq package not installed" && exit 1
fi

#begin remux to mkv based on language preferences
if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	
	#convert mp4 to mkv before language processing
	find "$1" -type f -iregex ".*/.*\.\(mp4\)" -print0 | while IFS= read -r -d '' video; do
		if timeout 10s mkvmerge -i "$video" > /dev/null; then
			echo "MP4 found, remuxing to mkv before processing audio/subtitles"
			mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" "$video"
			# cleanup temp files and rename
			mv "$video" "$video.original.mkv" && echo "Renamed source file"
			mv "$video.merged.mkv" "${video/.mp4/.mkv}" && echo "Renamed temp file"
			rm "$video.original.mkv" && echo "Deleted source file"
		else
			echo "MKVMERGE ERROR"
			rm "$video" && echo "DELETED: $video"
		fi
	done
	
	#convert avi to mkv before language processing
	find "$1" -type f -iregex ".*/.*\.\(avi\)" -print0 | while IFS= read -r -d '' video; do
		if timeout 10s mkvmerge -i "$video" > /dev/null; then
			echo "AVI found, remuxing to mkv before processing audio/subtitles"
			mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" "$video"
			# cleanup temp files and rename
			mv "$video" "$video.original.mkv" && echo "Renamed source file"
			mv "$video.merged.mkv" "${vdieo/.avi/.mkv}" && echo "Renamed temp file"
			rm "$video.original.mkv" && echo "Deleted source file"
		else
			echo "MKVMERGE ERROR"
			rm "$video" && echo "DELETED: $video"
		fi
	done
		
	# Finding Preferred Language
	find "$1" -type f -iregex ".*/.*\.\(mkv\)" -print0 | while IFS= read -r -d '' video; do
		echo ""
		echo "=========================="
		echo "PROCESSING $video"
		if timeout 10s mkvmerge -i "$video" > /dev/null; then
			perfvideo=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"video\") and select(.properties.language==\"${PerferredLanguage}\")) | .id")
			allvideo=$(mkvmerge -J "$video" | jq ".tracks[] | select(.type==\"video\") | .id")
			nonperfvideo=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"video\") and select(.properties.language!=\"${PerferredLanguage}\")) | .id")
			perfaudio=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"audio\") and select(.properties.language==\"${PerferredLanguage}\")) | .id")
			undaudio=$(mkvmerge -J "$video" | jq '.tracks[] | select((.type=="audio") and select(.properties.language=="und")) | .id')
			allaudio=$(mkvmerge -J "$video" | jq ".tracks[] | select(.type==\"audio\") | .id")
			nonperfaudio=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"audio\") and select(.properties.language!=\"${PerferredLanguage}\")) | .id")
			perfsub=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language==\"${SubtitleLanguage}\")) | .id")
			allsub=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language!=\"${SubtitleLanguage}\")) | .id")

			# Setting Audio language for mkvmerge
			if test ! -z "$allaudio"; then
				# If preferred found, use it
				audio="${PerferredLanguage}"
				echo "Begin search for preferred \"${PerferredLanguage}\" audio"
				if test ! -z "$nonperfaudio"; then
					echo "\"${audio}\" Audio Found"
					echo "Removing unwanted audio and subtitle tracks"
					echo "Creating temporary file: $video.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" -d ${allvideo} --language ${allvideo}:${PerferredLanguage} -a ${PerferredLanguage} -s ${SubtitleLanguage} "$video"
					# cleanup temp files and rename
					mv "$video" "$video.original.mkv" && echo "Renamed source file"
					mv "$video.merged.mkv" "$video" && echo "Renamed temp file"
					rm "$video.original.mkv" && echo "Deleted source file"
				else
					echo "\"${audio}\" Audio Found, No unwanted audio languages to remove"
					if test ! -z "$allsub"; then
						echo "Unwanted subtitles found, removing unwanted subtitles"
						echo "Creating temporary file: $video.merged.mkv"
						mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" -d ${allvideo} --language ${allvideo}:${PerferredLanguage} -a ${PerferredLanguage} -s ${SubtitleLanguage} "$video"
						# cleanup temp files and rename
						mv "$video" "$video.original.mkv" && echo "Renamed source file"
						mv "$video.merged.mkv" "$video" && echo "Renamed temp file"
						rm "$video.original.mkv" && echo "Deleted source file"
					elif test ! -z "$nonperfvideo"; then
						echo "\"${SubtitleLanguage}\" Subtitle Found, No unwanted subtitle languages to remove"
						echo "Setting video language to match \"${PerferredLanguage}\" language"
						mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" -d ${allvideo} --language ${allvideo}:${PerferredLanguage} -a ${PerferredLanguage} -s ${SubtitleLanguage} "$video"
						# cleanup temp files and rename
						mv "$video" "$video.original.mkv" && echo "Renamed source file"
						mv "$video.merged.mkv" "$video" && echo "Renamed temp file"
						rm "$video.original.mkv" && echo "Deleted source file"
					else
						echo "\"${SubtitleLanguage}\" Subtitle Found, No unwanted subtitle languages to remove"
						echo "\"${PerferredLanguage}\" Video Found, no video languages to adjust"
					fi
				fi
			elif test ! -z "$undaudio"; then
				# If preferred not found, use unknown audio
				audio="uknown (und)"
				echo "No preferred \"${PerferredLanguage}\" audio tracks found"
				echo "Begin search for \"unknown (und)\" audio tracks"
				echo "Found \"unknown (und)\" Audio"
				# Set unknown (und) audio laguange to specified language if enabled
				if [ "${SetUnknownAudioLanguage}" = TRUE ]; then
					echo "Setting Unknown (und) audio language to \"${UnkownAudioLanguage}\""
					echo "Removing unwanted audio and subtitle tracks"
					echo "Creating temporary file: $video.merged.mkv"
					if mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" -d ${allvideo} --language ${allvideo}:${PerferredLanguage} -a $undaudio --language $undaudio:${UnkownAudioLanguage} -s ${SubtitleLanguage} "$video"; then
						echo "SUCCESS"
					else
						echo "ERROR, skipping language setting"
						mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" -d ${allvideo} --language ${allvideo}:${PerferredLanguage} -a und -s ${SubtitleLanguage} "$video";
					fi
				else
					echo "SetUnknownAudioLanguage not enabled, skipping unknown audio language tag modification"
					echo "Removing unwanted audio and subtitle tracks"
					echo "Creating temporary file: $video.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" -d ${allvideo} --language ${allvideo}:${PerferredLanguage} -a und -s ${SubtitleLanguage} "$video"
				fi
				# cleanup temp files and rename
				mv "$video" "$video.original.mkv" && echo "Renamed source file"
				mv "$video.merged.mkv" "$video" && echo "Renamed temp file"
				rm "$video.original.mkv" && echo "Deleted source file"
			elif test ! -z "$allaudio"; then
				# If preferred and unknown not found, pass-through remaining audio tracks
				audio="all"
				echo "No preferred \"${PerferredLanguage}\" audio tracks found"
				echo "Begin search for \"unknown (und)\" audio tracks"
				echo "No \"unknown (und)\" audio tracks found"
				echo "Begin search for all other audio tracks"
				echo "Audio Detected, keeping all other audio tracks..."
				if test ! -z "$allsub"; then
					echo "ERROR: \"${SubtitleLanguage}\" Subtitle not found, only foreign audio/subtitles found"
					echo "Deleting video and marking download as failed because no usuable audio/subititles are found in requested langauge"
					rm "$video" && echo "DELETED: $video" && exit 1
				elif test ! -z "$perfsub"; then
					echo "Unwanted subtitles found, removing unwanted subtitles"
					echo "Creating temporary file: $video.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$video.merged.mkv" -a $allaudio -s ${SubtitleLanguage} "$video"
					# cleanup temp files and rename
					mv "$video" "$video.original.mkv" && echo "Renamed source file"
					mv "$video.merged.mkv" "$video" && echo "Renamed temp file"
					rm "$video.original.mkv" && echo "Deleted source file"
				else
					echo "\"${SubtitleLanguage}\" Subtitle Found, No unwanted subtitle languages to remove"
				fi
			else
				# no audio was found, error and report failed to sabnzbd
				echo "No audio tracks found"
				rm "$video" && echo "DELETED: $video" && exit 1
			fi
			echo "PROCESSING COMPLETE"
			echo "=========================="
			echo ""
		else
			echo "MKVMERGE ERROR"
			rm "$video" && echo "DELETED: $video" && exit 1
		fi
	done
else
	echo "ERROR: NO VIDEO FILES FOUND" && exit 1
fi

echo "VIDEO PROCESSING COMPLETE"

# script complete, now exiting
exit 0
