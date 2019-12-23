#!/bin/bash
echo "$sonarr_episodefile_path"
echo "$sonarr_episodefile_episodetitles"
echo "$sonarr_episodefile_seasonnumber"
echo "$sonarr_series_title"
echo "sonarr_episodefile_episodenumbers"
mv "$sonarr_episodefile_path" "$sonarr_episodefile_path-temp"
ffmpeg -i "$sonarr_episodefile_path-temp" -codec copy -metadata COMMENT="$sonarr_episodefile_scenename" -metadata TITLE="$sonarr_episodefile_episodetitles" -metadata TRACK="$sonarr_episodefile_episodenumbers" -metadata ALBUM="Season $sonarr_episodefile_seasonnumber" -metadata ARTIST="$sonarr_series_title" "$sonarr_episodefile_path"
rm "$sonarr_episodefile_path-temp"
exit 0
