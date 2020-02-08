#!/bin/bash
#####################################################################################################
#                                     Lidarr Automated Downloader                                   #
#                                    (Powered by: Deezloader Remix)                                 #
#                                       Credit: RandomNinjaAtk                                      #
#####################################################################################################
#                                           Script Start                                            #
#####################################################################################################

source ./config

tempalbumfile="temp-archive-album"
temptrackfile="temp-archive-track"
tempartistjson="artistinfo.json"
tempalbumlistjson="temp-albumlistdata.json"
tempalbumjson="albuminfo.json"
artistalbumlistjson="discography.json"

ArtistsLidarrReq(){
	
	wantit=$(curl -s --header "X-Api-Key:"${LidarrApiKey} --request GET  "$LidarrUrl/api/v1/Artist/")
	TotalLidArtistNames=$(echo "${wantit}"|jq -r '.[].sortName' | wc -l)
	
	if [ "$quality" = flac ]; then
		dlquality="flac"
		bitrate="lossless"
		targetformat="FLAC"
	elif [ "$quality" = mp3 ]; then
		dlquality="320"
		bitrate="320"
		targetformat="MP3"
	elif [ "$quality" = alac ]; then
		dlquality="flac"
		targetformat="ALAC"
		bitrate="lossless"
	elif [ "$quality" = opus ]; then
		dlquality="flac"
		targetformat="OPUS"
		if [ -z "$bitrate" ]; then
			bitrate="128"
		fi
	elif [ "$quality" = aac ]; then
		dlquality="flac"
		targetformat="AAC"
		if [ -z "$bitrate" ]; then
			bitrate="320"
		fi
	fi
	
	ConfigSettings
	
	MBArtistID=($(echo "${wantit}" | jq -r ".[$i].foreignArtistId"))
	for id in ${!MBArtistID[@]}; do
		artistnumber=$(( $id + 1 ))
		mbid="${MBArtistID[$id]}"
		
		source ./config
		
		if ! [ -f "musicbrainzerror.log" ]; then
			touch "musicbrainzerror.log"
		fi		
		
		LidArtistPath="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .path")"
		LidArtistID="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .id")"
		LidArtistNameCap="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .artistName")"
		mbjson=$(curl -s "http://musicbrainz.org/ws/2/artist/${mbid}?inc=url-rels&fmt=json")
		deezerartisturl=$(echo "$mbjson" | jq -r '.relations | .[] | .url | select(.resource | contains("deezer")) | .resource' | head -n 1)
		DeezerArtistID=$(printf -- "%s" "${deezerartisturl##*/}")
		artistdir="$(basename "$LidArtistPath")"
		if [ -z "${DeezerArtistID}" ]; then			
			if [ -f "musicbrainzerror.log" ]; then
				echo "${artistnumber}/${TotalLidArtistNames}: ERROR: \"$LidArtistNameCap\"... musicbrainz id: $mbid is missing deezer link, see: \"$(pwd)/musicbrainzerror.log\" for more detail..."
				if cat "musicbrainzerror.log" | grep "$mbid" | read; then
					sleep 0.1
				else
					echo "Update Musicbrainz Relationship Page: https://musicbrainz.org/artist/$mbid/relationships for \"${LidArtistNameCap}\" with Deezer Artist Link" >> "musicbrainzerror.log"
				fi
			fi
		else
			if [ -f "$LidArtistPath/musicbrainzerror.log" ]; then
				rm "$LidArtistPath/musicbrainzerror.log"
			fi
			
			if [ "$dailycheck" = true ]; then

				if cat "daily.log" | grep "$LidArtistID" | read; then
					echo "${artistnumber}/${TotalLidArtistNames}: Already Checked \"$LidArtistNameCap\" for new music, skipping..."
				else			
					lidarrartists

					if ! [ -f "daily.log" ]; then
						touch "daily.log"
					fi

					if cat "daily.log" | grep "$LidArtistID" | read; then
						sleep 0.1
					else
						echo "${LidArtistNameCap} :: $LidArtistID :: Daily Check Completed" >> "daily.log"
					fi
				fi
			else
				lidarrartists

				if ! [ -f "daily.log" ]; then
					touch "daily.log"
				fi
				
				if cat "daily.log" | grep "$LidArtistID" | read; then
					sleep 0.1
				else
					echo "${LidArtistNameCap} :: $LidArtistID :: Daily Check Completed" >> "daily.log"
				fi
			fi
		fi
	done
}

