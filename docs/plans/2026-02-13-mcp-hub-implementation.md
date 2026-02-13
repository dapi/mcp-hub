# MCP-Hub Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a repository for centralized MCP server management with Makefile automation and autostart support for Linux/macOS.

**Architecture:** Makefile as main interface, shell scripts for platform-specific setup, npx mcphub as runtime. Config stored in git, secrets in .env.

**Tech Stack:** Make, Bash, npx/Node.js, systemd (Linux), launchd (macOS)

---

## Task 1: Base Configuration Files

**Files:**
- Create: `.gitignore`
- Create: `.env.example`
- Create: `mcp_settings.json`

**Step 1: Create .gitignore**

```gitignore
# Secrets
.env

# MCPHub data
data/

# Node
node_modules/

# OS
.DS_Store
```

**Step 2: Create .env.example**

```bash
# MCPHub Configuration
MCPHUB_PORT=9700
MCPHUB_HOST=0.0.0.0

# Dashboard credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=changeme

# Disable MCP endpoint auth (trusted network)
ENABLE_BEARER_AUTH=false
```

**Step 3: Create mcp_settings.json**

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    }
  }
}
```

**Step 4: Test config validity**

Run: `cat mcp_settings.json | python3 -m json.tool`
Expected: Valid JSON output

**Step 5: Commit**

```bash
git add .gitignore .env.example mcp_settings.json
git commit -m "feat: add base configuration files"
```

---

## Task 2: Platform Detection Script

**Files:**
- Create: `scripts/detect-platform.sh`

**Step 1: Create scripts directory**

```bash
mkdir -p scripts
```

**Step 2: Create detect-platform.sh**

```bash
#!/bin/bash
# Detects platform and outputs: linux or macos

case "$(uname -s)" in
    Linux*)  echo "linux";;
    Darwin*) echo "macos";;
    *)       echo "unknown"; exit 1;;
esac
```

**Step 3: Make executable**

```bash
chmod +x scripts/detect-platform.sh
```

**Step 4: Test on current platform**

Run: `./scripts/detect-platform.sh`
Expected: `linux` or `macos`

**Step 5: Commit**

```bash
git add scripts/detect-platform.sh
git commit -m "feat: add platform detection script"
```

---

## Task 3: Linux Setup Script (systemd)

**Files:**
- Create: `scripts/setup-linux.sh`

**Step 1: Create setup-linux.sh**

```bash
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
ExecStart=${NPX_PATH} mcphub --port \${MCPHUB_PORT:-9700} --config ./mcp_settings.json
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
```

**Step 2: Make executable**

```bash
chmod +x scripts/setup-linux.sh
```

**Step 3: Commit**

```bash
git add scripts/setup-linux.sh
git commit -m "feat: add Linux systemd setup script"
```

---

## Task 4: macOS Setup Script (launchd)

**Files:**
- Create: `scripts/setup-macos.sh`

**Step 1: Create setup-macos.sh**

```bash
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
        <string>mcphub</string>
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
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

echo "Created: $PLIST_FILE"
echo "Service configured. Use 'make start' to start MCPHub."
echo "It will auto-start on login."
```

**Step 2: Make executable**

```bash
chmod +x scripts/setup-macos.sh
```

**Step 3: Commit**

```bash
git add scripts/setup-macos.sh
git commit -m "feat: add macOS launchd setup script"
```

---

## Task 5: Unsetup Scripts

**Files:**
- Create: `scripts/unsetup-linux.sh`
- Create: `scripts/unsetup-macos.sh`

**Step 1: Create unsetup-linux.sh**

```bash
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
```

**Step 2: Create unsetup-macos.sh**

```bash
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
```

**Step 3: Make executable**

```bash
chmod +x scripts/unsetup-linux.sh scripts/unsetup-macos.sh
```

**Step 4: Commit**

```bash
git add scripts/unsetup-linux.sh scripts/unsetup-macos.sh
git commit -m "feat: add unsetup scripts for Linux and macOS"
```

---

## Task 6: Makefile

**Files:**
- Create: `Makefile`

**Step 1: Create Makefile**

```makefile
.PHONY: install start stop restart status logs setup unsetup open help

