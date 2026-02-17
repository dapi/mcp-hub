.PHONY: all install install-deps install-docmost-mcp install-telegram telegram-sign-in start stop restart status logs setup unsetup open help claude-install claude-uninstall enable disable servers

SHELL := /bin/bash
REPO_DIR := $(shell pwd)
PLATFORM := $(shell ./scripts/detect-platform.sh 2>/dev/null || echo "unknown")
PID_FILE := $(REPO_DIR)/data/.pid
LOG_FILE := $(REPO_DIR)/data/mcphub.log

all: install setup claude-install

# Default target
help:
	@echo "MCP-Hub Management Commands:"
	@echo ""
	@echo "  make install          - Check dependencies, create .env from template"
	@echo "  make install-deps     - Install CLI tools (himalaya, tgcli, gh)"
	@echo "  make install-docmost-mcp - Build docmost-mcp from GitHub"
	@echo "  make install-telegram - Install mcp-telegram (requires uv)"
	@echo "  make telegram-sign-in - Authenticate with Telegram"
	@echo "  make start            - Start MCPHub"
	@echo "  make stop             - Stop MCPHub"
	@echo "  make restart          - Restart MCPHub"
	@echo "  make status           - Show MCPHub status"
	@echo "  make logs             - Show MCPHub logs"
	@echo "  make setup            - Configure autostart (systemd/launchd)"
	@echo "  make unsetup          - Remove autostart configuration"
	@echo "  make open             - Open dashboard in browser"
	@echo "  make claude-install   - Install MCP servers in Claude CLI (user scope)"
	@echo "  make claude-uninstall - Remove MCP servers from Claude CLI (user scope)"
	@echo "  make servers          - List all MCP servers with status"
	@echo "  make enable  name=X   - Enable server X (MCPHub + Claude CLI)"
	@echo "  make disable name=X   - Disable server X (MCPHub + Claude CLI)"
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

install-deps:
	@echo "Installing CLI dependencies..."
	@command -v himalaya >/dev/null 2>&1 && echo "himalaya: already installed" || $(MAKE) _install_himalaya
	@command -v tgcli >/dev/null 2>&1 && echo "tgcli: already installed" || $(MAKE) _install_tgcli
	@command -v gh >/dev/null 2>&1 && echo "gh: already installed" || $(MAKE) _install_gh
	@echo "Done."

_install_himalaya:
ifeq ($(PLATFORM),macos)
	brew install himalaya
else ifeq ($(PLATFORM),linux)
	cargo install himalaya
else
	@echo "Error: unsupported platform $(PLATFORM) for himalaya"; exit 1
endif

_install_tgcli:
	@command -v pip3 >/dev/null 2>&1 || { echo "Error: pip3 not found"; exit 1; }
	pip3 install --user tgcli

_install_gh:
ifeq ($(PLATFORM),macos)
	brew install gh
else ifeq ($(PLATFORM),linux)
	@command -v apt >/dev/null 2>&1 && { sudo apt install -y gh; } || \
	command -v dnf >/dev/null 2>&1 && { sudo dnf install -y gh; } || \
	{ echo "Error: install gh manually — https://cli.github.com/"; exit 1; }
else
	@echo "Error: unsupported platform $(PLATFORM) for gh"; exit 1
endif

install-docmost-mcp:
	@echo "Installing docmost-mcp from GitHub..."
	@if [ -d vendor/docmost-mcp ]; then \
		echo "Updating existing clone..."; \
		cd vendor/docmost-mcp && git pull; \
	else \
		mkdir -p vendor; \
		git clone https://github.com/dapi/docmost-mcp.git vendor/docmost-mcp; \
	fi
	@cd vendor/docmost-mcp && npm install && npm run build
	@echo "docmost-mcp installed at vendor/docmost-mcp/build/index.js"

install-telegram:
	@command -v uv >/dev/null 2>&1 || { echo "Error: uv not found. Install it first: https://docs.astral.sh/uv/"; exit 1; }
	@echo "Installing mcp-telegram..."
	@uv tool install git+https://github.com/sparfenyuk/mcp-telegram
	@echo ""
	@echo "mcp-telegram installed. Next steps:"
	@echo "  1. Get API credentials at https://my.telegram.org/auth"
	@echo "  2. Set TELEGRAM_API_ID and TELEGRAM_API_HASH in .env"
	@echo "  3. make telegram-sign-in"
	@echo "  4. make restart"

