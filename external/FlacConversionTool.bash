#!/bin/bash
################ FLAC CONVERSION TOOL ################

############ Usage
# Execute via CLI using the following command: bash FlacToOpus.bash "/path/to/starting/directory"
# Replace "/path/to/starting/directory" with the path to your starting directory

############ Requirements
# Software Packages:
# ffmpeg
# find

############ Settings
ConversionFormat="MP3" # SET TO: OPUS or AAC or MP3 or ALAC or FLAC - converts lossless FLAC files to set format
ConversionBitrate="320" # Set to desired bitrate when converting to OPUS/AAC/MP3 format types

################ Script Start

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

filecount=($(find "$1" -iname "*.flac" | wc -l))

echo "Configuration:"
echo "Conversion Format: $ConversionFormat"
echo "Conversion Bitrate: $targetbitrate"
echo "Starting Directory: $1"
echo "FLAC Files to process: $filecount"
echo ""

find "$1" -iname "*.flac" -print0 | while IFS= read -r -d '' file; do
	if [ -x "$(command -v ffmpeg)" ]; then
		filename="$(basename "${file%.flac}")"
		if ffmpeg -loglevel warning -hide_banner -nostats -i "$file" -n -vn $options "${file%.flac}.temp.$extension"; then
			echo "Converted: $filename"
			if [ -f "${file%.flac}.temp.$extension" ]; then
				rm "$file"
				sleep 0.1
				mv "${file%.flac}.temp.$extension" "${file%.flac}.$extension"
			fi
		else
			echo "Conversion failed: $filename, performing cleanup..."
			echo "Deleted: $file"
			rm "$file"
		fi
	else
		echo "ERROR: ffmpeg not installed, please install ffmpeg to use this conversion feature"
		sleep 5
	fi
done


################ Script End
exit 0
