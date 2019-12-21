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

if find "$1" -type f  -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "Found video files for processing..."
else
	echo "ERROR: NO VIDEO FILES FOUND" && exit 1
fi

#cleanup unwanted files
if find "$1" -type f -not -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "UNWANTED FILES FOUND"
	echo "DELETING NON VIDEO FILES"
	find "$1"/* -type f -not -iregex ".*/.*\.\(webvtt\|ass\|srt\|mkv\|mp4\|avi\)" -delete
	echo "COMPLETE"
fi

#check for required applications
if [ ! -x "$(command -v mkvmerge)" ]; then
	echo "mkvmerge utility not installed" && exit 1
fi

if [ ! -x "$(command -v jq)" ]; then
	echo "jq package not installed" && exit 1
fi
	
#convert mp4 to mkv before language processing
find "$1" -type f -iregex ".*/.*\.\(mp4\)" -print0 | while IFS= read -r -d '' video; do
	echo ""
	echo "=========================="
	echo "PROCESSING $video"
	if timeout 10s mkvmerge -i "$video" > /dev/null; then
		echo "MP4 found, remuxing to mkv before processing audio/subtitles"
		mkvmerge -o "$video.merged.mkv" "$video"
		# cleanup temp files and rename
		mv "$video" "$video.original.mkv" && echo "Renamed source file"
		mv "$video.merged.mkv" "${video/.mp4/.mkv}" && echo "Renamed temp file"
		rm "$video.original.mkv" && echo "Deleted source file"
	else
		echo "MKVMERGE ERROR"
		rm "$video" && echo "DELETED: $video" && exit 1
	fi
	echo "PROCESSING COMPLETE"
	echo "=========================="
	echo ""
done
	
