#!/bin/bash
set -e

echo "Setting up AL compiler (latest version)..."
echo "AL compiler setup complete"

echo "Setting up AL compiler (latest version)..."

# Install .NET runtime if not present
if ! command -v dotnet &> /dev/null; then
    wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
    chmod +x dotnet-install.sh
    ./dotnet-install.sh --runtime dotnet --version 8.0.0
fi

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

# Extract version from extension/package.json inside the VSIX
unzip -p al.vsix.zip extension/package.json > package.json
AL_VERSION=$(grep '"version"' package.json | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
EXT_DIR="$HOME/.vscode-server/extensions/ms-dynamics-smb.al-$AL_VERSION"

# Remove any existing extension dir for this version
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"

# Extract VSIX to the correct VS Code extension directory
unzip -q al.vsix.zip -d "$EXT_DIR"

echo "AL compiler installed to $EXT_DIR"
echo "alc path: $EXT_DIR/bin/linux/alc"
echo "Setup complete."
# Make compiler executable
chmod +x "$EXT_DIR/bin/linux/alc"

# Copy analyzers to bin directory if present
ANALYZERS=(
  "Microsoft.Dynamics.Nav.CodeCop.dll"
  "Microsoft.Dynamics.Nav.UICop.dll"
  "Microsoft.Dynamics.Nav.AppSourceCop.dll"
  "Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll"
)
ANALYZER_SRC="$EXT_DIR/extension/bin/"
ANALYZER_DST="$EXT_DIR/bin/"
mkdir -p "$ANALYZER_DST"
for dll in "${ANALYZERS[@]}"; do
  if [ -f "$ANALYZER_SRC/$dll" ]; then
    cp -f "$ANALYZER_SRC/$dll" "$ANALYZER_DST"
    echo "Copied $dll to $ANALYZER_DST"
  else
    echo "$dll not found in VSIX, skipping."
  fi
done

echo "AL compiler and analyzers installed to $EXT_DIR"
echo "alc path: $EXT_DIR/bin/linux/alc"
echo "Analyzers in: $EXT_DIR/bin/"
echo "Setup complete."