#!/bin/bash
# Sets up launchd agent for MCPHub

set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_NAME="com.mcp-hub"
PLIST_FILE="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

# Find npx path
NPX_PATH="$(which npx)"
if [ -z "$NPX_PATH" ]; then
    echo "Error: npx not found. Install Node.js first."
    exit 1
fi
NPX_DIR="$(dirname "$NPX_PATH")"

# Create LaunchAgents directory if needed
mkdir -p "$HOME/Library/LaunchAgents"

# Create data directory for logs
mkdir -p "$REPO_DIR/data"

# Load .env to get port
if [ -f "$REPO_DIR/.env" ]; then
    source "$REPO_DIR/.env"
fi
PORT="${MCPHUB_PORT:-9700}"

# Create plist file
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>WorkingDirectory</key>
    <string>${REPO_DIR}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${NPX_PATH}</string>
        <string>@samanhappy/mcphub</string>
        <string>--port</string>
        <string>${PORT}</string>
        <string>--config</string>
        <string>./mcp_settings.json</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${REPO_DIR}/data/mcphub.log</string>
    <key>StandardErrorPath</key>
    <string>${REPO_DIR}/data/mcphub.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${NPX_DIR}:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

echo "Created: $PLIST_FILE"
echo "Service configured. Use 'make start' to start MCPHub."
echo "It will auto-start on login."
