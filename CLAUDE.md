# MCP-Hub

Централизованный хаб для MCP серверов через MCPHub.

## Команды

```bash
make start    # Запустить
make stop     # Остановить
make restart  # Перезапустить
make status   # Статус
make logs     # Логи
```

## Важные настройки

### Systemd и mise

Systemd не видит PATH из mise. В сервисе `/home/danil/.config/systemd/user/mcp-hub.service` нужна строка:

```ini
Environment="PATH=/home/danil/.local/share/mise/shims:/home/danil/.local/bin:/usr/local/bin:/usr/bin:/bin"
```

После изменения: `systemctl --user daemon-reload && systemctl --user restart mcp-hub`

## Подключение из Claude Code

В `~/.claude.json` каждый MCP сервер через HTTP:

```json
{
  "playwright": {
    "type": "http",
    "url": "http://localhost:9700/mcp/playwright"
  },
  "tavily": {
    "type": "http",
    "url": "http://localhost:9700/mcp/tavily"
  },
  "google_workspace": {
    "type": "http",
    "url": "http://localhost:9700/mcp/google_workspace"
  }
}
```

## Добавление нового MCP сервера

1. Добавить в `mcp_settings.json` в секцию `mcpServers`
2. `make restart`
3. Добавить HTTP запись в `~/.claude.json`
