#!/bin/bash
set -e

# Configuration
FFMPEG_REPO_URL="https://git.ffmpeg.org/ffmpeg.git"
if [ -n "$FFMPEG_REPO" ]; then
    FFMPEG_REPO_URL="$FFMPEG_REPO"
fi

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# SCRIPT_DIR is .../scripts/linux/sub
# .../scripts/linux
# .../scripts
# .../game-scrcpy
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
TEMP_DIR="$ROOT_DIR/temp"
INSTALL_DIR="$ROOT_DIR/core/third_party/ffmpeg"
SOURCE_DIR="$TEMP_DIR/ffmpeg"

# Check if already installed
if [ -f "$INSTALL_DIR/lib/libavcodec.so" ] || [ -f "$INSTALL_DIR/bin/ffmpeg" ]; then
    echo "FFmpeg appears to be installed in $INSTALL_DIR. Skipping."
    exit 0
fi

# Dependencies check
for cmd in git make gcc pkg-config nasm; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not found. Please install it."
        exit 1
    fi
done

# Check system libraries
MISSING_DEPS=()
MISSING_PACKAGES_DEBIAN=()
MISSING_PACKAGES_FEDORA=()
MISSING_PACKAGES_ARCH=()

check_lib() {
    local pkg_name="$1"
    local deb_name="$2"
    local fedora_name="$3"
    local arch_name="$4"

    if ! pkg-config --exists "$pkg_name"; then
        MISSING_DEPS+=("$pkg_name")
        MISSING_PACKAGES_DEBIAN+=("$deb_name")
        MISSING_PACKAGES_FEDORA+=("$fedora_name")
        MISSING_PACKAGES_ARCH+=("$arch_name")
    fi
}

# Check for libraries required for requested features
# x264/x265 are explicitly requested by user logic
# dav1d is recommended for AV1 decoding performance
# libva is required for VAAPI
check_lib "x264" "libx264-dev" "x264-devel" "x264"
check_lib "x265" "libx265-dev" "x265-devel" "x265"
check_lib "dav1d" "libdav1d-dev" "dav1d-devel" "dav1d"
check_lib "libva" "libva-dev" "libva-devel" "libva"

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "Error: Missing required libraries: ${MISSING_DEPS[*]}"
    echo "Please install them using your package manager:"
    echo ""
    echo "  Debian/Ubuntu:"
    echo "    sudo apt update && sudo apt install -y ${MISSING_PACKAGES_DEBIAN[*]}"
    echo "    (Note: libnuma-dev might be required for x265 on some systems)"
    echo ""
    echo "  Fedora:"
    echo "    sudo dnf install ${MISSING_PACKAGES_FEDORA[*]}"
    echo ""
    echo "  Arch Linux:"
    echo "    sudo pacman -S ${MISSING_PACKAGES_ARCH[*]}"
    echo ""
    exit 1
fi


# Prepare temp dir
mkdir -p "$TEMP_DIR"

# Clone
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Cloning FFmpeg from $FFMPEG_REPO_URL..."
    # Clone depth 1 to save time/bandwidth since we just build
    git clone --depth 1 "$FFMPEG_REPO_URL" "$SOURCE_DIR"
fi

cd "$SOURCE_DIR"

# Configure
echo "Configuring FFmpeg..."
# Note: Enabling specific decoders/features as requested.
# VAAPI requires libva-dev installed on the system, but we can't easily check for headers in shell easily without trying.
# We assume the user has development environment set up or will see the error.
./configure \
    --prefix="$INSTALL_DIR" \
    --disable-all \
    --enable-shared \
    --disable-static \
    --enable-gpl \
    --enable-version3 \
    --enable-avcodec \
    --enable-avformat \
    --enable-avutil \
    --enable-swresample \
    --enable-swscale \
    --enable-decoder=h264 \
    --enable-decoder=hevc \
    --enable-decoder=av1 \
    --enable-decoder=aac \
    --enable-decoder=opus \
    --enable-parser=h264 \
    --enable-parser=hevc \
    --enable-parser=av1 \
    --enable-parser=aac \
    --enable-parser=opus \
    --enable-demuxer=h264 \
    --enable-demuxer=hevc \
    --enable-demuxer=av1 \
    --enable-demuxer=aac \
    --enable-demuxer=ogg \
    --enable-demuxer=mov \
    --enable-demuxer=matroska \
    --enable-demuxer=flv \
    --enable-protocol=file \
    --enable-protocol=pipe \
    --enable-vaapi \
    --enable-hwaccel=h264_vaapi \
    --enable-hwaccel=hevc_vaapi \
    --enable-hwaccel=av1_vaapi \
    --disable-debug \
    --disable-doc \
    --disable-programs

# Build
echo "Building FFmpeg..."
make -j$(nproc)

# Install
echo "Installing FFmpeg..."
make install

# Cleanup
cd "$SCRIPT_DIR"
rm -rf "$SOURCE_DIR"

echo "FFmpeg build completed."
