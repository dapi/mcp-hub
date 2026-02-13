# MCP-Hub: Дизайн системы управления MCP серверами

**Дата:** 2026-02-13
**Репозиторий:** https://github.com/dapi/mcp-hub

## Цель

Создать репозиторий для централизованного управления MCP серверами через MCPHub с возможностью:
- Хранить конфигурацию серверов в git (версионирование, шаринг с командой)
- Управлять сервисом через Makefile (install, start, stop, setup)
- Автозапуск при перезагрузке компьютера (Linux + macOS)

## Требования

| Параметр | Значение |
|----------|----------|
| Runtime | npx mcphub (нативный Node.js) |
| Конфигурация | В репозитории (mcp_settings.json) |
| Порт | 9700 |
| Автозапуск Linux | systemctl --user |
| Автозапуск macOS | launchd |
| Секреты | .env (в .gitignore) |
| Аутентификация MCP | Отключена (внутренняя сеть) |

## Структура репозитория

```
mcp-hub/
├── Makefile                    # Главный интерфейс управления
├── mcp_settings.json           # Конфигурация MCP серверов
├── .env.example                # Шаблон переменных окружения
├── .env                        # Секреты (в .gitignore)
├── .gitignore
├── README.md
├── data/                       # Персистентные данные MCPHub
└── scripts/
    ├── detect-platform.sh      # Определяет Linux/macOS
    ├── setup-linux.sh          # Создает systemd user service
    └── setup-macos.sh          # Создает launchd plist
```

## Makefile команды

| Команда | Описание |
|---------|----------|
| `make install` | Проверяет Node.js, создает .env из .env.example |
| `make start` | Запускает MCPHub в фоне |
| `make stop` | Останавливает MCPHub |
| `make restart` | stop + start |
| `make status` | Показывает статус (running/stopped, PID, порт) |
| `make logs` | Показывает логи MCPHub |
| `make setup` | Настраивает автозапуск (systemd/launchd) |
| `make unsetup` | Удаляет автозапуск |
| `make open` | Открывает dashboard в браузере |

## Конфигурация

### mcp_settings.json (в git)

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-filesystem", "/home"]
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    }
  }
}
```

### .env.example (в git)

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

### .env (в .gitignore)

Локальные секреты каждого разработчика.

## Автозапуск

### Linux (systemd --user)

Файл: `~/.config/systemd/user/mcp-hub.service`

```ini
[Unit]
Description=MCPHub - MCP Server Manager
After=network.target

[Service]
Type=simple
WorkingDirectory=/path/to/mcp-hub
ExecStart=/usr/bin/npx mcphub --port 9700 --config ./mcp_settings.json
Restart=on-failure
RestartSec=5
EnvironmentFile=/path/to/mcp-hub/.env

[Install]
WantedBy=default.target
```

Управление:
- `systemctl --user enable mcp-hub` - включить автозапуск
- `systemctl --user start mcp-hub` - запустить
- `systemctl --user status mcp-hub` - статус

### macOS (launchd)

Файл: `~/Library/LaunchAgents/com.mcp-hub.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mcp-hub</string>
    <key>WorkingDirectory</key>
    <string>/path/to/mcp-hub</string>
    <key>ProgramArguments</key>
    <array>
        <string>npx</string>
        <string>mcphub</string>
        <string>--port</string>
        <string>9700</string>
        <string>--config</string>
        <string>./mcp_settings.json</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/path/to/mcp-hub/data/mcphub.log</string>
    <key>StandardErrorPath</key>
    <string>/path/to/mcp-hub/data/mcphub.log</string>
</dict>
</plist>
```

Управление:
- `launchctl load ~/Library/LaunchAgents/com.mcp-hub.plist` - включить
- `launchctl unload ...` - выключить

## Workflow для команды

### Первоначальная настройка

```bash
git clone git@github.com:dapi/mcp-hub.git
cd mcp-hub
make install      # Проверит Node.js, создаст .env
make setup        # Настроит автозапуск
make start        # Запустит MCPHub
make open         # Откроет dashboard
```

### Добавление нового MCP сервера

```bash
# Редактируем mcp_settings.json
git add mcp_settings.json
git commit -m "Add playwright MCP server"
git push
make restart
```

### Синхронизация с командой

```bash
git pull
make restart
```

### Подключение AI клиентов

```
http://localhost:9700/mcp             # Все серверы
http://localhost:9700/mcp/{server}    # Конкретный сервер
http://localhost:9700/mcp/{group}     # Группа серверов
```
