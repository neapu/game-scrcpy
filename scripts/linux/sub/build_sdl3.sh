#!/bin/bash
set -e

# Configuration
SDL_REPO_URL="https://github.com/libsdl-org/SDL.git"
if [ -n "$SDL_REPO" ]; then
    SDL_REPO_URL="$SDL_REPO"
fi
SDL_VERSION="release-3.2.28" # Match Windows script version

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
TEMP_DIR="$ROOT_DIR/temp"
INSTALL_DIR="$ROOT_DIR/core/third_party/sdl3"
SOURCE_DIR="$TEMP_DIR/sdl3"
BUILD_DIR="$SOURCE_DIR/build"

# Check if already installed
if [ -f "$INSTALL_DIR/lib/libSDL3.a" ] || [ -f "$INSTALL_DIR/lib64/libSDL3.a" ]; then
    echo "SDL3 appears to be installed in $INSTALL_DIR. Skipping."
    exit 0
fi

# Dependencies check
for cmd in git cmake make gcc; do
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

# Check for libraries required for SDL3
# These are common requirements for a functional SDL3 build on Linux
check_lib "alsa" "libasound2-dev" "alsa-lib-devel" "alsa-lib"
check_lib "libpulse" "libpulse-dev" "pulseaudio-libs-devel" "libpulse"
check_lib "x11" "libx11-dev" "libX11-devel" "libx11"
check_lib "xext" "libxext-dev" "libXext-devel" "libxext"
check_lib "xcursor" "libxcursor-dev" "libXcursor-devel" "libxcursor"
check_lib "xi" "libxi-dev" "libXi-devel" "libxi"
check_lib "xrandr" "libxrandr-dev" "libXrandr-devel" "libxrandr"
check_lib "xinerama" "libxinerama-dev" "libXinerama-devel" "libxinerama"
check_lib "xscrnsaver" "libxss-dev" "libXScrnSaver-devel" "libxscrnsaver"
check_lib "wayland-client" "libwayland-dev" "wayland-devel" "wayland"
check_lib "wayland-scanner" "libwayland-bin" "wayland-devel" "wayland"
check_lib "xkbcommon" "libxkbcommon-dev" "libxkbcommon-devel" "libxkbcommon"

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "Warning: Missing recommended libraries: ${MISSING_DEPS[*]}"
    echo "SDL3 might build with reduced functionality (no audio/video/input)."
    echo "Please install them using your package manager:"
    echo ""
    echo "  Debian/Ubuntu:"
    echo "    sudo apt update && sudo apt install -y ${MISSING_PACKAGES_DEBIAN[*]}"
    echo ""
    echo "  Fedora:"
    echo "    sudo dnf install ${MISSING_PACKAGES_FEDORA[*]}"
    echo ""
    echo "  Arch Linux:"
    echo "    sudo pacman -S ${MISSING_PACKAGES_ARCH[*]}"
    echo ""
    echo "Press Enter to continue anyway, or Ctrl+C to abort..."
    read
fi


# Prepare temp dir
mkdir -p "$TEMP_DIR"

# Clone
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Cloning SDL3 from $SDL_REPO_URL..."
    git clone "$SDL_REPO_URL" "$SOURCE_DIR"
fi

cd "$SOURCE_DIR"
# Checkout version
if [ -n "$SDL_VERSION" ]; then
    echo "Checking out $SDL_VERSION..."
    git checkout "$SDL_VERSION" || echo "Warning: Could not checkout $SDL_VERSION, using HEAD"
fi

# Configure
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Force use of gcc/g++ from PATH if available, instead of /usr/bin/cc
export CC=gcc
export CXX=g++

echo "Configuring SDL3..."
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DSDL_STATIC=ON \
    -DSDL_SHARED=OFF \
    -DSDL_TEST_LIBRARY=OFF \
    -DSDL_DISABLE_INSTALL_DOCS=ON \
    -DCMAKE_BUILD_TYPE=Release

# Build
echo "Building SDL3..."
cmake --build . --config Release --parallel $(nproc)

# Install
echo "Installing SDL3..."
cmake --install .

# Cleanup
cd "$SCRIPT_DIR"
rm -rf "$SOURCE_DIR"

echo "SDL3 build completed."
