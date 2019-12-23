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
#                  jq                 #
#============CONFIGURATION=============
PerferredLanguage="eng" # Keeps only the audio for the language selected, if not found, fall-back to unknown tracks and if also not found, a final fall-back to all other audio tracks
SubtitleLanguage="eng" # Removes all subtitles not matching specified language
SetUnknownAudioLanguage="true" # true = ENABLED, if enabled, sets found unknown (und) audio tracks to the language in the next setting
UnkownAudioLanguage="eng" # Sets unknown language tracks to the language specified
#===============FUNCTIONS==============

echo ""
echo "=========================="
if find "$1" -type f  -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "CHECK: Finding video files for processing..."
	echo "SUCCESS: Video files found"
else
	echo "ERROR: No video files found for processing"
	exit 1
fi
echo "=========================="
echo ""

#cleanup unwanted files
echo ""
echo "=========================="
if find "$1" -type f -not -iregex ".*/.*\.\(mkv\|mp4\|avi\)" | read; then
	echo "CHECK: Searching for unwanted files"
	echo "SUCCESS: Unwanted files found"
	echo "INFO: Deleting unwanted file types"
	find "$1"/* -type f -not -iregex ".*/.*\.\(webvtt\|ass\|srt\|mkv\|mp4\|avi\)" -delete
	echo "INFO: Complete"
fi
echo "=========================="
echo ""

#check for required applications
echo ""
echo "=========================="
echo "INFO: Begin checking requirements"
echo "CHECK: for mkvmerge utility"
if [ ! -x "$(command -v mkvmerge)" ]; then
	echo "ERROR: mkvmerge utility not installed" && exit 1
else
	echo "SUCCESS: mkvmerge installed"
fi
echo ""
echo "CHECK: for jq utility"
if [ ! -x "$(command -v jq)" ]; then
	echo "ERROR: jq package not installed" && exit 1
else
	echo "SUCCESS: mkvmerge installed"
fi
echo "=========================="
echo ""
	
#convert mp4 to mkv before language processing
find "$1" -type f -iregex ".*/.*\.\(mp4\)" -print0 | while IFS= read -r -d '' video; do
	echo ""
	echo "=========================="
	echo "INFO: Processing $video"
	if timeout 10s mkvmerge -i "$video" > /dev/null; then
		echo "INFO: MP4 found, remuxing to mkv before processing audio/subtitles"
		mkvmerge -o "$video.merged.mkv" "$video"
		# cleanup temp files and rename
		mv "$video" "$video.original.mkv" && echo "INFO: Renamed source file"
		mv "$video.merged.mkv" "${video/.mp4/.mkv}" && echo "INFO: Renamed temp file"
		rm "$video.original.mkv" && echo "INFO: Deleted source file"
	else
		echo "ERROR: mkvmerge failed"
		rm "$video" && echo "DELETED: $video"
		exit 1
	fi
	echo "INFO: Processing complete"
	echo "=========================="
	echo ""
done
	
#convert avi to mkv before language processing
find "$1" -type f -iregex ".*/.*\.\(avi\)" -print0 | while IFS= read -r -d '' video; do
	echo ""
	echo "=========================="
	echo "INFO: Processing $video"
	if timeout 10s mkvmerge -i "$video" > /dev/null; then
		echo "INFO: AVI found, remuxing to mkv before processing audio/subtitles"
		mkvmerge -o "$video.merged.mkv" "$video"
		# cleanup temp files and rename
		mv "$video" "$video.original.mkv" && echo "INFO: Renamed source file"
		mv "$video.merged.mkv" "${video/.avi/.mkv}" && echo "INFO: Renamed temp file"
		rm "$video.original.mkv" && echo "INFO: Deleted source file"
	else
		echo "ERROR: mkvmerge failed"
		rm "$video" && echo "INFO: deleted: $video"
		exit 1
	fi
	echo "INFO: Processing complete"
	echo "=========================="
	echo ""
done
		
