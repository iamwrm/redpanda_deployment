#!/bin/bash
set -euo pipefail

# Download and extract Redpanda packages
# Usage: ./download-redpanda.sh [install_dir]

INSTALL_DIR="${1:-$HOME/redpanda}"
VERSION="${REDPANDA_VERSION:-25.3.1-1}"
BASE_URL="https://dl.redpanda.com/public/redpanda/deb/ubuntu/pool/any-version/main/r/re"

echo "=== Downloading Redpanda packages (version: $VERSION) ==="

# Create temp directory for downloads
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$TEMP_DIR"

# Download all required packages
echo "Downloading redpanda_${VERSION}_amd64.deb..."
curl -LO "${BASE_URL}/redpanda_${VERSION}/redpanda_${VERSION}_amd64.deb"

echo "Downloading redpanda-rpk_${VERSION}_amd64.deb..."
curl -LO "${BASE_URL}/redpanda-rpk_${VERSION}/redpanda-rpk_${VERSION}_amd64.deb"

echo "Downloading redpanda-tuner_${VERSION}_amd64.deb..."
curl -LO "${BASE_URL}/redpanda-tuner_${VERSION}/redpanda-tuner_${VERSION}_amd64.deb"

# Extract all packages to the install directory
echo "=== Extracting packages to $INSTALL_DIR ==="
mkdir -p "$INSTALL_DIR"
dpkg-deb -x "redpanda_${VERSION}_amd64.deb" "$INSTALL_DIR"
dpkg-deb -x "redpanda-rpk_${VERSION}_amd64.deb" "$INSTALL_DIR"
dpkg-deb -x "redpanda-tuner_${VERSION}_amd64.deb" "$INSTALL_DIR"

echo "=== Redpanda installed to $INSTALL_DIR ==="
echo ""
echo "Add to PATH for rpk: export PATH=\"$INSTALL_DIR/opt/redpanda/libexec:\$PATH\""
