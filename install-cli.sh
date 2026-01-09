#!/bin/bash
# Helper script to properly install the Carolina Cloud CLI

set -e

CLI_BINARY="ccloud-darwin-arm64"
INSTALL_PATH="/usr/local/bin/ccloud"

echo "Installing Carolina Cloud CLI..."

# Check if binary exists in current directory
if [ ! -f "$CLI_BINARY" ]; then
    echo "Error: $CLI_BINARY not found in current directory"
    exit 1
fi

# Move and rename the binary
echo "Moving $CLI_BINARY to $INSTALL_PATH..."
sudo mv "$CLI_BINARY" "$INSTALL_PATH"

# Ensure it's executable (should already be, but just in case)
sudo chmod +x "$INSTALL_PATH"

echo "✓ Installation complete!"
echo ""
echo "Verifying installation..."
which ccloud
ccloud --version

echo ""
echo "You can now use 'ccloud' from anywhere in your terminal."
echo ""
echo "Next steps:"
echo "1. Get your API key from: https://console.carolinacloud.io/settings/api"
echo "2. Set it: export CCLOUD_API_KEY=your_api_key"
echo "3. Test it: ccloud list"
