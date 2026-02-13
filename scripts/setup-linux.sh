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

# Create systemd user directory
mkdir -p "$HOME/.config/systemd/user"

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
EnvironmentFile=${REPO_DIR}/.env

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
