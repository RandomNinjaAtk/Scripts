#!/bin/bash
#######################################
#        Audio Post-Processing        #
#             Bash Script             #
#######################################
#=============REQUIREMENTS=============
#         flac, mp3val, ffmpeg        #
#============CONFIGURATION=============
RemoveNonAudioFiles="TRUE" # TURE = ENABLED, Deletes non FLAC/M4A/MP3/OPUS/OGG files
DuplicateFileCleanUp="TRUE" # TRUE = ENABLED, Deletes duplicate files
AudioVerification="TRUE" # TRUE = ENABLED, Verifies FLAC/MP3 files for errors (fixes MP3's, deletes bad FLAC files)
Convert="FALSE" # TRUE = ENABLED, Only converts lossless FLAC files
ConversionFormat="FLAC" # SET TO: OPUS or AAC or MP3 or ALAC or FLAC - converts lossless FLAC files to set format
ConversionBitrate="320" # Set to desired bitrate when converting to OPUS/AAC/MP3 format types
ReplaygainTagging="TRUE" # TRUE = ENABLED, adds replaygain tags for compatible players (FLAC ONLY)
BeetsProcessing="TRUE" # TRUE = ENABLED :: Match with beets
BeetsFallbackToLidarr="TRUE" # TRUE = ENABLED :: If beets cannot match, allow lidarr to attempt match and import, if disabled, download will be marked as failed
DetectNonSplitAlubms="TRUE" # TRUE = ENABLED :: Uses "MaxFileSize" to detect and mark download as failed if detected
MaxFileSize="150M" # M = MB, G = GB :: Set size threshold for detecting single file albums

#============FUNCTIONS============

settings () {

echo ""
echo "Configuration:"
if [ "${RemoveNonAudioFiles}" = TRUE ]; then
	echo "RemoveNonAudioFiles: ENABLED"
else
	echo "RemoveNonAudioFiles: DISABLED"
fi

if [ "${DuplicateFileCleanUp}" = TRUE ]; then
	echo "DuplicateFileCleanUp: ENABLED"
else
	echo "DuplicateFileCleanUp: DISABLED"
fi

if [ "${AudioVerification}" = TRUE ]; then
	echo "AudioVerification: ENABLED"
else
	echo "AudioVerification: DISABLED"
fi

if [ "${Convert}" = TRUE ]; then
	echo "Convert: ENABLED"
	echo "Convert Format: $ConversionFormat"
	if [ "${ConversionFormat}" = FLAC ]; then
		echo "Bitrate: lossless"
	elif [ "${ConversionFormat}" = ALAC ]; then
		echo "Bitrate: lossless"
	else
		echo "Conversion Bitrate: ${ConversionBitrate}k"
	fi
else
	echo "Convert: DISABLED"
fi

if [ "${Convert}" = TRUE ]; then
	if [ "${ConversionFormat}" = FLAC ]; then
		if [ "${ReplaygainTagging}" = TRUE ]; then
			echo "ReplaygainTagging: ENABLED"
		else
			echo "ReplaygainTagging: DISABLED"
		fi
	fi
else
	if [ "${ReplaygainTagging}" = TRUE ]; then
		echo "ReplaygainTagging: ENABLED"
	else
		echo "ReplaygainTagging: DISABLED"
	fi
fi

if [ "${BeetsProcessing}" = TRUE ]; then
	echo "BeetsProcessing: ENABLED"
	if [ "${BeetsFallbackToLidarr}" = TRUE ]; then
		echo "BeetsFallbackToLidarr: ENABLED" 
	else
		echo "BeetsFallbackToLidarr: DISABLED" 
	fi
else
	echo "BeetsProcessing: DISABLED"
fi

if [ "${DetectNonSplitAlubms}" = TRUE ]; then
	echo "DetectNonSplitAlubms: ENABLED"
	echo "MaxFileSize: $MaxFileSize" 
else
	echo "DetectNonSplitAlubms: DISABLED"
fi

echo ""
echo "Processing: $1" 

}