#convert avi to mkv before language processing
find "$1" -type f -iregex ".*/.*\.\(avi\)" -print0 | while IFS= read -r -d '' video; do
	echo ""
	echo "=========================="
	echo "PROCESSING $video"
	if timeout 10s mkvmerge -i "$video" > /dev/null; then
		echo "AVI found, remuxing to mkv before processing audio/subtitles"
		mkvmerge -o "$video.merged.mkv" "$video"
		# cleanup temp files and rename
		mv "$video" "$video.original.mkv" && echo "Renamed source file"
		mv "$video.merged.mkv" "${video/.avi/.mkv}" && echo "Renamed temp file"
		rm "$video.original.mkv" && echo "Deleted source file"
	else
		echo "MKVMERGE ERROR"
		rm "$video" && echo "DELETED: $video" && exit 1
	fi
	echo "PROCESSING COMPLETE"
	echo "=========================="
	echo ""
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
		nonundaudio=$(mkvmerge -J "$video" | jq '.tracks[] | select((.type=="audio") and select(.properties.language!="und")) | .id')
		allaudio=$(mkvmerge -J "$video" | jq ".tracks[] | select(.type==\"audio\") | .id")
		nonperfaudio=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"audio\") and select(.properties.language!=\"${PerferredLanguage}\")) | .id")
		perfsub=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language==\"${SubtitleLanguage}\")) | .id")
		allsub=$(mkvmerge -J "$video" | jq ".tracks[] | select(.type==\"subtitles\") | .id")
		nonperfsub=$(mkvmerge -J "$video" | jq ".tracks[] | select((.type==\"subtitles\") and select(.properties.language!=\"${SubtitleLanguage}\")) | .id")
	else
		echo "MKVMERGE ERROR: FAILED to get values from mkvmerge"
		rm "$video" && echo "DELETED: $video" && exit 1
	fi
	
	# Checking for video
	echo "Checking for video..."
	if test ! -z "$allvideo"; then
		echo "Video found"
	else
		# no video was found, error and report failed to sabnzbd
		echo "ERROR: No video tracks found"
		rm "$video" && echo "DELETED: $video" && exit 1
	fi
		
	# Checking for audio
	echo "Checking for audio..."
	if test ! -z "$allaudio"; then
		echo "Audio found"
	else
		# no audio was found, error and report failed to sabnzbd
		echo "ERROR: No audio tracks found"
		rm "$video" && echo "DELETED: $video" && exit 1
	fi
	
	# Checking for subtitles
	echo "Checking for subtitles..."
	if test ! -z "$allsub"; then
		echo "Subtitles found"
		subtitles="true"
	else
		echo "No subtitles found"
		subtitles="false"
	fi
	
	# Checking for preferred audio
	if test ! -z "$perfaudio"; then
		echo "Checking for \"${PerferredLanguage}\" audio"
		echo "Audio found"
		echo "Checking for unwanted audio"
		setundaudio="false"
		if test ! -z "$nonperfaudio"; then
			echo "Unwanted audio found"
			removeaudio="true"
		else
			echo "No unwanted audio to remove"
			removeaudio="false"
		fi
		
		if [ "${subtitles}" = true ]; then
			echo "Checking for \"${SubtitleLanguage}\" subtitles"
			if test ! -z "$perfsub"; then
				echo "\"${SubtitleLanguage}\" subs found"
				echo "Checking for unwanted subtitles"
				if test ! -z "$nonperfsub"; then
					echo "Unwanted subtitles found"
					removesubs="true"
				else 
					echo "No unwanted subtitles to remove"
					removeasubs="false"
				fi
			fi
		else
			echo "No unwanted subtitles to remove"
			removeasubs="false"
		fi
		echo "Checking video laguange"
		if test ! -z "$nonperfvideo"; then
			echo "Unwanted video lang found"
			setvideolanguage="true"
		else
			echo "No unwanted video lang to change"
			setvideolanguage="false"
		fi
	elif test ! -z "$undaudio"; then
		echo "Checking for \"und\" audio"
		echo "Audio found"
		echo "Checking for unwanted audio"
		setundaudio="true"
		if test ! -z "$nonundaudio"; then
			echo "Unwanted audio found"
			removeaudio="true"
		else 
			echo "No unwanted audio to remove"
			removeaudio="false"
		fi
		if [ "${subtitles}" = true ]; then
			echo "Checking for \"${SubtitleLanguage}\" subtitles"
			if test ! -z "$perfsub"; then
				echo "\"${SubtitleLanguage}\" Subs found"
				echo "Checking for unwanted subtitles"
				if test ! -z "$nonperfsub"; then
					echo "Unwanted subtitles found"
					removesubs="true"
				else 
					echo "No unwanted subtitles to remove"
					removeasubs="false"
				fi
			fi
		else
			echo "No unwanted subtitles to remove"
			removeasubs="false"
		fi
			
		echo "Checking video laguange"
		if test ! -z "$nonperfvideo"; then
			echo "Unwanted video lang found"
			setvideolanguage="true"
		else
			echo "No unwanted video lang to change"
			setvideolanguage="false"
		fi
	elif test ! -z "$allaudio"; then
		echo "Audio tracks found"
		echo "Checking for \"${SubtitleLanguage}\" subtitles"
		if test ! -z "$perfsub"; then
			echo "\"${SubtitleLanguage}\" Subs found"
			echo "Checking for unwanted subtitles"
			if test ! -z "$nonperfsub"; then
				echo "Unwanted subtitles found"
				removesubs="true"
			else 
				echo "No unwanted subtitles to remove"
				removeasubs="false"
			fi
			echo "Skipping unwanted audo check"
			echo "Skip setting video language"
			removeaudio="false"
			setundaudio="false"
			setvideolanguage="false"
		else
			echo "ERROR: \"${SubtitleLanguage}\" Subtitle not found, only foreign audio/subtitles found"
			echo "Deleting video and marking download as failed because no usuable audio/subititles are found in requested langauge"
			rm "$video" && echo "DELETED: $video" && exit 1
		fi
	fi
	
	if [ "${removeaudio}" = false ] && [ "${setundaudio}" = false ] && [ "${removeasubs}" = false ] && [ "${setvideolanguage}" = false ]; then
		echo "Video passed all checks"
	else
		
		if [ "${setundaudio}" = true ]; then
			mkvaudio="-a $undaudio --language $undaudio:${UnkownAudioLanguage}"
		else
			if [ "${removeaudio}" = true ]; then
				mkvaudio="-a ${PerferredLanguage}"
			else
				mkvaudio=""
			fi
		fi

		if [ "${removesubs}" = true ]; then
			mkvsubs="-s ${SubtitleLanguage}"
		else
			mkvsubs=""
		fi

		if [ "${setvideolanguage}" = true ]; then
			mkvvideo="-d ${nonperfvideo} --language ${nonperfvideo}:${PerferredLanguage}"
		else
			mkvvideo=""
		fi
		
		if mkvmerge --no-global-tags --title "" -o "$video.merged.mkv" ${mkvvideo} ${mkvaudio} ${mkvsubs} "$video"; then
			echo "MKVMERGE SUCCESS"
			echo "Options used: ${mkvvideo} ${mkvaudio} ${mkvsubs}"
		elif [ "${setundaudio}" = true ]; then
			echo "ERROR setting und audio to \"${PerferredLanguage}\" , skipping language setting"
			if mkvmerge --no-global-tags --title "" -o "$video.merged.mkv" ${mkvvideo} -a und ${mkvsubs} "$video"; then
				echo "MKVMERGE SUCCESS"
				echo "Options used: ${mkvvideo} -a und ${mkvsubs}"
			else
				echo "ERROR: MKVMERGE FAILURE" && exit 1
			fi
		fi
		# cleanup temp files and rename
		mv "$video" "$video.original.mkv" && echo "Renamed source file"
		mv "$video.merged.mkv" "$video" && echo "Renamed temp file"
		rm "$video.original.mkv" && echo "Deleted source file"

	fi
	echo "PROCESSING COMPLETE"
	echo "=========================="
	echo ""
done

echo "VIDEO PROCESSING COMPLETE"

# script complete, now exiting
exit 0