# Finding Preferred Language
find "$1" -type f -iregex ".*/.*\.\(mkv\)" -print0 | while IFS= read -r -d '' video; do
	echo ""
	echo "=========================="
	echo "INFO: processing $video"
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
		echo "ERROR: mkvmerge failed to read tracks and set values"
		rm "$video" && echo "INFO: deleted: $video"
		exit 1
	fi
	
	# Checking for video
	echo "CHECK: Finding video tracks..."
	if test ! -z "$allvideo"; then
		echo "SUCCESS: Video tracks found"
	else
		# no video was found, error and report failed to sabnzbd
		echo "ERROR: No video tracks found"
		rm "$video" && echo "INFO: deleted: $video"
		exit 1
	fi
		
	# Checking for audio
	echo "CHECK: Finding audio tracks..."
	if test ! -z "$allaudio"; then
		echo "SUCCESS: Audio tracks found"
	else
		# no audio was found, error and report failed to sabnzbd
		echo "ERROR: No audio tracks found"
		rm "$video" && echo "INFO: deleted: $video"
		exit 1
	fi
	
	# Checking for subtitles
	echo "CHECK: Finding subtitle tracks..."
	if test ! -z "$allsub"; then
		echo "SUCCESS: Subtitle tracks found"
		subtitles="true"
	else
		echo "INFO: No subtitles found"
		subtitles="false"
	fi
	
	# Checking for preferred audio
	if test ! -z "$perfaudio"; then
		echo "CHECK: Finding \"${PerferredLanguage}\" audio tracks"
		echo "SUCCESS: \"${PerferredLanguage}\" audio tracks found"
		echo "CHECK: Finding unwanted audio tracks"
		setundaudio="false"
		if test ! -z "$nonperfaudio"; then
			echo "SUCCESS: Unwanted audio tracks found"
			echo "INFO: Marking unwanted audio tracks for deletion"
			removeaudio="true"
		else
			echo "SUCCESS: No unwanted audio tracks found"
			removeaudio="false"
		fi
		
		echo "CHECK: Searching for subtitles"
		if [ "${subtitles}" = true ]; then
			echo "SUCCESS: Subtitle tracks found"
			echo "CHECK: Finding \"${SubtitleLanguage}\" subtitle tracks"
			if test ! -z "$perfsub"; then
				echo "SUCCESS: \"${SubtitleLanguage}\" subtitle tracks found"
				echo "CHECK: Finding unwanted subtitle tracks"
				if test ! -z "$nonperfsub"; then
					echo "SUCCESS: Unwanted subtitle tracks found"
					echo "INFO: Marking unwanted subtitle tracks for deletion"
					removesubs="true"
				else 
					echo "SUCCESS: No unwanted subtitle tracks found"
					removeasubs="false"
				fi
			else
				echo "INFO: \"${SubtitleLanguage}\" subtitle tracks not found"
				echo "CHECK: Finding unwanted subtitle tracks"
				if test ! -z "$nonperfsub"; then
					echo "SUCCESS: Unwanted subtitle tracks found"
					echo "INFO: Marking unwanted subtitle tracks for deletion"
					removesubs="true"
				else 
					echo "SUCCESS: No unwanted subtitle tracks found"
					removeasubs="false"
				fi
			fi
		else
			echo "ERROR: No subtitle tracks found"
			echo "INFO: No unwanted subtitle tracks to remove"
			removeasubs="false"
		fi
		
		echo "CHECK: Analyzing video laguange"
		if test ! -z "$nonperfvideo"; then
			echo "INFO: Unwanted video lang found"
			setvideolanguage="true"
		else
			echo "SUCCESS: No unwanted video lang to change"
			setvideolanguage="false"
		fi
	elif test ! -z "$undaudio"; then
		echo "CHECK: Searching for \"und\" audio"
		echo "SUCCESS: \"und\" audio tracks found"
		echo "CHECK: Searching for unwanted audio tracks"
		setundaudio="true"
		if test ! -z "$nonundaudio"; then
			echo "SUCCESS: Unwanted audio tracks found"
			echo "INFO: Marking unwanted autio tracks for deleteion"
			removeaudio="true"
		else 
			echo "SUCCES: No unwanted audio tracks found for removal"
			removeaudio="false"
		fi
		
		echo "CHECK: Searching for subtitles"
		if [ "${subtitles}" = true ]; then
			echo "SUCCESS: Subtitle tracks found"
			echo "CHECK: Finding \"${SubtitleLanguage}\" subtitle tracks"
			if test ! -z "$perfsub"; then
				echo "SUCCESS: \"${SubtitleLanguage}\" subtitle tracks found"
				echo "CHECK: Finding unwanted subtitle tracks"
				if test ! -z "$nonperfsub"; then
					echo "SUCCESS: Unwanted subtitle tracks found"
					echo "INFO: Marking unwanted subtitle tracks for deletion"
					removesubs="true"
				else 
					echo "SUCCESS: No unwanted subtitle tracks found"
					removeasubs="false"
				fi
			else
				echo "INFO: \"${SubtitleLanguage}\" subtitle tracks not found"
				echo "CHECK: Finding unwanted subtitle tracks"
				if test ! -z "$nonperfsub"; then
					echo "SUCCESS: Unwanted subtitle tracks found"
					echo "INFO: Marking unwanted subtitle tracks for deletion"
					removesubs="true"
				else 
					echo "SUCCESS: No unwanted subtitle tracks found"
					removeasubs="false"
				fi
			fi
		else
			echo "ERROR: No subtitle tracks found"
			echo "INFO: No unwanted subtitle tracks to remove"
			removeasubs="false"
		fi
			
		echo "CHECK: Analyzing video laguange"
		if test ! -z "$nonperfvideo"; then
			echo "INFO: Unwanted video lang found"
			setvideolanguage="true"
		else
			echo "SUCCESS: No unwanted video lang to change"
			setvideolanguage="false"
		fi
		
	elif test ! -z "$allaudio"; then
		echo "CHECK: Searching for all audio tracks"
		echo "SUCCESS: Audio tracks found"
		echo "CHECK: Searching for subtitles"
		if [ "${subtitles}" = true ]; then
			echo "SUCCESS: Subtitle tracks found"
			echo "CHECK: Finding \"${SubtitleLanguage}\" subtitle tracks"
			if test ! -z "$perfsub"; then
				echo "SUCCESS: \"${SubtitleLanguage}\" subtitle tracks found"
				echo "CHECK: Finding unwanted subtitle tracks"
				if test ! -z "$nonperfsub"; then
					echo "SUCCESS: Unwanted subtitle tracks found"
					echo "INFO: Marking unwanted subtitle tracks for deletion"
					removesubs="true"
				else 
					echo "SUCCESS: No unwanted subtitle tracks found"
					removeasubs="false"
				fi
			else
				echo "ERROR: No subtitle tracks found, only foreign audio tracks found"
				echo "INFO: Deleting video and marking download as failed because no usuable audio/subititles are found in requested langauge"
				rm "$video" && echo "INFO: deleted: $video"
				exit 1
			fi
			echo "INFO: Skipping unwanted audo check"
			echo "INFO: Skip setting video language"
			removeaudio="false"
			setundaudio="false"
			setvideolanguage="false"
		else
			echo "ERROR: No subtitle tracks found, only foreign audio tracks found"
			echo "INFO: Deleting video and marking download as failed because no usuable audio/subititles are found in requested langauge"
			rm "$video" && echo "INFO: deleted: $video"
			exit 1
		fi	
	fi
	
	if [ "${removeaudio}" = false ] && [ "${setundaudio}" = false ] && [ "${removeasubs}" = false ] && [ "${setvideolanguage}" = false ]; then
		echo "INFO: Video passed all checks, no processing needed"
	else
		
		if [ "${setundaudio}" = true ]; then
			if [ "${SetUnknownAudioLanguage}" = true ]; then
				mkvaudio="-a $undaudio --language $undaudio:${UnkownAudioLanguage}"
			elif [ "${removeaudio}" = true ]; then
				mkvaudio="-a und"
			else
				mkvaudio=""
			fi
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
		
		echo "INFO: Begin processign file with mkvmerge"
		if mkvmerge --no-global-tags --title "" -o "$video.merged.mkv" ${mkvvideo} ${mkvaudio} ${mkvsubs} "$video"; then
			echo "SUCCESS: mkverge complete"
			echo "INFO: Options used: ${mkvvideo} ${mkvaudio} ${mkvsubs}"
		elif [ "${SetUnknownAudioLanguage}" = true ]; then
			echo "ERROR: mkvmerge failed setting \"und\" audio to \"${PerferredLanguage}\", skipping language setting"
			if mkvmerge --no-global-tags --title "" -o "$video.merged.mkv" ${mkvvideo} -a und ${mkvsubs} "$video"; then
				echo "SUCCESS: mkverge complete"
				echo "INFO: Options used: ${mkvvideo} -a und ${mkvsubs}"
			else
				echo "ERROR: mkvmerge failed"
				exit 1
			fi
		fi
		# cleanup temp files and rename
		mv "$video" "$video.original.mkv" && echo "Renamed source file"
		mv "$video.merged.mkv" "$video" && echo "Renamed temp file"
		rm "$video.original.mkv" && echo "Deleted source file"

	fi
	echo "INFO: Processing complete"
	echo "=========================="
	echo ""
done

echo "INFO: Video processing complete"

# script complete, now exiting
exit 0
