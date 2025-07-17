#!/bin/bash
set -e

# Business Central Symbol Restoration Script
#
# This script downloads Business Central symbols from Microsoft NuGet feeds using direct .nupkg download and extraction.
# Key behaviors:
# - Always uses REST API for efficient package discovery with flexible matching
#   * Directly queries Microsoft feeds using REST API (no authentication required)
#   * Always returns the most recent version available in the feed
#   * Supports exact matches, partial matches, and GUID-suffixed packages
#   * Filters out country-specific variants (e.g., Microsoft.Application.DK.symbols.{GUID})
#   * Downloads international/base versions only
#   * Downloads .nupkg files directly and extracts .app files to .alpackages folder
# - Supports both Microsoft and AppSource packages with unified discovery methods
# - No nuget.exe dependencies - uses curl for downloads and unzip for extraction
# - Always targets the most recent version for all dependencies (no version pinning)
#
# Key insight: .nupkg files are ZIP files containing .app files. We download them directly,
# extract the .app files to the .alpackages folder, and clean up the temporary files.
# No authentication is required for public Microsoft feeds.
#
# Usage: ./restore-symbols.sh <project-path>

# Check parameters
if [ $# -ne 1 ]; then
    echo "Usage: $0 <project-path>"
    exit 1
fi

PROJECT_PATH="$1"

echo "Restoring symbols for project: $PROJECT_PATH"

# Find app.json - could be in root or app subdirectory
if [ -f "$PROJECT_PATH/app.json" ]; then
    APP_JSON_PATH="$PROJECT_PATH/app.json"
    AL_PROJECT_DIR="$PROJECT_PATH"
elif [ -f "$PROJECT_PATH/app/app.json" ]; then
    APP_JSON_PATH="$PROJECT_PATH/app/app.json"
    AL_PROJECT_DIR="$PROJECT_PATH/app"
else
    echo "Error: app.json not found in $PROJECT_PATH or $PROJECT_PATH/app"
    exit 1
fi

echo "Using app.json from: $APP_JSON_PATH"
echo "AL project directory: $AL_PROJECT_DIR"

# Read BC version from app.json
BC_VERSION=$(jq -r '.application' "$APP_JSON_PATH")
BC_MAJOR_VERSION=$(echo "$BC_VERSION" | cut -d. -f1)
echo "BC Version: $BC_VERSION (Major: $BC_MAJOR_VERSION)"

# Create symbols directory
SYMBOLS_PATH="$AL_PROJECT_DIR/.alpackages"
mkdir -p "$SYMBOLS_PATH"

# Check required tools
if ! command -v curl &> /dev/null; then
    echo "Error: curl not found. This script requires curl to download .nupkg files."
    exit 1
fi

if ! command -v unzip &> /dev/null; then
    echo "Error: unzip not found. This script requires unzip to extract .app files from .nupkg files."
    exit 1
fi

echo "Using curl $(curl --version | head -1)"
echo "Using unzip $(unzip -v | head -1)"

# Check if jq is available for JSON parsing (optional but recommended)
if command -v jq &> /dev/null; then
    echo "Using jq $(jq --version) for JSON parsing"
else
    echo "Warning: jq not available, using basic text parsing (jq recommended for better reliability)"
fi

# Setup NuGet sources using dotnet CLI (more reliable than XML config)
# Direct .nupkg download and extraction approach
# No nuget.exe required - we'll download .nupkg files directly and extract .app files
#
echo "Setting up direct .nupkg download and extraction..."

# Function to download and extract .nupkg directly
# ...existing code...
# Download Microsoft system symbols
# ...existing code...
# Download dependencies from app.json
# ...existing code...
# Verify symbol files are in place (no copying needed - files are already extracted to the correct location)
# ...existing code...
# Clean up temporary files
# ...existing code...
# Count total .app files found
# ...existing code...
# ...existing code...
