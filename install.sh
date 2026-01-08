#!/bin/bash
# CodeGraph Complete Installer
# Downloads CLI, MCP server, and configures Cursor
# Usage: curl -fsSL https://raw.githubusercontent.com/mitchellDrake/code-graph-releases/main/install.sh | bash

set -e

REPO="mitchellDrake/code-graph-releases"
CLI_DIR="/usr/local/bin"
MCP_DIR="$HOME/.codegraph/bin"
CURSOR_CONFIG="$HOME/.cursor/mcp.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║       CodeGraph Installer             ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  darwin) OS="macos" ;;
  linux) echo -e "${RED}❌ Linux binaries not yet available${NC}"; exit 1 ;;
  *) echo -e "${RED}❌ Unsupported OS: $OS${NC}"; exit 1 ;;
esac

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64) ARCH="x64" ;;
  *) echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

echo -e "  Platform: ${GREEN}${OS}-${ARCH}${NC}"

# Get latest version
echo -e "  Fetching latest version..."
VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
  echo -e "${RED}❌ Could not determine latest version${NC}"
  echo "  Try specifying a version: VERSION=v1.1.0 bash install.sh"
  exit 1
fi

echo -e "  Version: ${GREEN}${VERSION}${NC}"

# Download CLI
echo ""
echo -e "${BLUE}📦 Installing CLI...${NC}"
CLI_URL="https://github.com/${REPO}/releases/download/${VERSION}/codegraph-${VERSION}-${OS}-${ARCH}"
echo "  Downloading from: $CLI_URL"

sudo curl -fsSL "$CLI_URL" -o "${CLI_DIR}/codegraph"
sudo chmod +x "${CLI_DIR}/codegraph"
sudo xattr -d com.apple.quarantine "${CLI_DIR}/codegraph" 2>/dev/null || true

echo -e "  ${GREEN}✓${NC} CLI installed to ${CLI_DIR}/codegraph"

# Download MCP server
echo ""
echo -e "${BLUE}📦 Installing MCP Server...${NC}"
MCP_URL="https://github.com/${REPO}/releases/download/${VERSION}/codegraph-mcp-${VERSION}-${OS}-${ARCH}"
echo "  Downloading from: $MCP_URL"

mkdir -p "$MCP_DIR"
curl -fsSL "$MCP_URL" -o "${MCP_DIR}/codegraph-mcp"
chmod +x "${MCP_DIR}/codegraph-mcp"
xattr -d com.apple.quarantine "${MCP_DIR}/codegraph-mcp" 2>/dev/null || true

echo -e "  ${GREEN}✓${NC} MCP server installed to ${MCP_DIR}/codegraph-mcp"

# Configure Cursor
echo ""
echo -e "${BLUE}⚙️  Configuring Cursor...${NC}"
mkdir -p "$(dirname "$CURSOR_CONFIG")"

MCP_PATH="${MCP_DIR}/codegraph-mcp"

if [ -f "$CURSOR_CONFIG" ]; then
  # Check if codegraph already configured
  if grep -q "codegraph" "$CURSOR_CONFIG" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠${NC} codegraph already in mcp.json, updating..."
    # Use a temp file approach for sed compatibility
    tmp=$(mktemp)
    sed "s|\"command\":.*codegraph-mcp.*\"|\"command\": \"${MCP_PATH}\"|g" "$CURSOR_CONFIG" > "$tmp" && mv "$tmp" "$CURSOR_CONFIG"
  else
    # Add codegraph to existing config
    echo -e "  Adding codegraph to existing config..."
    tmp=$(mktemp)
    # Simple approach: if mcpServers exists, we need to merge
    if grep -q "mcpServers" "$CURSOR_CONFIG"; then
      # Insert before the closing brace of mcpServers
      sed 's/"mcpServers": {/"mcpServers": {\n    "codegraph": { "command": "PLACEHOLDER" },/' "$CURSOR_CONFIG" | sed "s|PLACEHOLDER|${MCP_PATH}|g" > "$tmp" && mv "$tmp" "$CURSOR_CONFIG"
    else
      # Wrap existing config
      echo -e "  ${YELLOW}⚠${NC} Unexpected mcp.json format, creating new config..."
      cat > "$CURSOR_CONFIG" << EOF
{
  "mcpServers": {
    "codegraph": {
      "command": "${MCP_PATH}"
    }
  }
}
EOF
    fi
  fi
else
  # Create new config
  cat > "$CURSOR_CONFIG" << EOF
{
  "mcpServers": {
    "codegraph": {
      "command": "${MCP_PATH}"
    }
  }
}
EOF
fi

echo -e "  ${GREEN}✓${NC} Cursor configured"

# Verify installation
echo ""
echo -e "${BLUE}🔍 Verifying installation...${NC}"
CLI_VERSION=$(codegraph --version 2>/dev/null || echo "failed")
if [ "$CLI_VERSION" != "failed" ]; then
  echo -e "  ${GREEN}✓${NC} CLI version: $CLI_VERSION"
else
  echo -e "  ${RED}✗${NC} CLI verification failed"
fi

# Done
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
echo "Installed:"
echo "  • CLI:    ${CLI_DIR}/codegraph"
echo "  • MCP:    ${MCP_DIR}/codegraph-mcp"
echo "  • Config: ${CURSOR_CONFIG}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart Cursor (Cmd+Q, then reopen)"
echo "  2. Run: codegraph analyze"
echo "  3. Ask Claude: 'What codegraph tools are available?'"
echo ""
