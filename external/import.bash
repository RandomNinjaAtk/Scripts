#!/bin/bash
if [ "$(ls -A "${DownloadDir}")" ]; then
	rm /config/scripts/beets/library.blb
	rm /config/scripts/beets/beets.log
	sleep 1s
	dlloc=($(find "${DownloadDir}" -type d -newer "${DownloadDir}/temp-hold"))
	for dir in "${dlloc[@]}"; do
		beet -c /config/scripts/beets/config.xml -d "$dir" import -q "$dir"
		if find "$dir" -type f -name "*.MATCHED.*" -mindepth 1 -maxdepth 1 | read; then
			logit "Matched with beets!"
		else
			echo "Unable to match using beets to a musicbrainz relase, deleting..."
			rm -rf "$dir"
		fi
	done
fi
