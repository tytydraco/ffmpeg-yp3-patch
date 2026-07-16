#!/usr/bin/env bash
# Dev build (glibc): produces local/bin/ffmpeg using system codec libraries.
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PREFIX="$SCRIPT_DIR/local"
BUILD="$SCRIPT_DIR/.build"
JOBS="$(nproc)"

build_x264() {
    prefix="$1"
    workdir="${2:-/tmp/x264-build}"

    mkdir -p "$workdir"
    cd "$workdir" || true

    [ ! -d x264-yp3-patch ] && git clone "https://github.com/tytydraco/x264-yp3-patch"
    cd x264-yp3-patch || true

    ./configure \
        --prefix="$prefix" \
        --enable-static \
        --disable-cli \
        --disable-opencl
    make -j"${JOBS:-$(nproc)}"
    make install
}

fetch_ffmpeg() {
    dest="$1"

    version="ffmpeg-8.1.tar.xz"

    url="${FFMPEG_URL:-"https://ffmpeg.org/releases/$version"}"
    tarball="${FFMPEG_TARBALL:-"$version"}"
    srcdir="${FFMPEG_SRCDIR:-"${version%.tar.xz}"}"

    mkdir -p "$(dirname "$dest")"
    work="$(dirname "$dest")"

    if [ -d "$dest/.ffmpeg-fetched" ]; then
        return 0
    fi

    cd "$work" || true
    if [ ! -f "$tarball" ]; then
        echo "Downloading $url ..."
        curl -fsSL "$url" -o "$tarball"
    fi

    rm -rf "$srcdir"
    tar xf "$tarball"
    rm -rf "$dest"
    mv "$srcdir" "$dest"
    touch "$dest/.ffmpeg-fetched"
    echo "ffmpeg sources ready at $dest"
}

build_x264 "$PREFIX" "$BUILD/x264"
fetch_ffmpeg "$BUILD/ffmpeg"

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

cd "$BUILD/ffmpeg"
make distclean 2>/dev/null || true
./configure \
    --prefix="$PREFIX" \
    --enable-gpl \
    --enable-libx264 \
    --enable-libdav1d \
    --enable-libopus \
    --enable-libvpx \
    --enable-libvorbis \
    --enable-libmp3lame \
    --disable-doc \
    --extra-cflags="-I$PREFIX/include" \
    --extra-ldflags="-L$PREFIX/lib"
make -j"$JOBS"
make install

echo "Installed: $PREFIX/bin/ffmpeg"