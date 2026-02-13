#!/bin/bash
# Removes systemd user service for MCPHub

set -e

SERVICE_NAME="mcp-hub"
SERVICE_FILE="$HOME/.config/systemd/user/${SERVICE_NAME}.service"

if [ -f "$SERVICE_FILE" ]; then
    systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl --user daemon-reload
    echo "Service removed: $SERVICE_FILE"
else
    echo "Service not installed."
fi