clean () {
	if find "$1" -type f -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" | read; then
		if find "$1" -type f -not -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" | read; then
			echo ""
			echo "REMOVE NON AUDIO FILES"
			find "$1" -type f -not -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -delete
			echo "REMOVE NON AUDIO FILES COMPLETE"
		fi
		if find "$1" -type f -mindepth 2 -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" | read; then
			echo ""
			echo "MOVE FILES TO DIR"
			find "$1" -type f -mindepth 2 -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -exec mv "{}" "$1"/ \;
			echo "MOVE FILES TO DIR COMPLETE"
		fi
		if find "$1" -type d -mindepth 1 | read; then
			echo ""
			echo "REMOVE SUB-DIRECTORIES"
			find "$1" -type d -mindepth 1 -exec rm -rf "{}" \;
			echo "REMOVE SUB-DIRECTORIES COMPLETE"
		fi
	else
		echo "ERROR: NO AUDIO FILES FOUND" && exit 1
	fi
}

duplicatefilecleanup () {
	duplicate="FALSE"
	if find "$1" -type f -mindepth 1 -iname "*([0-9]).*" | read; then
		find "$1" -type f -mindepth 1 -iname "*([0-9]).*" -delete
		duplicate="TRUE"
	fi
		
	if find "$1" -type f -mindepth 1 -iname "*.[0-9].*" | read; then
		find "$1" -type f -mindepth 1 -iname "*.[0-9].*" -delete
		duplicate="TRUE"
	fi
	
	if find "$1" -type f -mindepth 1 -iname "*.flac" | read; then
		if find "$1"/* -type f -not -iname "*.flac" | read; then
			find "$1"/* -type f -not -iname "*.flac" -delete
			duplicate="TRUE"
		fi
	fi
	if [ "${duplicate}" = TRUE ]; then
		echo ""
		echo "DUPLICATE FILE CLEANUP"
		echo "DUPLICATE FILE CLEANUP COMPLETE"
	fi
}

detectsinglefilealbums () {
	if find "$1" -type f -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -size +${MaxFileSize} | read; then
		echo "ERROR: Non split album detected" && exit 1
	fi
}

verify () {
	if find "$1" -iname "*.flac" | read; then
		verifytrackcount=$(find  "$1"/ -iname "*.flac" | wc -l)
		echo ""
		echo "Verifying: $verifytrackcount Tracks"
		if ! [ -x "$(command -v flac)" ]; then
			echo "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
		else
			for fname in "$1"/*.flac; do
				filename="$(basename "$fname")"
				if flac -t --totally-silent "$fname"; then
					echo "Verified Track: $filename"
				else
					echo "ERROR: Track Verification Failed: \"$filename\""
					rm -rf "$1"/*
					sleep 0.1
					exit 1
				fi
			done
		fi
	fi
	if find "$1" -iname "*.mp3" | read; then
		verifytrackcount=$(find  "$1"/ -iname "*.mp3" | wc -l)
		echo ""
		echo "Verifying: $verifytrackcount Tracks"
		if ! [ -x "$(command -v mp3val)" ]; then
			echo "MP3VAL verification utility not installed (ubuntu: apt-get install -y mp3val)"
		else
			for fname in "$1"/*.mp3; do
				filename="$(basename "$fname")"
				if mp3val -f -nb "$fname" > /dev/null; then
					echo "Verified Track: $filename"
				fi
			done
		fi
	fi
}

conversion () {
	converttrackcount=$(find  "$1"/ -name "*.flac" | wc -l)
	targetformat="$ConversionFormat"
	bitrate="$ConversionBitrate"
	if [ "${ConversionFormat}" = OPUS ]; then
		options="-acodec libopus -ab ${bitrate}k -application audio"
		extension="opus"
		targetbitrate="${bitrate}k"
	fi
	if [ "${ConversionFormat}" = AAC ]; then
		options="-acodec aac -ab ${bitrate}k -movflags faststart"
		extension="m4a"
		targetbitrate="${bitrate}k"
	fi
	if [ "${ConversionFormat}" = MP3 ]; then
		options="-acodec libmp3lame -ab ${bitrate}k"
		extension="mp3"
		targetbitrate="${bitrate}k"
	fi
	if [ "${ConversionFormat}" = ALAC ]; then
		options="-acodec alac -movflags faststart"
		extension="m4a"
		targetbitrate="lossless"
	fi
	if [ "${ConversionFormat}" = FLAC ]; then
		options="-acodec flac"
		extension="flac"
		targetbitrate="lossless"
	fi
	if [ -x "$(command -v ffmpeg)" ]; then
		if find "$1"/ -name "*.flac" | read; then
			echo ""
			echo "Converting: $converttrackcount Tracks (Target Format: $targetformat (${targetbitrate}))"
			for fname in "$1"/*.flac; do
				filename="$(basename "${fname%.flac}")"
				if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn $options "${fname%.flac}.temp.$extension"; then
					echo "Converted: $filename"
					if [ -f "${fname%.flac}.temp.$extension" ]; then
						rm "$fname"
						sleep 0.1
						mv "${fname%.flac}.temp.$extension" "${fname%.flac}.$extension"
					fi
				else
					echo "Conversion failed: $filename, performing cleanup..."
					rm -rf "$1"/*
					sleep 0.1
					exit 1
				fi
			done
		fi
	else
		echo "ERROR: ffmpeg not installed, please install ffmpeg to use this conversion feature"
		sleep 5
	fi
}

replaygain () {
	if ! [ -x "$(command -v flac)" ]; then
		echo "ERROR: METAFLAC replaygain utility not installed (ubuntu: apt-get install -y flac)"
	elif find "$1" -iname "*.flac" | read; then
		replaygaintrackcount=$(find  "$1"/ -iname "*.flac" | wc -l)
		echo ""
		find "$1" -iname "*.flac" -exec metaflac --add-replay-gain "{}" + && echo "Replaygain: $replaygaintrackcount Tracks Tagged"
	fi
}

beets () {
	echo ""
	trackcount=$(find "$1" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
	echo "Matching $trackcount tracks with Beets"
	if [ -f /config/scripts/beets/library.blb ]; then
		rm /config/scripts/beets/library.blb
		sleep 0.1
	fi
	if [ -f /config/scripts/beets/beets.log ]; then 
		rm /config/scripts/beets/beets.log
		sleep 0.1
	fi
	
	touch "$1/beets-match"
	sleep 0.1
	
	if find "$1" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | read; then
		beet -c /config/scripts/beets/config.yaml -d "$1" import -q "$1" > /dev/null
		if find "$1" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" -newer "$1/beets-match" | read; then
			echo "SUCCESS: Matched with beets!"
		else
			if [ "${BeetsFallbackToLidarr}" = TRUE ]; then
				echo "ERROR: Unable to match using beets, fallback to lidarr import matching..."
			else
				rm -rf "$1"/* 
				echo "ERROR: Unable to match using beets to a musicbrainz release, marking download as failed..." && exit 1
			fi
		fi	
	fi
	
	if [ -f "$1/beets-match" ]; then 
		rm "$1/beets-match"
		sleep 0.1
	fi
}

#============START SCRIPT============

settings "$1"

if [ "${RemoveNonAudioFiles}" = TRUE ]; then
	clean "$1"
else
	echo "CLEANING DISABLED"
fi

if [ "${DuplicateFileCleanUp}" = TRUE ]; then
	duplicatefilecleanup "$1"
else
	echo "DUPLICATE CLEANUP DISABLED"
fi

if [ "${DetectNonSplitAlubms}" = TRUE ]; then
	detectsinglefilealbums "$1"
else
	echo "NON-SPLIT ABLUM DETECTION DISABLED"
fi

if [ "${AudioVerification}" = TRUE ]; then
	verify "$1"
else
	echo "AUDIO VERFICATION DISABLED"
fi

if [ "${BeetsProcessing}" = TRUE ]; then
	beets "$1"
else
	echo "BEETS PROCESSING DISABLED"
fi

if [ "${Convert}" = TRUE ];	then
	conversion "$1"
else
	echo "CONVERSION DISABLED"
fi

if [ "${ReplaygainTagging}" = TRUE ]; then
	replaygain "$1"
else
	echo "REPLAYGAIN TAGGING DISABLED"
fi

echo ""
echo "AUDIO POST-PROCESSING COMPLETE" && exit 0
#============END SCRIPT============
