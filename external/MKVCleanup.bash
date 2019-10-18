#!/bin/bash
#######################################
#    MKV Audio & Subtitle Cleanup     #
#             Bash Script             #
#            Version 1.0.0            #
#######################################
#            Description:             #
#  This script removes unwated audio  #
#  and subtitles based on configured  #
#  preferences...                     #
#=============REQUIREMENTS=============
#        mkvtoolsnix (mkvmerge)       #
#============CONFIGURATION=============
StartingDirectory="/starting/file/path"
DestinationDirectory="/destination/file/path"
MoveToDestination="FALSE" # TRUE = ENABLED, moves files to destination directory, set to FALSE to keep in same location
RemoveNonVideoFiles="FALSE" # TRUE = ENABLED, Deletes non MKV/MP4/AVI files
Remux="TRUE" # TRUE = ENABLED, Remuxes MKV/MP4/AVI into mkv files and removes unwanted audio/subtitles based on the language preferences in the next few settings
PerferredLanguage="eng" # Keeps only the audio for the language selected, if not found, fall-back to unknown tracks and if also not found, a final fall-back to all other audio tracks
SubtitleLanguage="eng" # Removes all subtitles not matching specified language
SetUnknownAudioLanguage="TRUE" # TRUE = ENABLED, if enabled, sets found unknown (und) audio tracks to the language in the next setting
UnkownAudioLanguage="eng" # Sets unknown language tracks to the language specified
#===============FUNCTIONS==============

clean () {
	if find "$1" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
		echo "REMOVE NON VIDEO FILES"
		find "$1"/* -type f -not -iregex ".*/.*\.\(mkv\|mp4\|avi\)" -delete
		echo "REMOVE NON VIDEO FILES COMPLETE"
	else
		echo "ERROR: NO VIDEO FILES FOUND"
	fi
}

