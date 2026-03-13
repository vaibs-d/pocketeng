#!/bin/bash
# Pocket Eng installer — https://pocketeng.co
# curl -fsSL https://pocketeng.co/install | sh
set -e

REPO="vaibs-d/pocketengineer"
BINARY="pocketeng"
INSTALL_DIR="/usr/local/bin"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Pocket Eng${NC} — installing..."
echo ""

# Check OS
OS=$(uname -s)
if [ "$OS" != "Darwin" ] && [ "$OS" != "Linux" ]; then
    echo -e "${RED}Unsupported OS: $OS${NC}. Pocket Eng supports macOS and Linux."
    exit 1
fi

# Check dependencies
for cmd in ssh rsync; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}Missing: $cmd${NC}. Please install it first."
        exit 1
    fi
done

# Download
URL="https://raw.githubusercontent.com/$REPO/main/$BINARY"
TMP=$(mktemp)
echo -n "  Downloading... "
if command -v curl &>/dev/null; then
    curl -fsSL "$URL" -o "$TMP"
elif command -v wget &>/dev/null; then
    wget -q "$URL" -O "$TMP"
else
    echo -e "${RED}Need curl or wget${NC}"
    exit 1
fi
echo -e "${GREEN}done${NC}"

# Install
echo -n "  Installing to $INSTALL_DIR... "
chmod +x "$TMP"
if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP" "$INSTALL_DIR/$BINARY"
else
    sudo mv "$TMP" "$INSTALL_DIR/$BINARY"
fi
echo -e "${GREEN}done${NC}"

# Verify
echo ""
if command -v $BINARY &>/dev/null; then
    VERSION=$($BINARY version 2>/dev/null || $BINARY --version 2>/dev/null || echo "installed")
    echo -e "  ${GREEN}${BOLD}$VERSION${NC}"
    echo ""
    echo -e "  Get started:  ${BOLD}pocketeng init${NC}"
    echo ""
else
    echo -e "  ${GREEN}Installed!${NC} You may need to restart your shell or add $INSTALL_DIR to PATH."
fi
