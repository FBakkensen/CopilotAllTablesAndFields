#!/bin/bash

# compile-with-analysis.sh
# Bash equivalent of compile-with-analysis.ps1

set -e

# Parse command line arguments
PROJECT_PATH=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        *)
            PROJECT_PATH="$1"
            shift
            ;;
    esac
done

# Default to current directory if no project path provided
if [[ -z "$PROJECT_PATH" ]]; then
    PROJECT_PATH="$(pwd)"
fi

echo "Project path: $PROJECT_PATH"

# Check if app.json exists
APP_JSON_PATH="$PROJECT_PATH/app.json"
if [[ ! -f "$APP_JSON_PATH" ]]; then
    echo "Error: app.json not found at $APP_JSON_PATH" >&2
    exit 1
fi

# Parse app.json using jq (install if not available)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq: sudo apt-get install jq" >&2
    exit 1
fi

APP_NAME=$(jq -r '.name' "$APP_JSON_PATH")
APP_VERSION=$(jq -r '.version' "$APP_JSON_PATH")
PUBLISHER=$(jq -r '.publisher' "$APP_JSON_PATH")

if [[ "$APP_NAME" == "null" || "$APP_VERSION" == "null" || "$PUBLISHER" == "null" ]]; then
    echo "Error: Could not parse app.json - missing required fields (name, version, publisher)" >&2
    exit 1
fi

# Construct the output file name (remove invalid characters)
SAFE_APP_NAME=$(echo "$APP_NAME" | sed 's/[\\/:*?"<>|]//g')
OUTPUT_FILE_NAME="${PUBLISHER}_${SAFE_APP_NAME}_${APP_VERSION}.app"

# Find the latest AL extension path
AL_EXTENSION_PATH=$(find "$HOME/.vscode-server/extensions" -maxdepth 1 -name "ms-dynamics-smb.al-*" -type d | sort -V | tail -1)

if [[ -z "$AL_EXTENSION_PATH" ]]; then
    echo "Error: AL extension not found in $HOME/.vscode-server/extensions" >&2
    exit 1
fi

# Find alc binary
ALC_PATH="$AL_EXTENSION_PATH/bin/linux/alc"
if [[ ! -f "$ALC_PATH" ]]; then
    echo "Error: alc not found at $ALC_PATH" >&2
    exit 1
fi

# Make alc executable if it's not already
if [[ ! -x "$ALC_PATH" ]]; then
    echo "Making AL compiler executable..."
    chmod +x "$ALC_PATH"
fi

# Find analyzer DLLs
ANALYZER_DLLS=(
    "Microsoft.Dynamics.Nav.CodeCop.dll"
    "Microsoft.Dynamics.Nav.UICop.dll"
    "Microsoft.Dynamics.Nav.AppSourceCop.dll"
)

ANALYZER_PATHS=()
for dll in "${ANALYZER_DLLS[@]}"; do
    ANALYZER_PATH=$(find "$AL_EXTENSION_PATH" -name "$dll" -type f 2>/dev/null | head -1)
    if [[ -n "$ANALYZER_PATH" ]]; then
        ANALYZER_PATHS+=("/analyzer:\"$ANALYZER_PATH\"")
    else
        echo "Warning: Analyzer '$dll' not found in $AL_EXTENSION_PATH"
    fi
done

# Define other paths
PACKAGE_CACHE_PATH="$PROJECT_PATH/.alpackages"
OUT_PATH="$PROJECT_PATH/$OUTPUT_FILE_NAME"

# Build argument list
ARGS=(
    "/project:\"$PROJECT_PATH\""
    "/out:\"$OUT_PATH\""
    "/packagecachepath:\"$PACKAGE_CACHE_PATH\""
)

# Add analyzer arguments
ARGS+=("${ANALYZER_PATHS[@]}")

echo "Starting AL compilation with full analysis..."
echo "Compiler Path: $ALC_PATH"
echo "Output File:   $OUT_PATH"
echo "Arguments: ${ARGS[*]}"

# Execute the compiler
if "$ALC_PATH" "${ARGS[@]}"; then
    echo "Compilation completed successfully."
    exit 0
else
    EXIT_CODE=$?
    echo "##[error]Compilation failed with exit code $EXIT_CODE." >&2
    exit $EXIT_CODE
fi