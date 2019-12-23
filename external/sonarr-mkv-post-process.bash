#!/bin/bash
echo "$1"
mkvpropedit "$1" --edit info --set "comment=$sonarr_episodefile_scenename"
exit 0
