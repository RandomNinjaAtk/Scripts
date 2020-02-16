#!/bin/bash
################ FLAC -> OPUS CONVERSION TOOL ################

############ Usage
# Execute via CLI using the following command: bash FlacToOpus.bash "/path/to/starting/directory"
# Replace "/path/to/starting/directory" with the path to your starting directory

############ Requirements
# Software Packages:
# opusenc
# find

############ Settings
bitrate="192" # Desired bitrate for OPUS conversion (VBR is used, so will not be exact)

################ Script Start

filecount=($(find "$1" -iname "*.flac" | wc -l))

echo "Number of files to process $filecount"

find "$1" -iname "*.flac" -print0 | while IFS= read -r -d '' file; do
    if [ -x "$(command -v opusenc)" ]; then
		if opusenc --bitrate $bitrate --vbr --music "$file" "${file%.flac}.opus" 2> /dev/null; then
			echo "Converted: $file"
			if [ -f "${file%.flac}.opus" ]; then
				rm "$file"
			fi
		else
			echo "Conversion failed: $file, performing cleanup..."
			echo "Deleted: $file"
			rm "$file"
		fi
	else
		echo "ERROR: opus-tools not installed, please install opus-tools to use this conversion feature"
		sleep 5
	fi
done


################ Script End
exit 0
