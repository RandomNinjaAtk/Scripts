#!/bin/bash
echo "=====FFMPEG INSTALLATION SCRIPT====="
if ! [ -x "$(command -v ffmpeg)" ]; then	
	echo "START INSTALLING FFMPEG"
	apt-get update -qq && apt-get -qq -y install \
		autoconf \
		automake \
		build-essential \
		cmake \
		git-core \
		libass-dev \
		libfreetype6-dev \
		libsdl2-dev \
		libtool \
		libva-dev \
		libvdpau-dev \
		libvorbis-dev \
		libxcb1-dev \
		libxcb-shm0-dev \
		libxcb-xfixes0-dev \
		pkg-config \
		texinfo \
		wget \
		zlib1g-dev

	rm -rf ~/ffmpeg_sources ~/bin ~/ffmpeg_build
	mkdir -p ~/ffmpeg_sources ~/bin && \

	echo "COMPILING NASM"
	cd ~/ffmpeg_sources && \
	wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 && \
	tar xjvf nasm-2.14.02.tar.bz2 && \
	cd nasm-2.14.02 && \
	./autogen.sh && \
	PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
	make && \
	make install
	echo ""
	
	echo "COMPILING YASM"
	cd ~/ffmpeg_sources && \
	wget -O yasm-1.3.0.tar.gz https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
	tar xzvf yasm-1.3.0.tar.gz && \
	cd yasm-1.3.0 && \
	./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
	make && \
	make install
	echo ""
	
	echo "COMPILING X264"
	cd ~/ffmpeg_sources && \
	git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
	cd x264 && \
	PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --enable-pic && \
	PATH="$HOME/bin:$PATH" make && \
	make install
	echo ""
	
	echo "COMPILING X265"
	apt-get -qq -y install mercurial libnuma-dev && \
	cd ~/ffmpeg_sources && \
	if cd x265 2> /dev/null; then hg pull && hg update && cd ..; else hg clone https://bitbucket.org/multicoreware/x265; fi && \
	cd x265/build/linux && \
	PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off ../../source && \
	PATH="$HOME/bin:$PATH" make && \
	make install
	echo ""
	
	echo "COMPILING LIBVPX"
	cd ~/ffmpeg_sources && \
	git -C libvpx pull 2> /dev/null || git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
	cd libvpx && \
	PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
	PATH="$HOME/bin:$PATH" make && \
	make install
	echo ""
	
	echo "COMPILING fdk-aac"
	cd ~/ffmpeg_sources && \
	git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
	cd fdk-aac && \
	autoreconf -fiv && \
	./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
	make && \
	make install
	echo ""

	echo "COMPILING lame"
	cd ~/ffmpeg_sources && \
	wget -O lame-3.100.tar.gz https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
	tar xzvf lame-3.100.tar.gz && \
	cd lame-3.100 && \
	PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm && \
	PATH="$HOME/bin:$PATH" make && \
	make install
	echo ""
	
	echo "COMPILING libopus"
	cd ~/ffmpeg_sources && \
	git -C opus pull 2> /dev/null || git clone --depth 1 https://github.com/xiph/opus.git && \
	cd opus && \
	./autogen.sh && \
	./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
	make && \
	make install
	echo ""
	
	echo "COMPILING av1"
	cd ~/ffmpeg_sources && \
	git -C aom pull 2> /dev/null || git clone --depth 1 https://aomedia.googlesource.com/aom && \
	mkdir -p aom_build && \
	cd aom_build && \
	PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off -DENABLE_NASM=on ../aom && \
	PATH="$HOME/bin:$PATH" make && \
	make install
	echo ""
	
	echo "MOVING BINARIES"
	find "/usr/bin/" -type f -iname "lame" -exec rm {} \;
	find "/usr/bin/" -type f -iname "nasm" -exec rm {} \;
	find "/usr/bin/" -type f -iname "ndisasm" -exec rm {} \;
	find "/usr/bin/" -type f -iname "vsyasm" -exec rm {} \;
	find "/usr/bin/" -type f -iname "x264" -exec rm {} \;
	find "/usr/bin/" -type f -iname "yasm" -exec rm {} \;
	find "/usr/bin/" -type f -iname "ytasm" -exec rm {} \;
	find "$HOME/bin/" -type f -iname "lame" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "nasm" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "ndisasm" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "vsyasm" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "x264" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "yasm" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "ytasm" -exec mv {} /usr/bin/ \;

	echo "COMPILING FFMPEG"
	wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
	tar xjvf ffmpeg-snapshot.tar.bz2 && \
	cd ffmpeg && \
	PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
	--prefix="$HOME/ffmpeg_build" \
	--pkg-config-flags="--static" \
	--extra-cflags="-I$HOME/ffmpeg_build/include" \
	--extra-ldflags="-L$HOME/ffmpeg_build/lib" \
	--extra-libs="-lpthread -lm" \
	--bindir="$HOME/bin" \
	--enable-gpl \
	--enable-libaom \
	--enable-libass \
	--enable-libfdk-aac \
	--enable-libfreetype \
	--enable-libmp3lame \
	--enable-libopus \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libx264 \
	--enable-libx265 \
	--enable-vaapi \
	--enable-nonfree && \

	PATH="/usr/bin:$PATH" make && \
	make install && \
	hash -r
	cd ~/
	rm -rf ~/ffmpeg_sources ~/ffmpeg_build

	find "/usr/bin/" -type f -iname "ffmpeg" -exec rm {} \;
	find "/usr/bin/" -type f -iname "ffprobe" -exec rm {} \;
	find "/usr/bin/" -type f -iname "ffplay" -exec rm {} \;

	find "$HOME/bin/" -type f -iname "ffmpeg" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "ffprobe" -exec mv {} /usr/bin/ \;
	find "$HOME/bin/" -type f -iname "ffplay" -exec mv {} /usr/bin/ \;

else
	echo "ffmpeg already installed"
fi

echo "=====FFMPEG INSTALLATION COMPLETE====="
exit 0