telegram-sign-in:
	@command -v mcp-telegram >/dev/null 2>&1 || { echo "Error: mcp-telegram not installed. Run 'make install-telegram' first."; exit 1; }
	@source .env 2>/dev/null || true; \
	if [ -z "$$TELEGRAM_API_ID" ] || [ -z "$$TELEGRAM_API_HASH" ]; then \
		echo "Error: TELEGRAM_API_ID and TELEGRAM_API_HASH must be set in .env"; \
		exit 1; \
	fi; \
	PHONE="$$TELEGRAM_PHONE"; \
	if [ -z "$$PHONE" ]; then \
		read -p "Enter phone number (with country code, e.g. +79001234567): " PHONE; \
		if [ -z "$$PHONE" ]; then \
			echo "Error: Phone number is required."; \
			exit 1; \
		fi; \
	else \
		echo "Using phone from .env: $$PHONE"; \
	fi; \
	cd /tmp && mcp-telegram sign-in --api-id "$$TELEGRAM_API_ID" --api-hash "$$TELEGRAM_API_HASH" --phone-number "$$PHONE"

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
	@( \
		flock -n 200 || { echo "Another start operation in progress"; exit 1; }; \
		if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
			echo "MCPHub already running (PID: $$(cat $(PID_FILE)))"; \
		else \
			rm -f $(PID_FILE); \
			source .env 2>/dev/null || true; \
			PORT=$${MCPHUB_PORT:-9700}; \
			nohup npx -y @samanhappy/mcphub --port $$PORT --config ./mcp_settings.json > $(LOG_FILE) 2>&1 & \
			echo $$! > $(PID_FILE); \
			echo "Started MCPHub (PID: $$!, Port: $$PORT)"; \
		fi \
	) 200>$(REPO_DIR)/data/.lock

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
	@$(MAKE) _kill_orphans

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

_kill_orphans:
	@MAIN_PID=$$(systemctl --user show mcp-hub --property=MainPID 2>/dev/null | cut -d= -f2); \
	CGROUP=$$(systemctl --user show mcp-hub --property=ControlGroup 2>/dev/null | cut -d= -f2); \
	pgrep -f "mcphub.*--config" 2>/dev/null | while read PID; do \
		if [ -n "$$CGROUP" ] && [ -f "/proc/$$PID/cgroup" ] && grep -q "$$CGROUP" "/proc/$$PID/cgroup" 2>/dev/null; then \
			continue; \
		fi; \
		TREE=$$(pgrep -P $$PID 2>/dev/null || true); \
		kill $$PID $$TREE 2>/dev/null && echo "Killed orphan MCPHub process: $$PID"; \
	done; true

claude-update: claude-uninstall claude-install

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

servers:
	@command -v jq >/dev/null 2>&1 || { echo "Error: jq not found"; exit 1; }
	@jq -r '.mcpServers | to_entries[] | if .value.enabled == false then "  \(.key)\t[disabled]" else "  \(.key)\t[enabled]" end' mcp_settings.json

enable:
	@test -n "$(name)" || { echo "Usage: make enable name=<server>"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "Error: jq not found"; exit 1; }
	@jq -e '.mcpServers["$(name)"]' mcp_settings.json >/dev/null 2>&1 || { echo "Error: server '$(name)' not found"; exit 1; }
	@source .env 2>/dev/null || true; \
	PORT=$${MCPHUB_PORT:-9700}; \
	echo "Enabling $(name) in MCPHub..."; \
	curl -sf -X POST "http://localhost:$$PORT/api/servers/$(name)/toggle" \
		-H 'Content-Type: application/json' -d '{"enabled": true}' >/dev/null \
		&& echo "  MCPHub: enabled" \
		|| echo "  MCPHub: failed (is it running?)"; \
	if command -v claude >/dev/null 2>&1; then \
		echo "Adding $(name) to Claude CLI..."; \
		claude mcp add -s user -t http "$(name)" "http://localhost:$$PORT/mcp/$(name)" \
			&& echo "  Claude CLI: added" \
			|| echo "  Claude CLI: failed"; \
	fi

disable:
	@test -n "$(name)" || { echo "Usage: make disable name=<server>"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "Error: jq not found"; exit 1; }
	@jq -e '.mcpServers["$(name)"]' mcp_settings.json >/dev/null 2>&1 || { echo "Error: server '$(name)' not found"; exit 1; }
	@source .env 2>/dev/null || true; \
	PORT=$${MCPHUB_PORT:-9700}; \
	echo "Disabling $(name) in MCPHub..."; \
	curl -sf -X POST "http://localhost:$$PORT/api/servers/$(name)/toggle" \
		-H 'Content-Type: application/json' -d '{"enabled": false}' >/dev/null \
		&& echo "  MCPHub: disabled" \
		|| echo "  MCPHub: failed (is it running?)"; \
	if command -v claude >/dev/null 2>&1; then \
		echo "Removing $(name) from Claude CLI..."; \
		claude mcp remove -s user "$(name)" \
			&& echo "  Claude CLI: removed" \
			|| echo "  Claude CLI: failed"; \
	fi

claude-install:
	@command -v claude >/dev/null 2>&1 || { echo "Error: claude CLI not found"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "Error: jq not found"; exit 1; }
	@source .env 2>/dev/null || true; \
	PORT=$${MCPHUB_PORT:-9700}; \
	for name in $$(jq -r '.mcpServers | to_entries[] | select(.value.enabled != false) | .key' mcp_settings.json); do \
		echo "Installing $$name..."; \
		claude mcp add -s user -t http "$$name" "http://localhost:$$PORT/mcp/$$name" || true; \
	done
	@echo "All enabled MCP servers installed in user scope."

claude-uninstall:
	@command -v claude >/dev/null 2>&1 || { echo "Error: claude CLI not found"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "Error: jq not found"; exit 1; }
	@for name in $$(jq -r '.mcpServers | keys[]' mcp_settings.json); do \
		echo "Removing $$name..."; \
		claude mcp remove -s user "$$name"; \
	done
	@echo "All MCP servers removed from user scope."
