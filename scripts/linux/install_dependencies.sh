#!/bin/bash
set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SUB_DIR="$SCRIPT_DIR/sub"

echo "Starting dependencies installation..."

# List of build scripts to run
BUILD_SCRIPTS=(
    "build_ffmpeg.sh"
    "build_sdl3.sh"
)

for script in "${BUILD_SCRIPTS[@]}"; do
    script_path="$SUB_DIR/$script"
    
    if [ -f "$script_path" ]; then
        echo ""
        echo "Running $script..."
        
        # Make executable if not already
        chmod +x "$script_path"
        
        "$script_path"
        
        if [ $? -ne 0 ]; then
            echo "Error: $script failed with exit code $?"
            exit 1
        fi
    else
        echo "Warning: Script $script not found at $script_path"
    fi
done

echo ""
echo "All dependencies installed successfully!"