SHELL := /bin/bash
REPO_DIR := $(shell pwd)
PLATFORM := $(shell ./scripts/detect-platform.sh 2>/dev/null || echo "unknown")
PID_FILE := $(REPO_DIR)/data/.pid
LOG_FILE := $(REPO_DIR)/data/mcphub.log

# Default target
help:
	@echo "MCP-Hub Management Commands:"
	@echo ""
	@echo "  make install   - Check dependencies, create .env from template"
	@echo "  make start     - Start MCPHub"
	@echo "  make stop      - Stop MCPHub"
	@echo "  make restart   - Restart MCPHub"
	@echo "  make status    - Show MCPHub status"
	@echo "  make logs      - Show MCPHub logs"
	@echo "  make setup     - Configure autostart (systemd/launchd)"
	@echo "  make unsetup   - Remove autostart configuration"
	@echo "  make open      - Open dashboard in browser"
	@echo ""
	@echo "Platform: $(PLATFORM)"

install:
	@echo "Checking dependencies..."
	@command -v node >/dev/null 2>&1 || { echo "Error: Node.js not found. Install it first."; exit 1; }
	@command -v npx >/dev/null 2>&1 || { echo "Error: npx not found. Install Node.js first."; exit 1; }
	@echo "Node.js: $$(node --version)"
	@echo "npx: $$(npx --version)"
	@mkdir -p data
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env from .env.example"; \
		echo "Edit .env to set your credentials."; \
	else \
		echo ".env already exists"; \
	fi
	@echo "Install complete. Run 'make setup' to configure autostart."

start:
ifeq ($(PLATFORM),linux)
	@if systemctl --user is-enabled mcp-hub >/dev/null 2>&1; then \
		systemctl --user start mcp-hub; \
		echo "Started via systemd"; \
	else \
		$(MAKE) _start_manual; \
	fi
else ifeq ($(PLATFORM),macos)
	@if [ -f "$$HOME/Library/LaunchAgents/com.mcp-hub.plist" ]; then \
		launchctl load "$$HOME/Library/LaunchAgents/com.mcp-hub.plist" 2>/dev/null || true; \
		launchctl start com.mcp-hub; \
		echo "Started via launchd"; \
	else \
		$(MAKE) _start_manual; \
	fi
else
	$(MAKE) _start_manual
endif

_start_manual:
	@mkdir -p data
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "MCPHub already running (PID: $$(cat $(PID_FILE)))"; \
	else \
		source .env 2>/dev/null || true; \
		PORT=$${MCPHUB_PORT:-9700}; \
		nohup npx mcphub --port $$PORT --config ./mcp_settings.json > $(LOG_FILE) 2>&1 & \
		echo $$! > $(PID_FILE); \
		echo "Started MCPHub (PID: $$!, Port: $$PORT)"; \
	fi

stop:
ifeq ($(PLATFORM),linux)
	@if systemctl --user is-enabled mcp-hub >/dev/null 2>&1; then \
		systemctl --user stop mcp-hub; \
		echo "Stopped via systemd"; \
	else \
		$(MAKE) _stop_manual; \
	fi
else ifeq ($(PLATFORM),macos)
	@if [ -f "$$HOME/Library/LaunchAgents/com.mcp-hub.plist" ]; then \
		launchctl stop com.mcp-hub 2>/dev/null || true; \
		echo "Stopped via launchd"; \
	else \
		$(MAKE) _stop_manual; \
	fi
else
	$(MAKE) _stop_manual
endif

