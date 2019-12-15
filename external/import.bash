#!/bin/bash
if [ "$(ls -A "${DownloadDir}")" ]; then
	if [ -f /config/scripts/beets/library.blb ]; then
		rm /config/scripts/beets/library.blb
		sleep 1s
	fi
	if [ -f /config/scripts/beets/beets.log ]; then 
		rm /config/scripts/beets/beets.log
		sleep 1s
	fi
	dlloc=($(find "${DownloadDir}" -type d -mindepth 1 -maxdepth 1 -newer "${DownloadDir}/temp-hold"))
	for dir in "${dlloc[@]}"; do
		beet -c /config/scripts/beets/config.xml -d "$dir" import -q "$dir"
		if find "$dir" -type f -name "*.MATCHED.*" -mindepth 1 -maxdepth 1 | read; then
			logit "Matched with beets!"
		else
			logit "Unable to match using beets to a musicbrainz relase, deleting..."
			rm -rf "$dir"
		fi
	done
fi
