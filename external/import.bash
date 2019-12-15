#!/bin/bash
source /config/scripts/lidarr-download-automation/config
if [ "$(ls -A "${DownloadDir}")" ]; then
	if [ -f /config/scripts/beets/library.blb ]; then
		rm /config/scripts/beets/library.blb
		sleep 1s
	fi
	if [ -f /config/scripts/beets/beets.log ]; then 
		rm /config/scripts/beets/beets.log
		sleep 1s
	fi
	beets=($(find "${DownloadDir}" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" -newer "${DownloadDir}/temp-hold" -printf '%h\n' | sed -e "s/'/\\'/g" -e 's/\$/\$/g' | sort -u))
	for beetdir in "${beets[@]}"; do
		beet -c /config/scripts/beets/config.yaml -d "${beetdir}" import -q "${beetdir}"
		if find "$dir" -type f -iname "*.MATCHED.*" | read; then
			logit "Matched with beets!"
		else
			logit "Unable to match using beets to a musicbrainz relase, deleting..."
			rm -rf "${beetdir}"
		fi
	done
fi
