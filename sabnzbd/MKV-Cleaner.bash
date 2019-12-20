#!/bin/bash
#######################################
#    MKV Audio & Subtitle Cleanup     #
#             Bash Script             #
#            Version 1.0.1            #
#######################################
#            Description:             #
#  This script removes unwated audio  #
#  and subtitles based on configured  #
#  preferences...                     #
#=============REQUIREMENTS=============
#        mkvtoolsnix (mkvmerge)       #
#============CONFIGURATION=============
RemoveNonVideoFiles="TRUE" # TRUE = ENABLED, Deletes non MKV/MP4/AVI files
Remux="TRUE" # TRUE = ENABLED, Remuxes MKV/MP4/AVI into mkv files and removes unwanted audio/subtitles based on the language preferences in the next few settings
PerferredLanguage="eng" # Keeps only the audio for the language selected, if not found, fall-back to unknown tracks and if also not found, a final fall-back to all other audio tracks
SubtitleLanguage="eng" # Removes all subtitles not matching specified language
SetUnknownAudioLanguage="TRUE" # TRUE = ENABLED, if enabled, sets found unknown (und) audio tracks to the language in the next setting
UnkownAudioLanguage="eng" # Sets unknown language tracks to the language specified
#===============FUNCTIONS==============

clean () {
	if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
		echo "REMOVE NON VIDEO FILES"
		find "$1"/* -type f -not -iregex ".*/.*\.\(webvtt\|ass\|srt\|mkv\|mp4\|avi\)" -delete
		echo "REMOVE NON VIDEO FILES COMPLETE"
	else
		echo "ERROR: NO VIDEO FILES FOUND"
		exit 1
	fi
}