_stop_manual:
	@if [ -f $(PID_FILE) ]; then \
		PID=$$(cat $(PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID; \
			echo "Stopped MCPHub (PID: $$PID)"; \
		else \
			echo "Process not running"; \
		fi; \
		rm -f $(PID_FILE); \
	else \
		echo "PID file not found"; \
	fi

restart: stop
	@sleep 1
	$(MAKE) start

status:
ifeq ($(PLATFORM),linux)
	@if systemctl --user is-enabled mcp-hub >/dev/null 2>&1; then \
		systemctl --user status mcp-hub --no-pager || true; \
	else \
		$(MAKE) _status_manual; \
	fi
else ifeq ($(PLATFORM),macos)
	@if [ -f "$$HOME/Library/LaunchAgents/com.mcp-hub.plist" ]; then \
		launchctl list | grep mcp-hub || echo "Not running"; \
	else \
		$(MAKE) _status_manual; \
	fi
else
	$(MAKE) _status_manual
endif

_status_manual:
	@source .env 2>/dev/null || true; \
	PORT=$${MCPHUB_PORT:-9700}; \
	if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "Status: RUNNING"; \
		echo "PID: $$(cat $(PID_FILE))"; \
		echo "Port: $$PORT"; \
		echo "Dashboard: http://localhost:$$PORT"; \
	else \
		echo "Status: STOPPED"; \
	fi

logs:
	@if [ -f $(LOG_FILE) ]; then \
		tail -f $(LOG_FILE); \
	else \
		echo "No log file found. Start MCPHub first."; \
	fi

setup:
ifeq ($(PLATFORM),linux)
	@./scripts/setup-linux.sh
else ifeq ($(PLATFORM),macos)
	@./scripts/setup-macos.sh
else
	@echo "Unsupported platform: $(PLATFORM)"
	@exit 1
endif

unsetup:
ifeq ($(PLATFORM),linux)
	@./scripts/unsetup-linux.sh
else ifeq ($(PLATFORM),macos)
	@./scripts/unsetup-macos.sh
else
	@echo "Unsupported platform: $(PLATFORM)"
endif

open:
	@source .env 2>/dev/null || true; \
	PORT=$${MCPHUB_PORT:-9700}; \
	URL="http://localhost:$$PORT"; \
	echo "Opening $$URL"; \
	if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open "$$URL"; \
	elif command -v open >/dev/null 2>&1; then \
		open "$$URL"; \
	else \
		echo "Cannot open browser. Visit: $$URL"; \
	fi
```

**Step 2: Test Makefile syntax**

Run: `make help`
Expected: Shows help message with available commands

**Step 3: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile with all management commands"
```

---

## Task 7: README

**Files:**
- Create: `README.md`

**Step 1: Create README.md**

```markdown
# MCP-Hub

Централизованное управление MCP серверами через [MCPHub](https://github.com/samanhappy/mcphub).

## Quick Start

```bash
git clone git@github.com:dapi/mcp-hub.git
cd mcp-hub
make install
make setup
make start
make open
```

## Commands

| Command | Description |
|---------|-------------|
| `make install` | Check dependencies, create .env |
| `make start` | Start MCPHub |
| `make stop` | Stop MCPHub |
| `make restart` | Restart MCPHub |
| `make status` | Show status |
| `make logs` | Show logs |
| `make setup` | Configure autostart |
| `make unsetup` | Remove autostart |
| `make open` | Open dashboard |

## Configuration

### MCP Servers

Edit `mcp_settings.json` to add/remove MCP servers:

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-filesystem", "/home"]
    }
  }
}
```

### Environment

Copy `.env.example` to `.env` and edit:

```bash
MCPHUB_PORT=9700
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-password
```

## Connect AI Clients

```
http://localhost:9700/mcp           # All servers
http://localhost:9700/mcp/{server}  # Specific server
```

## Platform Support

- **Linux**: systemd --user
- **macOS**: launchd

## License

MIT
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with usage instructions"
```

---

## Task 8: Final Test & Push

**Step 1: Run install**

Run: `make install`
Expected: Creates .env, shows Node.js version

**Step 2: Test start/stop (manual mode)**

Run: `make start && sleep 3 && make status && make stop`
Expected: MCPHub starts, shows running status, stops

**Step 3: Push to GitHub**

```bash
git push origin master
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Base config files | .gitignore, .env.example, mcp_settings.json |
| 2 | Platform detection | scripts/detect-platform.sh |
| 3 | Linux setup | scripts/setup-linux.sh |
| 4 | macOS setup | scripts/setup-macos.sh |
| 5 | Unsetup scripts | scripts/unsetup-*.sh |
| 6 | Makefile | Makefile |
| 7 | README | README.md |
| 8 | Final test | - |

Total: 8 tasks, ~11 files
