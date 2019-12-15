#!/bin/bash
source /config/scripts/lidarr-download-automation/config
if [ "$(ls -A "${DownloadDir}")" ]; then
	beets=($(find "${DownloadDir}" -type f -iregex ".*/.*\.\(flac\|opus\|m4a\|mp3\)" -newer "${DownloadDir}/temp-hold" -printf '%h\n' | sed -e "s/'/\\'/g" -e 's/\$/\$/g' | sort -u))
	for beetdir in "${beets[@]}"; do
		logit "Attempting to match using beets..."
		beet -c /config/scripts/beets/config.yaml -d "${beetdir}" import -q "${beetdir}"
		if find "${beetdir}" -type f -iname "*.MATCHED.*" | read; then
			logit "SUCCESS: Matched with beets!"
		else
			logit "ERROR: Unable to match using beets to a musicbrainz release, deleting..."
			rm -rf "${beetdir}"
		fi
	done
fi
