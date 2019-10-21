#!/bin/bash
echo "==========INSTALLING TOOLS==========="
if ! [ -x "$(command -v mkvmerge)" ]
	then
		echo "Installing mkvtoolnix..."
		apt-get update -qq
		if { apt-get -y install mkvtoolnix; }; then
			apt-get purge --auto-remove -y
			apt-get clean
			echo "INSTALLATION SUCCESSFUL"
		else
			echo "ERROR: INSTALLTION UNSUCCESSFUL"
		fi
	else
		echo "mkvtoolnix already installed"
fi
echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
