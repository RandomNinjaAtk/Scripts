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
Convert="FALSE" # TRUE = ENABLED, Only converts lossless FLAC/ALAC files
ConversionFormat="MP3" # SET TO: OPUS or AAC or MP3 or FLAC or ALAC - converts lossless FLAC files to set format
Threads="0" # SET TO: "0" to use maximum number of threads for multi-threaded operations
ReplaygainTagging="TRUE" # TRUE = ENABLED, adds replaygain tags for compatible players (FLAC ONLY)

#============FUNCTIONS============

clean () {
	if find "$1" -type f -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" | read; then
		echo "REMOVE NON AUDIO FILES"
		find "$1"/* -type f -not -iregex ".*/.*\.\(flac\|mp3\|m4a\|alac\|ogg\|opus\)" -delete
		echo "REMOVE NON AUDIO FILES COMPLETE"
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
	if find "$1" -type f -iregex ".*/.*\.\(flac\)" | read; then
		echo "START FLAC VERIFICATION"
		find "$1" -type f -iregex ".*/.*\.\(flac\)" | xargs -0 -d '\n' -n1 -I@ -P ${Threads} bash -c 'if flac -t --totally-silent "@"; then echo "FLAC CHECK PASSED: @"; else rm "@" && echo "FAILED FLAC CHECK, FILE DELETED: @"; fi;' && echo "VERIFICATION COMPLETE"
	elif find "$1" -type f -iregex ".*/.*\.\(mp3\)" | read; then
		echo "START MP3 VERIFICATION"
		find "$1" -type f -iregex ".*/.*\.\(mp3\)" | xargs -0 -d '\n' -n1 -I@ -P ${Threads} bash -c 'mp3val -f -nb "@"' && echo "VERIFICATION COMPLETE"
	else
		echo "NO FLAC/MP3 FILES TO VERIFY"
	fi
}

