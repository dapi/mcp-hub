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

В `~/.claude.json` каждый MCP сервер через SSE (MCPHub использует SSE-транспорт, НЕ Streamable HTTP):

```json
{
  "playwright": {
    "type": "sse",
    "url": "http://localhost:9700/sse/playwright"
  },
  "tavily": {
    "type": "sse",
    "url": "http://localhost:9700/sse/tavily"
  },
  "google_workspace": {
    "type": "sse",
    "url": "http://localhost:9700/sse/google_workspace"
  }
}
```

## Добавление нового MCP сервера

1. Добавить в `mcp_settings.json` в секцию `mcpServers`
   - ОБЯЗАТЕЛЬНО указать `"args": []` даже если аргументов нет (иначе MCPHub не создаст транспорт и SSE-роуты не зарегистрируются)
2. `make restart`
3. Добавить SSE запись в `~/.claude.json` (type: "sse", url: `http://localhost:9700/sse/<имя_сервера>`)

### Важно: URL-пути MCPHub

- `/sse/<group>` — SSE-транспорт (используется Claude Code)
- `/mcp/<group>` — Streamable HTTP (POST-based, НЕ для Claude Code SSE)
- НЕ путать `/mcp/` и `/sse/`!
