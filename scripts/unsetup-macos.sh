#!/bin/bash
# Removes launchd agent for MCPHub

set -e

PLIST_NAME="com.mcp-hub"
PLIST_FILE="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

if [ -f "$PLIST_FILE" ]; then
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    echo "Agent removed: $PLIST_FILE"
else
    echo "Agent not installed."
fi
