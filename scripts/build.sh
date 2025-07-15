#!/bin/bash

# lint.sh
# Bash equivalent of lint.ps1

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call compile-with-analysis.sh with the project path
exec "$SCRIPT_DIR/compile-with-analysis.sh" "$SCRIPT_DIR/../app"