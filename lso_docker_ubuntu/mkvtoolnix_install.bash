#!/bin/bash
echo ""
echo "==========INSTALLING TOOLS==========="
if ! [ -x "$(command -v mkvmerge)" ]
	then
		echo "Installing mkvtoolnix..."
		apt-get update -qq
		if apt-get -y install mkvtoolnix; then
			echo " "
			echo "INSTALLATION SUCCESSFUL"
		else
			echo " "
			echo "ERROR: INSTALLTION UNSUCCESSFUL"
		fi
		apt-get purge --auto-remove -y
		apt-get clean
	else
		echo "mkvtoolnix already installed"
fi
echo ""
echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
