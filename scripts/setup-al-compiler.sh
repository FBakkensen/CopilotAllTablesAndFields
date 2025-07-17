#!/bin/bash
set -e

TOOLS_DIR="$HOME/.al-tools"

echo "Setting up AL compiler (latest version)..."

# Install .NET runtime if not present
if ! command -v dotnet &> /dev/null; then
    wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
    chmod +x dotnet-install.sh
    ./dotnet-install.sh --runtime dotnet --version 8.0.0
fi

# Download AL compiler from NuGet
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR"

# Download the latest AL Language VSIX
echo "Downloading latest AL Language extension..."
wget --user-agent="Mozilla/5.0" "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-dynamics-smb/vsextensions/al/latest/vspackage" -O al.vsix.gz

# Check if we got a gzipped file
if file al.vsix.gz | grep -q "gzip compressed"; then
    echo "Decompressing VSIX file..."
    gunzip al.vsix.gz
    mv al.vsix al.vsix.zip
elif file al.vsix.gz | grep -q "Zip archive"; then
    # It's already a zip, just rename
    mv al.vsix.gz al.vsix.zip
else
    echo "Error: Downloaded file is not a valid VSIX/ZIP file"
    echo "File type: $(file al.vsix.gz)"
    exit 1
fi

# Verify it's a valid zip now
if ! unzip -t al.vsix.zip >/dev/null 2>&1; then
    echo "Error: File is not a valid ZIP archive"
    exit 1
fi

# Extract compiler
unzip -o al.vsix.zip
cd extension/bin

# Make compiler executable
chmod +x linux/alc

# Create symlink
sudo ln -sf "$TOOLS_DIR/extension/bin/linux/alc" /usr/local/bin/alc

echo "AL compiler setup complete"