conversion () {
	if find "$1" -type f -iregex ".*/.*\.\(flac\)" | read; then
		echo "FLAC FILES FOUND"
		if [ "${ConversionFormat}" = OPUS ]; then
			echo "OPUS CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(flac\)" | sed -e 's/.flac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.flac\" -n -vn -acodec libopus -ab 160k -application audio \"@.opus\" && echo \"CONVERSION SUCCESS: @.opus\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "OPUS CONVERSION COMPLETE"
			else
				echo "ERROR: OPUS CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = AAC ]; then
			echo "AAC CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(flac\)" | sed -e 's/.flac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.flac\" -n -vn -acodec libfdk_aac -ab 320k -movflags faststart \"@.m4a\" && echo \"CONVERSION SUCCESS: @.m4a\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "AAC CONVERSION COMPLETE"
			else
				echo "ERROR: AAC CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = MP3 ]; then
			echo "MP3 CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(flac\)" | sed -e 's/.flac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.flac\" -n -vn -acodec libmp3lame -ab 320k \"@.mp3\" && echo \"CONVERSION SUCCESS: @.mp3\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "MP3 CONVERSION COMPLETE"
			else
				echo "ERROR: MP3 CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = FLAC ]; then
			echo "FLAC CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(flac\)" | sed -e 's/.flac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.flac\" -n -vn -acodec flac \"@.temp.flac\" && echo \"CONVERSION SUCCESS: @.flac\" && rm \"@.flac\" && mv \"@.temp.flac\" \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "FLAC CONVERSION COMPLETE"
			else
				echo "ERROR: FLAC CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = ALAC ]; then
			echo "ALAC CONVERSION START"
			if { find "${DownloadDir}/files/" -name "*.flac" | sed -e 's/.flac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.flac\" -n -vn -acodec alac -movflags faststart \"@.m4a\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "ALAC CONVERSION COMPLETE"
			else
				echo "ERROR: ALAC CONVERSION FAILED" && exit 1
			fi
		fi
	elif find "$1" -type f -iregex ".*/.*\.\(alac\)" | read; then
		echo "ALAC FILES FOUND"
		if [ "${ConversionFormat}" = OPUS ]; then
			echo "OPUS CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(alac\)" | sed -e 's/.alac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.alac\" -n -vn -acodec libopus -ab 160k -application audio \"@.opus\" && echo \"CONVERSION SUCCESS: @.opus\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "OPUS CONVERSION COMPLETE"
			else
				echo "ERROR: OPUS CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = AAC ]; then
			echo "AAC CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(alac\)" | sed -e 's/.alac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.alac\" -n -vn -acodec libfdk_aac -ab 320k -movflags faststart \"@.m4a\" && echo \"CONVERSION SUCCESS: @.m4a\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "AAC CONVERSION COMPLETE"
			else
				echo "ERROR: AAC CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = MP3 ]; then
			echo "MP3 CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(alac\)" | sed -e 's/.alac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.alac\" -n -vn -acodec libmp3lame -ab 320k \"@.mp3\" && echo \"CONVERSION SUCCESS: @.mp3\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "MP3 CONVERSION COMPLETE"
			else
				echo "ERROR: MP3 CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = FLAC ]; then
			echo "FLAC CONVERSION START"
			if { find "$1" -type f -iregex ".*/.*\.\(alac\)" | sed -e 's/.alac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.alac\" -n -vn -acodec flac \"@.temp.flac\" && echo \"CONVERSION SUCCESS: @.flac\" && rm \"@.flac\" && mv \"@.temp.flac\" \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "FLAC CONVERSION COMPLETE"
			else
				echo "ERROR: FLAC CONVERSION FAILED" && exit 1
			fi
		fi
		if [ "${ConversionFormat}" = ALAC ]; then
			echo "ALAC CONVERSION START"
			if { find "${DownloadDir}/files/" -name "*.flac" | sed -e 's/.flac$//' -e "s/'/\\'/g" -e 's/\$/\\$/g' | xargs -d '\n' -n1 -I@ -P ${Threads} bash -c "ffmpeg -loglevel warning -hide_banner -stats -i \"@.flac\" -n -vn -acodec alac -movflags faststart \"@.m4a\" && rm \"@.flac\" && echo \"SOURCE FILE DELETED: @.flac\""; }; then
				echo "ALAC CONVERSION COMPLETE"
			else
				echo "ERROR: ALAC CONVERSION FAILED" && exit 1
			fi
		fi
	else
		echo "No lossless (FLAC/ALAC) files found to convert"
	fi
}

replaygain () {
	if find "$1" -type f -iregex ".*/.*\.\(flac\)" | read; then
		echo "FLAC - ADDING REPLAYGAIN TAGS"
		if find "$1" -type f -iregex ".*/.*\.\(flac\)" -exec metaflac --add-replay-gain "{}" +; then
			echo "FLAC REPLAYGAIN TAGGING COMPLETE"
		else
			echo "ERROR: FLAC REPLAYGAIN TAGGING FAILED" && exit 1
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
	if [ -x "$(command -v flac)" ]; then
		if [ -x "$(command -v mp3val)" ]; then
			verify "$1"
		else
			echo "MP3VAL not installed" && exit 1
		fi
	else
		echo "FLAC not installed" && exit 1
	fi
else
	echo "AUDIO VERFICATION DISABLED"
fi
if [ "${Convert}" = TRUE ];	then
	if [ -x "$(command -v ffmpeg)" ]; then
		conversion "$1"
	else
		echo "FFMPEG not installed" && exit 1
	fi
else
	echo "CONVERSION DISABLED"
fi
if [ "${ReplaygainTagging}" = TRUE ]; then
	if [ -x "$(command -v metaflac)" ];	then
		replaygain "$1"
	else
		echo "metaflac not installed" && exit 1
	fi
else
	echo "REPLAYGAIN TAGGING DISABLED"
fi
echo "AUDIO POST-PROCESSING COMPLETE" && exit 0
#============END SCRIPT============