AlbumDL () {
	check=1
	error=0
	trackdlfallback=0
	if [ "$downloadmethod" = "album" ]; then
		if curl -s --request GET "$deezloaderurl/api/download/?url=$albumurl&quality=$dlquality" >/dev/null; then
			echo "Download Timeout: $albumtimeoutdisplay"
			echo "Downloading $tracktotal Tracks..."
			sleep $dlcheck
			let j=0
			while [[ "$check" -le 1 ]]; do
				let j++
				if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
					check=2
				else
					sleep 1s
					if [ "$j" = "$albumtimeout" ]; then
						dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
						if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
							echo "Error downloading $albumname ($dlquality), retrying...via track method "
							trackdlfallback=1
							error=1
						fi
					fi
				fi
			done
			if find "$downloaddir" -iname "*.flac" | read; then
				fallbackqualitytext="FLAC"
			elif find "$downloaddir" -iname "*.mp3" | read; then
				fallbackqualitytext="MP3"
			fi
			if [ $error = 1 ]; then
				rm -rf "$downloaddir"/*
				echo "$artistname :: $albumname :: $fallbackqualitytext :: Fallback to track download method" >> "download-album-error.log"
			else
				echo "Downloaded Album: $albumname (Format: $fallbackqualitytext; Length: $albumdurationdisplay)"
				Verify
			fi
		else
			echo "Error sending download to Deezloader-Remix (Attempt 1)"
			trackdlfallback=1
		fi
	else
		trackdlfallback=1
	fi
}

DownloadURL () {
	check=1
	error=0
	retry=0
	fallback=0
	fallbackbackup=0
	fallbackquality="$dlquality"
	if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$dlquality" >/dev/null; then
		sleep $dlcheck
		let j=0
		while [[ "$check" -le 1 ]]; do
			let j++
			if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
				check=2
			else
				sleep 1s
				retry=0
				if [ "$j" = "$tracktimeout" ]; then
					dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
					if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
						echo "Error downloading track $tracknumber: $trackname ($dlquality), retrying...download"
						retry=1
						find "$downloaddir" -type f -iname "*.flac" -newer "$temptrackfile" -delete
						find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
					fi
				fi
			fi
		done
	else
	    echo "Error sending download to Deezloader-Remix (Attempt 2)"
	fi
	if [ $retry = 1 ]; then
		if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$dlquality" >/dev/null; then
			sleep $dlcheck
			let k=0
			while [[ "$retry" -le 1 ]]; do
				let k++
				if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
					retry=2
				else
					sleep 1s
					fallback=0
					if [ "$k" = "$trackfallbacktimout" ]; then
						dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
						if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
							echo "Error downloading track $tracknumber: $trackname ($dlquality), retrying...as mp3 320"
							fallback=1
							find "$downloaddir" -type f -iname "*.flac" -newer "$temptrackfile" -delete
							find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
						fi
					fi
				fi
			done
		else
			echo "Error sending download to Deezloader-Remix (Attempt 3)"
		fi
	fi
	if [ "$enablefallback" = true ]; then
		if [ $fallback = 1 ]; then
			if [ "$dlquality" = flac ]; then
				fallbackquality="320"
				bitrate="320"
			elif [ "$dlquality" = 320 ]; then
				fallbackquality="128"
				bitrate="128"
			fi
			if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$fallbackquality" >/dev/null; then
				sleep $dlcheck
				let l=0
				while [[ "$fallback" -le 1 ]]; do
					let l++
					if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
						fallback=2
					else
						sleep 1s
						if [ "$l" = $tracktimeout ]; then
							dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
							if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
								if [ "$fallbackquality" = 128 ]; then
									echo "Error downloading track $tracknumber: $trackname (mp3 128), skipping..."
									error=1
								else
									echo "Error downloading track $tracknumber: $trackname (mp3 320), retrying...as mp3 128"
									fallbackbackup=1
								fi
								find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
							fi
						fi
					fi
				done
			else
				echo "Error sending download to Deezloader-Remix (Attempt 4)"
			fi
		fi
		if [ $fallbackbackup = 1 ]; then
			fallbackquality="128"
			bitrate="128"
			if curl -s --request GET "$deezloaderurl/api/download/?url=$trackurl&quality=$fallbackquality" >/dev/null; then
				sleep $dlcheck
				let l=0
				while [[ "$fallbackbackup" -le 1 ]]; do
					let l++
					if curl -s --request GET "$deezloaderurl/api/queue/" | grep "length\":0,\"items\":\[\]" >/dev/null; then
						fallbackbackup=2
					else
						sleep 1s
						if [ "$l" = $trackfallbacktimout ]; then
							dlid=$(curl -s --request GET "$deezloaderurl/api/queue/" | jq -r ".items | .[] | .queueId")
							if curl -s --request GET "$deezloaderurl/api/canceldownload/?queueId=$dlid" >/dev/null; then
								echo "Error downloading track $tracknumber: $trackname (mp3 128), skipping..."
								error=1
								find "$downloaddir" -type f -iname "*.mp3" -newer "$temptrackfile" -delete
							fi
						fi
					fi
				done
			else
				echo "Error sending download to Deezloader-Remix (Attempt 5)"
			fi
		fi
	else
		echo "Error downloading track $tracknumber: $trackname ($dlquality), skipping..."
		error=1
	fi

	if find "$downloaddir" -iname "*.flac" -newer "$temptrackfile" | read; then
		fallbackqualitytext="FLAC"
	elif find "$downloaddir" -iname "*.mp3" -newer "$temptrackfile" | read; then
		fallbackqualitytext="MP3"
	fi
	if [ $error = 1 ]; then
		echo "$artistname :: $albumname :: $fallbackqualitytext :: $trackname (${trackid[$track]})" >> "download-track-error.log"
	elif find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|mp3\)" -newer "$temptrackfile" | read; then
		echo "Download Track $tracknumber of $tracktotal: $trackname (Format: $fallbackqualitytext; Length: $trackdurationdisplay)"
		Verify
	else
		error=1
		echo "$artistname :: $albumname :: $fallbackqualitytext :: $trackname (${trackid[$track]})" >> "download-track-error.log"
	fi
}

TrackMethod () {
	rm -rf "$downloaddir"/*
	sleep 0.5
	echo "Downloading $tracktotal Tracks..."
	trackid=($(cat "$tempalbumjson" | jq -r ".tracks | .data | .[] | .id"))
	for track in ${!trackid[@]}; do
		tracknumber=$(( $track + 1 ))
		trackname=$(cat "$tempalbumjson" | jq -r ".tracks | .data | .[] | select(.id=="${trackid[$track]}") | .title")
		trackduration=$(cat "$tempalbumjson" | jq -r ".tracks | .data | .[] | select(.id=="${trackid[$track]}") | .duration")
		trackdurationdisplay=$(DurationCalc $trackduration)
		trackurl="https://www.deezer.com/track/${trackid[$track]}"
		tracktimeout=$(($trackduration*$tracktimeoutpercentage/100))
		trackfallbacktimout=$(($tracktimeout*2))
		if [[ "$tracktimeout" -le 60 ]]; then
			tracktimeout="60"
			trackfallbacktimout=$(($tracktimeout*2))
		fi
		if [ -f "$temptrackfile" ]; then
			rm "$temptrackfile"
			sleep 0.1
		fi
		touch "$temptrackfile"
		DownloadURL
		if [ -f "$temptrackfile" ]; then
			rm "$temptrackfile"
			sleep 0.1
		fi
	done
}

Convert () {
	if [ "${quality}" = opus ]; then
		if [ -x "$(command -v opusenc)" ]; then
			if find "${downloaddir}/" -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat (${bitrate}k))"
				for fname in "${downloaddir}"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if opusenc --bitrate $bitrate --vbr --music "$fname" "${fname%.flac}.opus" 2> /dev/null; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.opus" ]; then
							rm "$fname"
						fi
					else
						echo "Conversion failed: $filename, performing cleanup..."
						if [ -f "${fname%.flac}.opus" ]; then
							rm "${fname%.flac}.opus"
						fi
						if [ ! -f "conversion-failure.log" ]; then
							touch "conversion-failure.log"
							chmod 0666 "conversion-failure.log"
						fi
						echo "$artistname :: $albumname :: $quality :: $filename.flac" >> "conversion-failure.log"
					fi
				done
			fi
		else
			echo "ERROR: opus-tools not installed, please install opus-tools to use this conversion feature"
			sleep 5
		fi
	fi
	if [ "${quality}" = aac ]; then
		if [ -x "$(command -v ffmpeg)" ]; then
			if find "${downloaddir}/" -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat (${bitrate}k))"
				for fname in "${downloaddir}"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn -acodec aac -ab ${bitrate}k -movflags faststart "${fname%.flac}.m4a"; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.m4a" ]; then
							rm "$fname"
						fi
					else
						echo "Conversion failed ($quality): $filename, performing cleanup..."
						if [ -f "${fname%.flac}.m4a" ]; then
							rm "${fname%.flac}.m4a"
						fi
						if [ ! -f "conversion-failure.log" ]; then
							touch "conversion-failure.log"
							chmod 0666 "conversion-failure.log"
						fi
						echo "$artistname :: $albumname :: $quality :: $filename.flac" >> "conversion-failure.log"
					fi
				done
			fi
		else
			echo "ERROR: ffmpeg not installed, please install ffmpeg to use this conversion feature"
			sleep 5
		fi
	fi
	if [ "${quality}" = alac ]; then
		if [ -x "$(command -v ffmpeg)" ]; then
			if find "${downloaddir}/" -name "*.flac" | read; then
				echo "Converting: $converttrackcount Tracks (Target Format: $targetformat)"
				for fname in "${downloaddir}"/*.flac; do
					filename="$(basename "${fname%.flac}")"
					if ffmpeg -loglevel warning -hide_banner -nostats -i "$fname" -n -vn -acodec alac -movflags faststart "${fname%.flac}.m4a"; then
						echo "Converted: $filename"
						if [ -f "${fname%.flac}.m4a" ]; then
							rm "$fname"
						fi
					else
						echo "Conversion failed: $filename, performing cleanup..."
						if [ -f "${fname%.flac}.m4a" ]; then
							rm "${fname%.flac}.m4a"
						fi
						if [ ! -f "conversion-failure.log" ]; then
							touch "conversion-failure.log"
							chmod 0666 "conversion-failure.log"
						fi
						echo "$artistname :: $albumname :: $quality :: $filename.flac" >> "conversion-failure.log"
					fi
				done
			fi
		else
			echo "ERROR: ffmpeg not installed, please install ffmpeg to use this conversion feature"
			sleep 5
		fi
	fi
}

Verify () {
	if [ $trackdlfallback = 0 ]; then
		if find "$downloaddir" -iname "*.flac" | read; then
			if ! [ -x "$(command -v flac)" ]; then
				echo "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
			else
				for fname in "${downloaddir}"/*.flac; do
					filename="$(basename "$fname")"
					if flac -t --totally-silent "$fname"; then
						echo "Verified Track: $filename"
					else
						echo "Track Verification Error: \"$filename\" deleted...retrying download via track method"
						rm -rf "$downloaddir"/*
						sleep 0.5
						trackdlfallback=1
					fi
				done
			fi
		fi
		if find "$downloaddir" -iname "*.mp3" | read; then
			if ! [ -x "$(command -v mp3val)" ]; then
				echo "MP3VAL verification utility not installed (ubuntu: apt-get install -y mp3val)"
			else
				for fname in "${downloaddir}"/*.mp3; do
					filename="$(basename "$fname")"
					if mp3val -f -nb "$fname" > /dev/null; then
						echo "Verified Track: $filename"
					fi
				done
			fi
		fi
	elif [ $trackdlfallback = 1 ]; then
		if ! [ -x "$(command -v flac)" ]; then
			echo "ERROR: FLAC verification utility not installed (ubuntu: apt-get install -y flac)"
		else
			if find "$downloaddir" -iname "*.flac" -newer "$temptrackfile" | read; then
				find "$downloaddir" -iname "*.flac" -newer "$temptrackfile" -print0 | while IFS= read -r -d '' file; do
					filename="$(basename "$file")"
					if flac -t --totally-silent "$file"; then
						echo "Verified Track $tracknumber of $tracktotal: $trackname (Format: $fallbackqualitytext; Length: $trackdurationdisplay)"
					else
						rm "$file"
						if [ "$enablefallback" = true ]; then
							echo "Track Verification Error: \"$trackname\" deleted...retrying as MP3"
							origdlquality="$dlquality"
							dlquality="320"
							DownloadURL
							dlquality="$origdlquality"
						else
							echo "Verification Error: \"$trackname\" deleted..."
							echo "Fallback quality disabled, skipping..."
							echo "$artistname :: $albumname :: $fallbackqualitytext :: $trackname (${trackid[$track]})" >> "download-track-error.log"
						fi
					fi
				done
			fi
		fi
		if ! [ -x "$(command -v mp3val)" ]; then
			echo "MP3VAL verification utility not installed (ubuntu: apt-get install -y mp3val)"
		else
			if find "$downloaddir" -iname "*.mp3" -newer "$temptrackfile" | read; then
				find "$downloaddir" -iname "*.mp3" -newer "$temptrackfile" -print0 | while IFS= read -r -d '' file; do
					filename="$(basename "$file")"
					if mp3val -f -nb "$file" > /dev/null; then
						echo "Verified Track $tracknumber of $tracktotal: $trackname (Format: $fallbackqualitytext; Length: $trackdurationdisplay)"
					fi
				done
			fi
		fi
	fi
}

DLArtistArtwork () {
	if [ -d "$fullartistpath" ]; then
		if [ ! -f "$fullartistpath/folder.jpg"  ]; then
			echo ""
			echo "Archiving Artist Profile Picture"
			if curl -sL --fail "${artistartwork}" -o "$fullartistpath/folder.jpg"; then
				if find "$fullartistpath/folder.jpg" -type f -size -16k | read; then
					echo "ERROR: Artist artwork is smaller than \"16k\""
					rm "$fullartistpath/folder.jpg"
					echo ""
				else
					echo "Downloaded 1 profile picture"
					echo ""
				fi
			else
				echo "Error downloading artist artwork"
				echo ""
			fi
		fi
	fi

}

DLAlbumArtwork () {
	if curl -sL --fail "${albumartworkurl}" -o "$downloaddir/folder.jpg"; then
		sleep 0.1
	else
		echo "Failed downloading album cover picture..."
	fi
}

Replaygain () {
	if ! [ -x "$(command -v flac)" ]; then
		echo "ERROR: METAFLAC replaygain utility not installed (ubuntu: apt-get install -y flac)"
	elif find "$downloaddir" -name "*.flac" | read; then
		find "$downloaddir" -name "*.flac" -exec metaflac --add-replay-gain "{}" + && echo "Replaygain: $replaygaintrackcount Tracks Tagged"
	fi
}

DurationCalc () {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days and ' $D
  (( $H > 0 )) && printf '%d:' $H
  (( $M > 0 )) && printf '%02d:' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf ''
  printf '%02ds\n' $S
}

if [ "${LyricType}" = explicit ]; then
	LyricDLType="Explicit"
elif [ "${LyricType}" = clean ]; then
	LyricDLType="Clean"
else
	LyricDLType="Explicit Preferred"
fi

if [ "$VerifyTrackCount" = "true" ]; then
	vtc="Enabled"
else
	vtc="Disabled"
fi

if [ "$upgrade" = "true" ]; then
	dlupgrade="Enabled"
else
	dlupgrade="Disabled"
fi

ConfigSettings () {
	echo "START DEEZER ARCHIVING"
	echo ""
	echo "Global Settings"
	echo "Download Client: $deezloaderurl"
	echo "Download Directory: $downloaddir"
	echo "Download Quality: $targetformat"
	if [ "$quality" = "opus" ]; then
		echo "Download Bitrate: ${bitrate}k"
	elif [ "$quality" = "aac" ]; then
		echo "Download Bitrate: ${bitrate}k"
	elif [ "$quality" = "mp3" ]; then
		echo "Download Bitrate: ${bitrate}k"
	else
		echo "Download Bitrate: ${bitrate}"
	fi
	echo "Download Track Count Verification: $vtc"
	echo "Download Quality Upgrade: $dlupgrade"
	echo "Download Lyric Type: $LyricDLType"
	if [ "$TagWithBeets" = true ]; then
		echo "Beets Tagging: Enabled"
	else
		echo "Beets Tagging: Disabled"
	fi
	if [ "$KeepOnlyBeetsMatched" = true ]; then
		echo "Beets Skip Unmatched Files: Enabled"
	else
		echo "Beets Skip Unmatched Files: Disabled"
	fi
	if [ "$BeetsDeDupe" = true ]; then
		echo "Beets Deduping: Enabled"
	else
		echo "Beets Deduping: Disabled"
	fi
	echo "Total Artists To Process: $TotalLidArtistNames"
	echo ""
	echo "Begin archive process..."
	sleep 5s
}

if [ ! -d "$downloaddir" ];	then
	mkdir -p "$downloaddir"
	chmod 0777 "$downloaddir"
fi

lidarrartists () {

	if [ -f "$tempartistjson" ]; then
		rm "$tempartistjson"
	fi
	if [ -f "$tempalbumlistjson" ]; then
		rm "$tempalbumlistjson"
	fi
	if [ -f "$tempalbumjson"  ]; then
		rm "$tempalbumjson"
	fi
	if [ -f "$temptrackfile" ]; then
		rm "$temptrackfile"
	fi
	if [ -f "$beetslibraryfile" ]; then
		rm "$beetslibraryfile"
	fi
	if [ -f "$beetslog" ]; then
		rm "$beetslog"
	fi
	rm -rf "$downloaddir"/*
	
	if curl -sL --fail "https://api.deezer.com/artist/$DeezerArtistID" -o "$tempartistjson"; then
		artistartwork=($(cat "$tempartistjson" | jq -r '.picture_xl'))
		artistname="$(cat "$tempartistjson" | jq -r '.name')"
		artistid="$(cat "$tempartistjson" | jq -r '.id')"
		artistalbumtotal="$(cat "$tempartistjson" | jq -r '.nb_album')"
		sanatizedartistname="$(echo "$artistname" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
		shortartistpath="$artistname ($artistid)"
		fullartistpath="$LidArtistPath"		
		sanatizedlidarrartistname="$(echo "$LidArtistNameCap" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
		
		if [ -d "$fullartistpath" ]; then
			if [ -f "$fullartistpath/$tempartistjson" ]; then
				if [ "$upgrade" = true ]; then
					sleep 0.1
				else
					archivealbumtotal="$(cat "$fullartistpath/$tempartistjson" | jq -r '.nb_album')"
					if [ "$artistalbumtotal" = "$archivealbumtotal" ]; then
						echo "${artistnumber}/${TotalLidArtistNames}: Skipping \"$artistname\"... no new albums albums to process..."
						return
					fi
				fi
			fi
			if find "$fullartistpath" -iname "$tempalbumjson" | read; then
				if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
					rm "$fullartistpath/$artistalbumlistjson"
					sleep 0.1
				fi
				jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
			else
				if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
					rm "$fullartistpath/$artistalbumlistjson"
					sleep 0.1
				fi
			fi
		fi
		
		if [ "$artistname" == null ]; then
			echo ""
			echo "Error no artist returned with Deezer Artist ID \"$artistid\""
		else
			if [ -f "$tempalbumlistjson" ]; then
				rm "$tempalbumlistjson"
				sleep 0.1
			fi
						
			if curl -sL --fail "https://api.deezer.com/artist/$artistid/albums&limit=1000" -o "$tempalbumlistjson"; then
				if [ "$LyricType" = explicit ]; then
					LyricDLType=" Explicit"
					albumlist=($(cat "$tempalbumlistjson" | jq -r ".data | .[]| select(.explicit_lyrics==true)| .id"))
					totalnumberalbumlist=($(cat "$tempalbumlistjson" | jq -r ".data | .[]| select(.explicit_lyrics==true)| .id" | wc -l))
				elif [ "$LyricType" = clean ]; then
					LyricDLType=" Clean"
					albumlist=($(cat "$tempalbumlistjson" | jq -r ".data | .[]| select(.explicit_lyrics==false)| .id"))
					totalnumberalbumlist=($(cat "$tempalbumlistjson" | jq -r ".data | .[]| select(.explicit_lyrics==false)| .id" | wc -l))
				else
					LyricDLType=""
					albumlist=($(cat "$tempalbumlistjson" | jq -r ".data | sort_by(.explicit_lyrics) | reverse | .[] | .id"))
					totalnumberalbumlist=($(cat "$tempalbumlistjson" | jq -r ".data | sort_by(.explicit_lyrics) | reverse | .[] | .id" | wc -l))
				fi
				if [ "$totalnumberalbumlist" = 0 ]; then
					echo ""
					echo "Archiving: $artistname (ID: $artistid) ($artistnumber of $TotalLidArtistNames)"
					echo "ERROR: No albums found"
					if [ -f "$tempalbumlistjson"  ]; then
						rm "$tempalbumlistjson"
					fi
					if [ -f "$tempalbumlistjson"  ]; then
						rm "$tempalbumlistjson"
					fi
					sleep 0.1
					continue
				fi
				
				if [ -d "$fullartistpath" ]; then
					if [ "$BeetsDeDupe" = true ]; then
						rm "$beetslibraryfile"
						rm "$beetslog"
						sleep 0.1
						echo "Importing existing library for beets Dedupe matching"
						beet -c "$beetsconfig" -l "$beetslibraryfile" import -AWC "$fullartistpath" > /dev/null
					fi
				fi
				
				if [ -d "temp" ]; then
					sleep 0.1
					rm -rf "temp"
				fi
				
				for album in ${!albumlist[@]}; do
					if [ ! -d "temp" ]; then
						mkdir -p "temp"
					fi
					if curl -sL --fail "https://api.deezer.com/album/${albumlist[$album]}" -o "temp/${albumlist[$album]}-album.json"; then
						sleep 0.1
					else
						echo "Error getting album information"
					fi				
				done
				
				if [ -f "downloadlist.json" ]; then
					rm "downloadlist.json"
					sleep 0.1
				fi
				
				jq -s '.' temp/*-album.json > "downloadlist.json"
				
				if [ -d "temp" ]; then
					sleep 0.1
					rm -rf "temp"
				fi
				
				orderedalbumlist=($(cat "downloadlist.json" | jq -r "sort_by(.explicit_lyrics, .nb_tracks) | reverse | .[] | .id"))
				
				echo ""
				echo ""
				echo "Archiving: $artistname (ID: $artistid) ($artistnumber of $TotalLidArtistNames)"
				echo "Searching for albums... $totalnumberalbumlist Albums found"
				for album in ${!orderedalbumlist[@]}; do
					trackdlfallback=0
					albumnumber=$(( $album + 1 ))
					albumid="${orderedalbumlist[$album]}"
					albumurl="https://www.deezer.com/album/$albumid"
					albumname=$(cat "$tempalbumlistjson" | jq -r ".data | .[]| select(.id=="$albumid") | .title")
					albumnamesanatized="$(echo "$albumname" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
					sanatizedfuncalbumname="${albumnamesanatized,,}"
						
					rm -rf "$downloaddir"/*
					
					if [ -f "$tempalbumjson" ]; then
						rm "$tempalbumjson"
					fi
						
					if [ "$quality" = flac ]; then
							dlquality="flac"
							bitrate="lossless"
							targetformat="FLAC"
						elif [ "$quality" = mp3 ]; then
							dlquality="320"
							bitrate="320"
							targetformat="MP3"
						elif [ "$quality" = alac ]; then
							dlquality="flac"							
							bitrate="lossless"
							targetformat="ALAC"
						elif [ "$quality" = opus ]; then
							dlquality="flac"
							targetformat="OPUS"
							if [ -z "$bitrate" ]; then
								bitrate="128"
							fi
						elif [ "$quality" = aac ]; then
							dlquality="flac"
							targetformat="AAC"
							if [ -z "$bitrate" ]; then
								bitrate="320"
							fi
						fi
						
					sleep 0.1
						
					if curl -sL --fail "https://api.deezer.com/album/$albumid" -o "$tempalbumjson"; then
							tracktotal=$(cat "$tempalbumjson" | jq -r ".nb_tracks")
							actualtracktotal=$(cat "$tempalbumjson" | jq -r ".tracks.data | .[] | .id" | wc -l)
							albumdartistid=$(cat "$tempalbumjson" | jq -r ".artist | .id")
							albumlyrictype="$(cat "$tempalbumjson" | jq -r ".explicit_lyrics")"
							albumartworkurl="$(cat "$tempalbumjson" | jq -r ".cover_xl")"
							albumdate="$(cat "$tempalbumjson" | jq -r ".release_date")"
							albumyear=$(echo ${albumdate::4})
							albumtype="$(cat "$tempalbumjson" | jq -r ".record_type")"
							albumtypecap="${albumtype^^}"
							albumduration=$(cat "$tempalbumjson" | jq -r ".duration")
							albumdurationdisplay=$(DurationCalc $albumduration)
							albumtimeout=$(($albumduration*$albumtimeoutpercentage/100))
							albumtimeoutdisplay=$(DurationCalc $albumtimeout)
							albumfallbacktimout=$(($albumduration*2))							
							
							if [ "$albumlyrictype" = true ]; then
								albumlyrictype="Explicit"
							elif [ "$albumlyrictype" = false ]; then
								albumlyrictype="Clean"
							fi
							
							libalbumfolder="$sanatizedlidarrartistname - $albumtypecap - $albumyear - $albumnamesanatized ($albumlyrictype)"
							
							if [ "$albumdartistid" -ne "$artistid" ]; then
								continue
							fi
							
							if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
							
								if cat "$fullartistpath/$artistalbumlistjson" | grep "$albumid" | read; then
									archivequality="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$albumid) | .dlquality")"
									archivefoldername="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$albumid) | .foldername")"
									archivebitrate="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$albumid) | .bitrate")"
									archivetrackcount=$(find "$fullartistpath/$archivefoldername" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
									if [ "$upgrade" = true ]; then
										if [ "$targetformat" = "$archivequality" ]; then
											if [ "$archivebitrate" = "lossless" ]; then											
												if [ "$VerifyTrackCount" = true ]; then												
													if [ "$tracktotal" = "$archivetrackcount" ]; then
														echo "Previously Downloaded \"$albumname\", skipping..."
														continue
													else
														echo ""
														echo "ERROR: Archived Track Count ($archivetrackcount) and Album Track Count ($tracktotal) do not match, missing files... attempting re-download..."
														echo ""
														if [ -d "$fullartistpath/$archivefoldername" ]; then
															rm -rf "$fullartistpath/$archivefoldername"
															sleep 0.1
														fi
														if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
															rm "$fullartistpath/$artistalbumlistjson"
															sleep 0.1
														fi
														jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
													fi
												else
													echo "Previously Downloaded \"$albumname\", skipping..."
													continue
												fi
											elif [ "${bitrate}k" = "$archivebitrate" ]; then
												if [ "$VerifyTrackCount" = true ]; then
													if [ "$tracktotal" = "$archivetrackcount" ]; then
														echo "Previously Downloaded \"$albumname\", skipping..."
														continue
													else
														echo ""
														echo "ERROR: Archived Track Count ($archivetrackcount) and Album Track Count ($tracktotal) do not match, missing files... attempting re-download..."
														echo ""
														if [ -d "$fullartistpath/$archivefoldername" ]; then
															rm -rf "$fullartistpath/$archivefoldername"
															sleep 0.1
														fi
														if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
															rm "$fullartistpath/$artistalbumlistjson"
															sleep 0.1
														fi
														jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
													fi
												else
													echo "Previously Downloaded \"$albumname\", skipping..."
													continue
												fi
											else
												echo ""
												echo "Previously Downloaded \"$albumname\", does not match requested quality... attempting upgrade..."
												echo ""
												if [ -d "$fullartistpath/$archivefoldername" ]; then
													rm -rf "$fullartistpath/$archivefoldername"
													sleep 0.1
												fi
												if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
													rm "$fullartistpath/$artistalbumlistjson"
													sleep 0.1
												fi
												jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
											fi
										else
											echo ""
											echo "Previously Downloaded \"$albumname\", does not match requested quality... attempting upgrade..."
											echo ""
											if [ -d "$fullartistpath/$archivefoldername" ]; then
												rm -rf "$fullartistpath/$archivefoldername"
												sleep 0.1
											fi
											if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
												rm "$fullartistpath/$artistalbumlistjson"
												sleep 0.1
											fi
											jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
										fi
									elif [ "$VerifyTrackCount" = true ]; then												
										if [ "$tracktotal" = "$archivetrackcount" ]; then
											echo "Previously Downloaded \"$albumname\", skipping..."
											continue
										else
											echo ""
											echo "ERROR: Archived Track Count ($archivetrackcount) and Album Track Count ($tracktotal) do not match, missing files... attempting re-download..."
											echo ""
											if [ -d "$fullartistpath/$archivefoldername" ]; then
												rm -rf "$fullartistpath/$archivefoldername"
												sleep 0.1
											fi
											if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
												rm "$fullartistpath/$artistalbumlistjson"
												sleep 0.1
											fi
											jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
										fi
									else
										echo "Previously Downloaded \"$albumname\", skipping..."
										continue
									fi
								fi
							fi
							
							if [ "$VerifyTrackCount" = true ]; then
								if [ "$tracktotal" -ne "$actualtracktotal" ]; then
									continue
								fi
							fi

							if [ -f "$fullartistpath/$artistalbumlistjson" ]; then
								if [ "$debug" = "true" ]; then
									echo ""
								fi
								
								archivealbumid="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.record_type==\"$albumtype\") | select(.sanatized_album_name==\"$sanatizedfuncalbumname\") | .id")"
								if [ ! -z "$archivealbumid" ]; then
									archivealbumname="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$archivealbumid) | .title")"
									archivealbumlyrictype="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$archivealbumid) | .explicit_lyrics")"
									archivealbumtracktotal="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$archivealbumid) | .nb_tracks")"
									archivealbumreleasetype="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$archivealbumid) | .record_type")"
									archivealbumdate="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$archivealbumid) | .release_date")"
									archivealbumfoldername="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | select(.id==$archivealbumid) | .foldername")"
									archivealbumyear="$(echo ${archivealbumdate::4})"
									
									if [ "$archivealbumlyrictype" = true ]; then
										archivealbumlyrictype="Explicit"
									elif [ "$archivealbumlyrictype" = false ]; then
										archivealbumlyrictype="Clean"
									fi
									
									if [ "$debug" = "true" ]; then
										echo ""
										echo "Dedupe info:"
										echo "Incoming Album: $albumname"
										echo "Incoming Album: $sanatizedfuncalbumname"
										echo "Incoming Album: $tracktotal Tracks"
										echo "Incoming Album: $albumtype"
										echo "Incoming Album: $albumlyrictype"
										echo "Incoming Album: $albumyear"
										echo "Incoming Album: $libalbumfolder"
										echo ""
										echo "Archive: $archivealbumname"
										echo "Archive: $archivealbumtracktotal Tracks"
										echo "Archive: $archivealbumreleasetype"
										echo "Archive: $archivealbumlyrictype"
										echo "Archive: $archivealbumyear"
										echo "Archive: $archivealbumfoldername"
										echo ""
									fi
									
									if [ "$albumlyrictype" = "Explicit" ]; then
										if [ "$debug" = "true" ]; then
											echo "Dupe found $albumname :: check 1"
										fi
										if [ "$archivealbumlyrictype" = "Clean" ]; then
											if [ "$debug" = "true" ]; then
												echo "Incoming album is explicit, exixsiting is clean, upgrading... :: check 2"
											fi
											rm -rf "$fullartistpath/$archivealbumfoldername"
											sleep 0.1
										else										
											if [ "$albumyear" -eq "$archivealbumyear" ]; then
												if [ "$debug" = "true" ]; then
													echo "Incoming album: $albumname has same year as existing :: check 3"
												fi
												if [ "$tracktotal" -gt "$archivealbumtracktotal" ]; then
													if [ "$debug" = "true" ]; then
														echo "Incoming album: $albumname, has more total tracks: $tracktotal vs $archivealbumtracktotal :: check 4"
													fi
													rm -rf "$fullartistpath/$archivealbumfoldername"
													sleep 0.1
												else
													continue
												fi
											else
												if [ "$debug" = "true" ]; then
													echo "Year does not match new: $albumyear; archive: $arhcivealbumyear :: check 5"
												fi
											fi
										fi
									fi
									
									if [ "$albumlyrictype" = "Clean" ]; then
										if [ "$debug" = "true" ]; then
											echo "Dupe found $albumname :: check 10"
										fi
										if [ "$archivealbumlyrictype" = "Explicit" ]; then
											if [ "$debug" = "true" ]; then
												echo "Archived album: $archivealbumname is Explicit, Skipping... :: check 11"
											fi
											continue											
										fi
										
										if [ "$albumyear" -eq "$archivealbumyear" ]; then
											if [ "$debug" = "true" ]; then
												echo "Incoming album: $albumname has same year as existing :: check 12"
											fi
											if [ "$tracktotal" -gt "$archivealbumtracktotal" ]; then
												if [ "$debug" = "true" ]; then
													echo "Incoming album: $albumname, has more total tracks: $tracktotal vs $archivealbumtracktotal :: check 13"
												fi
												rm -rf "$fullartistpath/$archivealbumfoldername"
												sleep 0.1
											else
												continue
											fi
										else
											if [ "$debug" = "true" ]; then
												echo "Year does not match new: $albumyear; archive: $arhcivealbumyear :: check 14"
											fi
										fi
										
									fi
								fi
								
								if [ "$debug" = "true" ]; then
									echo ""
									sleep 3
								fi
							fi
							
							if [[ "$albumtimeout" -le 60 ]]; then
								albumtimeout="60"
								albumfallbacktimout=$(($albumtimeout*2))
								albumtimeoutdisplay=$(DurationCalc $albumtimeout)
							fi
							if [ ! -f "$tempalbumfile" ]; then
								touch "$tempalbumfile"
							fi
							echo ""
							echo "Archiving \"$artistname\" (ID: $artistid) ($artistnumber of $TotalLidArtistNames) in progress..."
							echo "Archiving Album: $albumname (ID: $albumid)"
							echo "Album Link: $albumurl"
							echo "Album Release Year: $albumyear"
							echo "Album Release Type: $albumtype"
							echo "Album Lyric Type: $albumlyrictype"
							echo "Album Duration: $albumdurationdisplay"
							echo "Album Track Count: $tracktotal"
							
							AlbumDL
							
							if [ $trackdlfallback = 1 ]; then
								TrackMethod
							fi							
							DLAlbumArtwork		
							downloadedtrackcount=$(find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
							downloadedlyriccount=$(find "$downloaddir" -type f -iname "*.lrc" | wc -l)
							downloadedalbumartcount=$(find "$downloaddir" -type f -iname "folder.*" | wc -l)
							replaygaintrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
							converttrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
							echo "Downloaded: $downloadedtrackcount Tracks"
							echo "Downloaded: $downloadedlyriccount Synced Lyrics"
							echo "Downloaded: $downloadedalbumartcount Album Cover"										
								
							if [ "$VerifyTrackCount" = true ]; then
								if [ "$tracktotal" -ne "$downloadedtrackcount" ]; then
									echo "ERROR: Downloaded Track Count ($downloadedtrackcount) and Album Track Count ($tracktotal) do not match, missing files... re-attempt download as individual tracks..."
									rm -rf "$downloaddir"/*
									sleep 0.1
									trackdlfallback=1
									TrackMethod
									DLAlbumArtwork
									downloadedtrackcount=$(find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" | wc -l)
									downloadedlyriccount=$(find "$downloaddir" -type f -iname "*.lrc" | wc -l)
									downloadedalbumartcount=$(find "$downloaddir" -type f -iname "folder.*" | wc -l)
									replaygaintrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
									converttrackcount=$(find "$downloaddir" -type f -iname "*.flac" | wc -l)
									echo "Downloaded: $downloadedtrackcount Tracks"
									echo "Downloaded: $downloadedlyriccount Synced Lyrics"
									echo "Downloaded: $downloadedalbumartcount Album Cover"
									if [ "$tracktotal" -ne "$downloadedtrackcount" ]; then
										echo "ERROR: Downloaded Track Count ($downloadedtrackcount) and Album Track Count ($tracktotal) do not match, missing files... skipping import..."
										rm -rf "$downloaddir"/*
										sleep 0.1
										continue
									fi
								fi
							fi														
							
							beetsmatched="false"
							
							if  [ "$TagWithBeets" = true ]; then
							
								if [ "$BeetsDeDupe" != true ]; then
									if [ -f "$beetslibraryfile" ]; then
										rm "$beetslibraryfile"
										sleep 0.1
									fi
									if [ -f "$beetslog" ]; then 
										rm "$beetslog"
										sleep 0.1
									fi
								fi
								
								if [ -f "$downloaddir/beets-match" ]; then 
									rm "$downloaddir/beets-match"
									sleep 0.1
								fi
								
								touch "$downloaddir/beets-match"
								
								sleep 0.1
								
								beet -c "$beetsconfig" -l "$beetslibraryfile" import -q "$downloaddir" > /dev/null
								
								if find "$downloaddir" -type f -iregex ".*/.*\.\(flac\|mp3\)" -newer "$downloaddir/beets-match" | read; then 
									beetsmatched="true"
									echo "Tagged with Beets"
								else
									beetsmatched="false"
									echo "Error: Unable to match with Beets"
									
									if [ "$KeepOnlyBeetsMatched" = true ]; then
										rm -rf "$downloaddir"/*
										sleep 0.1
										continue
									fi
								fi
								
								if [ -f "$downloaddir/beets-match" ]; then 
									rm "$downloaddir/beets-match"
									sleep 0.1
								fi
								
								if [ "$BeetsDeDupe" != true ]; then
									if [ -f "$beetslibraryfile" ]; then
										rm "$beetslibraryfile"
										sleep 0.1
									fi
									if [ -f "$beetslog" ]; then 
										rm "$beetslog"
										sleep 0.1
									fi
								fi
								
							fi
							
							if [ "$replaygaintaggingflac" = true ]; then
								if [ "$quality" = flac ]; then
									Replaygain
								fi
							fi
							
							if [ "$replaygaintaggingopus" = true ]; then
								if [ "$quality" = opus ]; then
									Replaygain
								fi
							fi
							
							Convert

							if [ -d "$fullartistpath/$libalbumfolder" ]; then
								rm -rf "$fullartistpath/$libalbumfolder"
								sleep 0.5s
							fi
							
							mkdir -p "$fullartistpath/$libalbumfolder"
							
							for file in "$downloaddir"/*; do
								mv "$file" "$fullartistpath/$libalbumfolder"/
							done
							
							if find "$fullartistpath/$libalbumfolder" -iname "*.mp3" | read; then
								archivequality="MP3"
								archivebitrate="${bitrate}k"
							elif find "$fullartistpath/$libalbumfolder" -iname "*.flac" | read; then
								archivequality="FLAC"
								archivebitrate="${bitrate}"
							elif find "$fullartistpath/$libalbumfolder" -iname "*.opus" | read; then
								archivequality="OPUS"
								archivebitrate="${bitrate}k"
							elif find "$fullartistpath/$libalbumfolder" -iname "*.m4a" | read; then
								if [ "$quality" = alac ]; then
									archivequality="ALAC"
									archivebitrate="${bitrate}"
								fi
								if [ "$quality" = aac ]; then
									archivequality="AAC"
									archivebitrate="${bitrate}k"
									
								fi
							fi
							echo "Archiving Album: $albumname (Format: $archivequality ($archivebitrate)) complete!"
							
							jq ". + {\"sanatized_album_name\": \"$sanatizedfuncalbumname\"} + {\"foldername\": \"$libalbumfolder\"} + {\"artistpath\": \"$fullartistpath\"} + {\"dlquality\": \"$archivequality\"} + {\"bitrate\": \"$archivebitrate\"} + {\"beetsmatched\": \"$beetsmatched\"}" "$tempalbumjson" > "$fullartistpath/$libalbumfolder/$tempalbumjson"
							
							if [ -f "$tempalbumfile" ]; then
								rm "$tempalbumfile"
							fi
							rm -rf "$downloaddir"/*
							sleep 0.1
						else
							echo "Error contacting Deezer for album information"
						fi
					if [ -d "$fullartistpath" ]; then
						jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
					fi
					if [ -f "$tempalbumjson" ]; then
						rm "$tempalbumjson"
					fi
					if [ -d "$fullartistpath" ]; then	
						find "$fullartistpath" -type d -exec chmod 0777 "{}" \;
						find "$fullartistpath" -type f -exec chmod 0666 "{}" \;
					fi
				done
				
				DLArtistArtwork
				if [ -d "$fullartistpath" ]; then
					totalalbumsarchived="$(cat "$fullartistpath/$artistalbumlistjson" | jq -r ".[] | .id" | wc -l)"
					echo ""
					if [ "$totalalbumsarchived" = "$totalnumberalbumlist" ]; then
						echo "Archived $totalalbumsarchived Albums"
					else
						echo "Archived $totalalbumsarchived of $totalnumberalbumlist Albums (Some Dupes found... and removed...)"
					fi
				fi
				echo "Archiving $artistname complete!"
				echo ""
				if [ -d "$fullartistpath" ]; then
					find "$fullartistpath" -type d -exec chmod 0777 "{}" \;
					find "$fullartistpath" -type f -exec chmod 0666 "{}" \;
				fi
				if [ -f "$tempalbumlistjson"  ]; then
					rm "$tempalbumlistjson"
					sleep 0.1
				fi
				if [ -f "$tempalbumfile" ]; then
					rm "$tempalbumfile"
					sleep 0.1
				fi
				if [ -f "downloadlist.json" ]; then
					rm "downloadlist.json"
					sleep 0.1
				fi
			fi
		fi
	else
		echo "Error contacting Deezer for artist information"
	fi
	if [ -d "$fullartistpath" ]; then
		if [ -f "$fullartistpath/$tempartistjson" ]; then
			rm "$fullartistpath/$tempartistjson"
			sleep 0.1
		fi
		if [ -f "$tempartistjson"  ]; then
			mv "$tempartistjson" "$fullartistpath"/
		fi
		if [ -d "$fullartistpath" ]; then
			jq -s '.' "$fullartistpath"/*/"$tempalbumjson" > "$fullartistpath/$artistalbumlistjson"
		fi
		
		LidarrProcessIt=$(curl -s $LidarrUrl/api/v1/command -X POST -d "{\"name\": \"RefreshArtist\", \"artistID\": \"${LidArtistID}\"}" --header "X-Api-Key:${LidarrApiKey}" );
		echo "Notified Lidarr to scan ${LidArtistNameCap}"
		
	fi
	sleep 0.1
}

ArtistsLidarrReq

#####################################################################################################
#                                              Script End                                           #
#####################################################################################################
exit 0
