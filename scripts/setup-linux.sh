#!/bin/bash
# Sets up systemd user service for MCPHub

set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="mcp-hub"
SERVICE_FILE="$HOME/.config/systemd/user/${SERVICE_NAME}.service"

# Find npx path
NPX_PATH="$(which npx)"
if [ -z "$NPX_PATH" ]; then
    echo "Error: npx not found. Install Node.js first."
    exit 1
fi

# Build PATH for systemd service from current user environment
SERVICE_PATH="/usr/local/bin:/usr/bin:/bin"
# Add mise shims if mise is installed
if command -v mise >/dev/null 2>&1; then
    MISE_SHIMS="$(mise where shims 2>/dev/null || echo "$HOME/.local/share/mise/shims")"
    [ -d "$MISE_SHIMS" ] && SERVICE_PATH="$MISE_SHIMS:$SERVICE_PATH"
fi
# Add user local bin
[ -d "$HOME/.local/bin" ] && SERVICE_PATH="$HOME/.local/bin:$SERVICE_PATH"
# Add directory containing npx (in case it's not in standard paths)
NPX_DIR="$(dirname "$NPX_PATH")"
case ":$SERVICE_PATH:" in
    *":$NPX_DIR:"*) ;;
    *) SERVICE_PATH="$NPX_DIR:$SERVICE_PATH" ;;
esac

# Create systemd user directory
mkdir -p "$HOME/.config/systemd/user"

# Create data directory for logs
mkdir -p "$REPO_DIR/data"

# Create service file
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=MCPHub - MCP Server Manager
After=network.target

[Service]
Type=simple
WorkingDirectory=${REPO_DIR}
ExecStart=${NPX_PATH} @samanhappy/mcphub --port \${MCPHUB_PORT:-9700} --config ./mcp_settings.json
Restart=on-failure
RestartSec=5
EnvironmentFile=-${REPO_DIR}/.env
Environment="PATH=${SERVICE_PATH}"

[Install]
WantedBy=default.target
EOF

echo "Created: $SERVICE_FILE"

# Reload systemd
systemctl --user daemon-reload

# Enable service
systemctl --user enable "$SERVICE_NAME"

echo "Service enabled. Use 'make start' to start MCPHub."
echo "It will auto-start on login."
