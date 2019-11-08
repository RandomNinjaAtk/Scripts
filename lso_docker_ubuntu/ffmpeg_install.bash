#!/bin/bash
echo "==========INSTALLING TOOLS==========="

echo "INSTALLING FFMPEG"
mkdir /tmp/ffmpeg
curl -o /tmp/ffmpeg/ffmpeg-git-amd64-static.tar.xz https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz
cd /tmp/ffmpeg
tar xvf ffmpeg-git-amd64-static.tar.xz
find "/usr/bin/" -type f -iname "ffmpeg" -exec rm {} \;
find "/usr/bin/" -type f -iname "ffprobe" -exec rm {} \;
find "/tmp/ffmpeg" -type f -iname "ffmpeg" -exec mv {} /usr/bin/ \;
find "/tmp/ffmpeg" -type f -iname "ffprobe" -exec mv {} /usr/bin/ \;
cd /
rm -rf /tmp/ffmpeg

echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0