remux () {
	# Removing previously unfinished operations
	find "$1"/* -type f -name "*.merged.mkv" -delete
	find "$1"/* -type f -name "*.original.mkv" -delete
	
	movies=($(find "$1" -type f -iregex ".*/.*\.\(mp4\)"))
	for movie in "${movies[@]}"; do
		if timeout 10s mkvmerge -i "$movie" > /dev/null; then
			echo "MP4 found, remuxing to mkv before processing audio/subtitles"
			mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" "$movie"
			# cleanup temp files and rename
			mv "$movie" "$movie.original.mkv" && echo "Renamed source file"
			mv "$movie.merged.mkv" "${movie/.mp4/.mkv}" && echo "Renamed temp file"
			rm "$movie.original.mkv" && echo "Deleted source file"
		else
			echo "MKVMERGE ERROR"
			rm "$movie" && echo "DELETED: $movie"
		fi
	done

	movies=($(find "$1" -type f -iregex ".*/.*\.\(avi\)"))
	for movie in "${movies[@]}"; do
		if timeout 10s mkvmerge -i "$movie" > /dev/null; then
			echo "AVI found, remuxing to mkv before processing audio/subtitles"
			mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" "$movie"
			# cleanup temp files and rename
			mv "$movie" "$movie.original.mkv" && echo "Renamed source file"
			mv "$movie.merged.mkv" "${movie/.avi/.mkv}" && echo "Renamed temp file"
			rm "$movie.original.mkv" && echo "Deleted source file"
		else
			echo "MKVMERGE ERROR"
			rm "$movie" && echo "DELETED: $movie"
		fi
	done

	# Finding Preferred Language
	movies=($(find "$1" -type f -iregex ".*/.*\.\(mkv\)"))
	for movie in "${movies[@]}"; do
		echo ""
		echo "=========================="
		echo "PROCESSING $movie"
		if timeout 10s mkvmerge -i "$movie" > /dev/null; then
			perfaudio=$(mkvmerge -J "$movie" | jq ".tracks[] | select((.type==\"audio\") and select(.properties.language==\"${PerferredLanguage}\")) | .id")
			undaudio=$(mkvmerge -J "$movie" | jq '.tracks[] | select((.type=="audio") and select(.properties.language=="und")) | .id')
			allaudio=$(mkvmerge -J "$movie" | jq ".tracks[] | select((.type==\"audio\") and select(.properties.language!=\"${PerferredLanguage}\")) | .id")
			perfsub=$(mkvmerge -J "$movie" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language==\"${SubtitleLanguage}\")) | .id")
			allsub=$(mkvmerge -J "$movie" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language!=\"${SubtitleLanguage}\")) | .id")

			# Setting Audio language for mkvmerge
			if test ! -z "$perfaudio"; then
				# If preferred found, use it
				audio="${PerferredLanguage}"
				echo "Begin search for preferred \"${PerferredLanguage}\" audio"
				if test ! -z "$allaudio"; then
					echo "\"${audio}\" Audio Found"
					echo "Removing unwanted audio and subtitle tracks"
					echo "Creating temporary file: $movie.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a ${PerferredLanguage} -s ${SubtitleLanguage} "$movie"
					# cleanup temp files and rename
					mv "$movie" "$movie.original.mkv" && echo "Renamed source file"
					mv "$movie.merged.mkv" "$movie" && echo "Renamed temp file"
					rm "$movie.original.mkv" && echo "Deleted source file"
				else
					echo "\"${audio}\" Audio Found, No unwanted audio languages to remove"
					if test ! -z "$allsub"; then
						echo "Unwanted subtitles found, removing unwanted subtitles"
						echo "Creating temporary file: $movie.merged.mkv"
						mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a ${PerferredLanguage} -s ${SubtitleLanguage} "$movie"
						# cleanup temp files and rename
						mv "$movie" "$movie.original.mkv" && echo "Renamed source file"
						mv "$movie.merged.mkv" "$movie" && echo "Renamed temp file"
						rm "$movie.original.mkv" && echo "Deleted source file"
					else
						echo "\"${SubtitleLanguage}\" Subtitle Found, No unwanted subtitle languages to remove"
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
					echo "Creating temporary file: $movie.merged.mkv"
					if mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a $undaudio --language $undaudio:${UnkownAudioLanguage} -s ${SubtitleLanguage} "$movie"; then
						echo "SUCCESS"
					else
						echo "ERROR, skipping language setting"
						mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a und -s ${SubtitleLanguage} "$movie";
					fi
				else
					echo "SetUnknownAudioLanguage not enabled, skipping unknown audio language tag modification"
					echo "Removing unwanted audio and subtitle tracks"
					echo "Creating temporary file: $movie.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a und -s ${SubtitleLanguage} "$movie"
				fi
				# cleanup temp files and rename
				mv "$movie" "$movie.original.mkv" && echo "Renamed source file"
				mv "$movie.merged.mkv" "$movie" && echo "Renamed temp file"
				rm "$movie.original.mkv" && echo "Deleted source file"
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
					rm "$movie" && echo "DELETED: $movie"
					exit 1
				elif test ! -z "$perfsub"; then
					echo "Unwanted subtitles found, removing unwanted subtitles"
					echo "Creating temporary file: $movie.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a $allaudio -s ${SubtitleLanguage} "$movie"
					# cleanup temp files and rename
					mv "$movie" "$movie.original.mkv" && echo "Renamed source file"
					mv "$movie.merged.mkv" "$movie" && echo "Renamed temp file"
					rm "$movie.original.mkv" && echo "Deleted source file"
				else
					echo "\"${SubtitleLanguage}\" Subtitle Found, No unwanted subtitle languages to remove"
				fi
			else
				# no audio was found, error and report failed to sabnzbd
				echo "No audio tracks found"
				rm "$movie" && echo "DELETED: $movie"
				exit 1
			fi
			echo "PROCESSING COMPLETE"
			echo "=========================="
			echo ""
		else
			echo "MKVMERGE ERROR"
			rm "$movie" && echo "DELETED: $movie"
			exit 1
		fi
	done
	echo "VIDEO PROCESSING COMPLETE"
}

# start cleanup if enabled
if [ "${RemoveNonVideoFiles}" = TRUE ]; then
	clean "$1"
fi

# start Remux if enabled
if [ "${Remux}" = TRUE ]; then
	if [ -x "$(command -v mkvmerge)" ]; then
		if [ -x "$(command -v jq)" ]; then
			if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
				remux "$1"
			else
				echo "ERROR: NO VIDEO FILES FOUND"
				exit 1
			fi
		else
			echo "jq package not installed" && exit 1
		fi
	else
		echo "mkvmerge utility not installed" && exit 1
	fi
fi

# script complete, now exiting
exit 0
