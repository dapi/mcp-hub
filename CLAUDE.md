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

## .claude.json

НИКОГДА не читай и не редактируй `.claude.json` напрямую. Используй `claude` CLI:

```bash
claude mcp add -s user -t http <name> <url>   # Добавить MCP сервер
claude mcp remove -s user <name>              # Удалить MCP сервер
claude mcp list                               # Показать серверы
```

`CLAUDE_CONFIG_DIR` может указывать на нестандартный путь, и реальный `.claude.json` будет не в `~/.claude.json`.

## Важные настройки

### Systemd и mise

Systemd не видит PATH из mise. В сервисе `/home/danil/.config/systemd/user/mcp-hub.service` нужна строка:

```ini
Environment="PATH=/home/danil/.local/share/mise/shims:/home/danil/.local/bin:/usr/local/bin:/usr/bin:/bin"
```

После изменения: `systemctl --user daemon-reload && systemctl --user restart mcp-hub`

## Подключение из Claude Code

Используй `make claude-install` или CLI напрямую:

```bash
claude mcp add -s user -t http <name> "http://localhost:9700/mcp/<name>"
```

НИКОГДА не редактируй `.claude.json` вручную — `CLAUDE_CONFIG_DIR` может указывать на другой путь.

## Добавление нового MCP сервера

1. Добавить в `mcp_settings.json` в секцию `mcpServers`
   - ОБЯЗАТЕЛЬНО указать `"args": []` даже если аргументов нет (иначе MCPHub не создаст транспорт)
2. `make restart`
3. `make claude-install` или `claude mcp add -s user -t http <имя> "http://localhost:9700/mcp/<имя>"`

### URL-пути MCPHub

- `/mcp/<group>` — Streamable HTTP (используется Claude Code с `-t http`)
- `/sse/<group>` — SSE-транспорт (legacy, НЕ использовать)

### Переменная PORT

MCPHub передаёт **все** env-переменные дочерним процессам (`...process.env`).
`PORT=9700` из `.env` наследуется всеми серверами. Для google_workspace это вызывает
конфликт портов (workspace-mcp поднимает OAuth callback на `PORT`).
Решение: переопределить `PORT` в env секции google_workspace через `GOOGLE_OAUTH_PORT`.

### Зомби-процессы

`make stop` убивает orphan-процессы MCPHub. Если при `make restart` порт занят — вероятно,
остался процесс от ручного запуска. `make stop` зачищает и их.
