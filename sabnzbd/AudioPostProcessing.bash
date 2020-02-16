#!/bin/bash
#######################################
#        Audio Post-Processing        #
#             Bash Script             #
#######################################
#=============REQUIREMENTS=============
#        flac, mp3val, ffmpeg         #
#============CONFIGURATION=============
RemoveNonAudioFiles="TRUE" # TURE = ENABLED, Deletes non FLAC/M4A/MP3/OPUS/OGG files
DuplicateFileCleanUp="TRUE" # TRUE = ENABLED, Deletes duplicate files
AudioVerification="TRUE" # TRUE = ENABLED, Verifies FLAC/MP3 files for errors (fixes MP3's, deletes bad FLAC files)
Convert="FALSE" # TRUE = ENABLED, Only converts lossless FLAC files
ConversionFormat="MP3" # SET TO: OPUS or AAC or MP3 or ALAC - converts lossless FLAC files to set format
ConversionBitrate="192" # Set to desired bitrate when converting to OPUS/AAC/MP3 format types
ReplaygainTagging="TRUE" # TRUE = ENABLED, adds replaygain tags for compatible players (FLAC ONLY)
BeetsProcessing="TRUE" # TRUE = ENABLED

#============FUNCTIONS============

clean () {
	if find "$1" -type f -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" | read; then
		echo "REMOVE NON AUDIO FILES"
		find "$1" -type f -not -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -delete
		echo "REMOVE NON AUDIO FILES COMPLETE"
		echo "MOVE FILES TO DIR"
		find "$1" -type f -mindepth 2 -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -exec mv "{}" "$1"/ \;
		echo "MOVE FILES TO DIR COMPLETE"
		echo "REMOVE SUB-DIRECTORIES"
		find "$1" -type d -mindepth 1 -exec rm -rf "{}" \;
		echo "REMOVE SUB-DIRECTORIES COMPLETE"
	else
		echo "ERROR: NO AUDIO FILES FOUND" && exit 1
	fi
}

duplicatefilecleanup () {
	echo "DUPLICATE FILE CLEANUP"
	find "$1"/* -type f -iname "*([0-9]).*" -delete
	find "$1"/* -type f -iname "*.[0-9].*" -delete
	if find "$1" -type f -iregex ".*/.*\.\(flac\)" | read; then
		find "$1"/* -type f -not -iregex ".*/.*\.\(flac\)" -delete
	elif find "$1" -type f -iregex ".*/.*\.\(alac\)" | read; then
		find "$1"/* -type f -not -iregex ".*/.*\.\(alac\)" -delete
	fi
	echo "DUPLICATE FILE CLEANUP COMPLETE"
}

verify () {
	if find "$1" -iname "*.flac" | read; then
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
		if [ -x "$(command -v opusenc)" ]; then
			if find  "$1"/ -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat (${bitrate}k))"
				for fname in "$1"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if opusenc --bitrate $bitrate --vbr --music "$fname" "${fname%.flac}.opus" 2> /dev/null; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.opus" ]; then
							rm "$fname"
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
			echo "ERROR: opus-tools not installed, please install opus-tools to use this conversion feature"
			sleep 5
		fi
	fi
	if [ "${ConversionFormat}" = AAC ]; then
		if [ -x "$(command -v ffmpeg)" ]; then
			if find "$1"/ -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat (${bitrate}k))"
				for fname in "$1"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn -acodec aac -ab ${bitrate}k -movflags faststart "${fname%.flac}.m4a"; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.m4a" ]; then
							rm "$fname"
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
	fi
	
	if [ "${ConversionFormat}" = MP3 ]; then
		if [ -x "$(command -v ffmpeg)" ]; then
			if find "$1"/ -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat (${bitrate}k))"
				for fname in "$1"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn -acodec libmp3lame -ab ${bitrate}k "${fname%.flac}.mp3"; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.mp3" ]; then
							rm "$fname"
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
	fi
	if [ "${ConversionFormat}" = ALAC ]; then
		if [ -x "$(command -v ffmpeg)" ]; then
			if find "$1"/ -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat)"
				for fname in "$1"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn -acodec alac -movflags faststart "${fname%.flac}.m4a"; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.m4a" ]; then
							rm "$fname"
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
	fi
}

replaygain () {
	if ! [ -x "$(command -v flac)" ]; then
		echo "ERROR: METAFLAC replaygain utility not installed (ubuntu: apt-get install -y flac)"
	elif find "$1" -iname "*.flac" | read; then
		replaygaintrackcount=$(find  "$1"/ -iname "*.flac" | wc -l)
		find "$1" -iname "*.flac" -exec metaflac --add-replay-gain "{}" + && echo "Replaygain: $replaygaintrackcount Tracks Tagged"
	fi
}

beets () {
	echo "MATCHING WITH BEETS"
	if [ -f /config/scripts/beets/library.blb ]; then
		rm /config/scripts/beets/library.blb
		sleep 0.2
	fi
	if [ -f /config/scripts/beets/beets.log ]; then 
		rm /config/scripts/beets/beets.log
		sleep 0.2
	fi
	if find "$1" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | read; then
		beet -c /config/scripts/beets/config.yaml -d "$1" import -q "$1" > /dev/null
		if find "$1" -type f -iname "*.MATCHED.*" | read; then
			echo "SUCCESS: Matched with beets!"
		else
			rm -rf "$1"/* 
			echo "ERROR: Unable to match using beets to a musicbrainz release, deleting..." && exit 1
		fi	
	fi
}

#============START SCRIPT============

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

echo "AUDIO POST-PROCESSING COMPLETE" && exit 0
#============END SCRIPT============
