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