remux () {
OLDIFS=$IFS
IFS='
'
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
			file=$(mkvmerge --identify-verbose "$movie" | tail --lines=+2)
			track_ids_string=""
			found_languages=()
			track_ids_stringa=""
			found_languagesa=()
			track_ids_stringb=""
			found_languagesb=()
			for track in $file; do
				track_id=""
				[[ "$track" =~ Track\ ID\ ([0-9]+) ]] &&
					track_id=${BASH_REMATCH[1]}
				[[ "$track" =~ language:([a-z]+) ]] &&
					language=${BASH_REMATCH[1]}
				[[ "$track" =~ Track\ ID\ [0-9]+:\ ([a-z]*) ]] &&
					track_type=${BASH_REMATCH[1]}

				if [[ "$track_id" == "" ]]; then
					continue
				fi

				if [[ "$track_type" != "audio" ]]; then
					continue
				fi

				if [[ "$language" == "$PerferredLanguage" ]]; then
					track_ids_string="$track_ids_string,$track_id"
				else
					found_languages+=("$language")
				fi
				
				if [[ "$language" == "und" ]]; then
					track_ids_stringa="$track_ids_stringa,$track_id"
				else
					found_languagesa+=("$language")
				fi
				
				if [[ "$language" != "$PerferredLanguage" ]]; then
					track_ids_stringb="$track_ids_stringb,$track_id"
				else
					found_languagesb+=("$language")
				fi
				
			done    
			track_ids_string=${track_ids_string:1} # remove first comma
			track_ids_stringa=${track_ids_stringa:1} # remove first comma
			track_ids_stringb=${track_ids_stringb:1} # remove first comma 

			# Subtitle Language
			file=$(mkvmerge --identify-verbose "$movie" | tail --lines=+2)
			track_ids_stringsub=""
			found_languagessub=()
			for tracksub in $file; do
				track_idsub=""
				[[ "$tracksub" =~ Track\ ID\ ([0-9]+) ]] &&
					track_idsub=${BASH_REMATCH[1]}
				[[ "$tracksub" =~ language:([a-z]+) ]] &&
					languagesub=${BASH_REMATCH[1]}
				[[ "$tracksub" =~ Track\ ID\ [0-9]+:\ ([a-z]*) ]] &&
					track_typesub=${BASH_REMATCH[1]}

				if [[ "$track_idsub" == "" ]]; then
					continue
				fi

				if [[ "$track_typesub" != "subtitles" ]]; then
					continue
				fi

				if [[ "$languagesub" != "$SubtitleLanguage" ]]; then
					track_ids_stringsub="$track_ids_stringsub,$track_idsub"
				else
					found_languagessub+=("$languagesub")
				fi
			done    
			track_ids_stringsub=${track_ids_stringsub:1} # remove first comma
			
			# Setting Audio language for mkvmerge
			if test ! -z "$track_ids_string"; then
				# If preferred found, use it
				audio_track_ids="$track_ids_string"
				audio="${PerferredLanguage}"
				echo "Begin search for preferred \"${PerferredLanguage}\" audio"
				if test ! -z "$track_ids_stringb"; then
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
					if test ! -z "$track_ids_stringsub"; then
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
			elif test ! -z "$track_ids_stringa"; then
				# If preferred not found, use unknown audio
				audio_track_ids="$track_ids_stringa"
				audio="uknown (und)"
				echo "No preferred \"${PerferredLanguage}\" audio tracks found"
				echo "Begin search for \"unknown (und)\" audio tracks"
				echo "Found \"unknown (und)\" Audio"
				# Set unknown (und) audio laguange to specified language if enabled
				if [ "${SetUnknownAudioLanguage}" = TRUE ]; then
					echo "Setting Unknown (und) audio language to \"${UnkownAudioLanguage}\""
					echo "Removing unwanted audio and subtitle tracks"
					echo "Creating temporary file: $movie.merged.mkv"
					if mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a $audio_track_ids --language $audio_track_ids:${UnkownAudioLanguage} -s ${SubtitleLanguage} "$movie"; then
						echo "SUCCESS"
					else
						echo "ERROR, skipping language setting"
						mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a $audio_track_ids -s ${SubtitleLanguage} "$movie";
					fi
				else
					echo "SetUnknownAudioLanguage not enabled, skipping unknown audio language tag modification"
					echo "Removing unwanted audio and subtitle tracks"
					echo "Creating temporary file: $movie.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a $audio_track_ids -s ${SubtitleLanguage} "$movie"
				fi
				# cleanup temp files and rename
				mv "$movie" "$movie.original.mkv" && echo "Renamed source file"
				mv "$movie.merged.mkv" "$movie" && echo "Renamed temp file"
				rm "$movie.original.mkv" && echo "Deleted source file"
			elif test ! -z "$track_ids_stringb"; then
				# If preferred and unknown not found, pass-through remaining audio tracks
				audio_track_ids="$track_ids_stringb"
				audio="all"
				echo "No preferred \"${PerferredLanguage}\" audio tracks found"
				echo "Begin search for \"unknown (und)\" audio tracks"
				echo "No \"unknown (und)\" audio tracks found"
				echo "Begin search for all other audio tracks"
				echo "Audio Detected, keeping all other audio tracks..."
				if test ! -z "$track_ids_stringsub"; then
					echo "Unwanted subtitles found, removing unwanted subtitles"
					echo "Creating temporary file: $movie.merged.mkv"
					mkvmerge --no-global-tags --default-language ${PerferredLanguage} --title "" -o "$movie.merged.mkv" -a $audio_track_ids -s ${SubtitleLanguage} "$movie"
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
			fi
			echo "PROCESSING COMPLETE"
			echo "=========================="
			echo ""
		else
			echo "MKVMERGE ERROR"
			rm "$movie" && echo "DELETED: $movie"
		fi
	done
	echo "VIDEO PROCESSING COMPLETE"
	IFS=$OLDIFS
}

files="${StartingDirectory}"
for f in "$files"/*; do
	# start cleanup if enabled
	if [ "${RemoveNonVideoFiles}" = TRUE ]; then
		clean "$f"
	fi

	# start remux if enabled
	if [ "${Remux}" = TRUE ]; then
		if [ -x "$(command -v mkvmerge)" ]; then
			if find "$f" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
				remux "$f"
			else
				echo "ERROR: NO VIDEO FILES FOUND TO PROCESS"
			fi
		else
			echo "mkvmerge utility not installed"
		fi
	fi
	if [ "${MoveToDestination}" = TRUE ]; then
		if find "$f" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
			mv "$f" "${DestinationDirectory}"/ && echo "SUCCESS, moved $f to ${DestinationDirectory}"
		else
			echo "ERROR: NO VIDEO FILES FOUND"
		fi
	else
		echo "MoveToDestination setting disabled, leaving files in place"
	fi
done


# script complete, now exiting
exit 0


files="${StartingDirectory}"
for f in "$files"/*; do
	# start cleanup if enabled
	if [ "${RemoveNonVideoFiles}" = TRUE ]; then
		clean "$f"
	fi

	# start remux if enabled
	if [ "${Remux}" = TRUE ]; then
		if [ -x "$(command -v mkvmerge)" ]; then
			if find "$f" -type f -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
				remux "$f"
			else
				echo "ERROR: NO VIDEO FILES FOUND"
			fi
		else
			echo "mkvmerge utility not installed"
		fi
	fi
	if [ "${MoveToDestination}" = TRUE ]; then
		mv "$f" "${DestinationDirectory}"/ && echo "SUCCESS, moved $f to ${DestinationDirectory}"
	else
		echo "MoveToDestination setting disabled, leaving files in place"
	fi
done


# script complete, now exiting
exit 0
