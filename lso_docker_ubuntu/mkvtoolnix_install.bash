#!/bin/bash
echo "==========INSTALLING TOOLS==========="
if ! [ -x "$(command -v mkvmerge)" ]; then	
	echo "INSTALLING mkvtoolnix"
	apt-get update -qq && \
	apt-get install -y mkvtoolnix && \		
	apt-get purge --auto-remove -y && \
	apt-get clean
else
	echo "mkvtoolnix ALREADY INSTALLED"
fi
echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
