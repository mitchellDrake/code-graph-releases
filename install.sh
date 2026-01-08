#!/bin/bash
# CodeGraph installer script

set -e

REPO="YOUR_USER/code-graph"  # TODO: Update with actual repo
INSTALL_DIR="${HOME}/.codegraph/bin"
BINARY_NAME="codegraph"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Installing CodeGraph...${NC}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  darwin) OS="macos" ;;
  linux) OS="linux" ;;
  *) echo -e "${RED}❌ Unsupported OS: $OS${NC}"; exit 1 ;;
esac

case "$ARCH" in
  x86_64) ARCH="x64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

echo "  Detected: $OS-$ARCH"

# Get latest release version
echo "  Fetching latest release..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_RELEASE" ]; then
  echo -e "${RED}❌ Could not find latest release${NC}"
  exit 1
fi

echo "  Latest version: $LATEST_RELEASE"

# Download binary
BINARY_URL="https://github.com/${REPO}/releases/download/${LATEST_RELEASE}/codegraph-${LATEST_RELEASE}-${OS}-${ARCH}"
echo "  Downloading binary..."

mkdir -p "$INSTALL_DIR"
curl -fsSL "$BINARY_URL" -o "${INSTALL_DIR}/${BINARY_NAME}"
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

# Add to PATH if not already there
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
  SHELL_RC="$HOME/.bash_profile"
fi

PATH_LINE="export PATH=\"\$HOME/.codegraph/bin:\$PATH\""

if [ -n "$SHELL_RC" ]; then
  if ! grep -q ".codegraph/bin" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# CodeGraph CLI" >> "$SHELL_RC"
    echo "$PATH_LINE" >> "$SHELL_RC"
    echo -e "  ${GREEN}✅ Added to PATH in $SHELL_RC${NC}"
  fi
fi

echo ""
echo -e "${GREEN}✅ CodeGraph installed successfully!${NC}"
echo ""
echo "To use immediately, run:"
echo "  export PATH=\"\$HOME/.codegraph/bin:\$PATH\""
echo ""
echo "Or restart your terminal, then run:"
echo "  codegraph --help"
echo ""
