#!/bin/bash
echo ""
echo "==========INSTALLING TOOLS==========="
if ! [ -x "$(command -v ffmpeg)" ]
	then	
		echo "START INSTALLING FFMPEG"
		apt-get update -qq

		apt-get -y install \
			autoconf \
			automake \
			build-essential \
			cmake \
			git \
			libass-dev \
			libfreetype6-dev \
			libtheora-dev \
			libtool \
			libvorbis-dev \
			mercurial \
			pkg-config \
			texinfo \
			wget \
			zlib1g-dev \
			yasm \
			nasm \
			libx264-dev \
			libx265-dev \
			libnuma-dev \
			libvpx-dev \
			libfdk-aac-dev \
			libmp3lame-dev \
			libopus-dev
			
		mkdir /tmp/build
		cd /tmp/build

		# ACTUAL COMPILATION
		cd /tmp/build
		wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
		tar xjvf ffmpeg-snapshot.tar.bz2
		cd ffmpeg

		PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" ./configure \
		  --prefix="/usr/local" \
		  --pkg-config-flags="--static" \
		  --extra-cflags="-I/usr/local/include" \
		  --extra-ldflags="-L/usr/local/lib" \
		  --extra-libs="-lpthread -lm" \
		  --bindir="/usr/local/bin" \
		  --enable-gpl \
		  --enable-libass \
		  --enable-libfdk-aac \
		  --enable-libfreetype \
		  --enable-libmp3lame \
		  --enable-libopus \
		  --enable-libtheora \
		  --enable-libvorbis \
		  --enable-libvpx \
		  --enable-libx264 \
		  --enable-libx265 \
		  --enable-nonfree

		make
		make install
		hash -r
		echo "DONE"
		cd /
		rm -rf /tmp/build
		apt-get purge --auto-remove -y
		apt-get clean
	else
		echo "FFMPEG ALREADY INSTALLED"
fi
echo ""
echo "=====TOOLS INSTALLATION COMPLETE====="
exit 0