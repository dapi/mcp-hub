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
