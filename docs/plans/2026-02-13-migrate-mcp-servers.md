# План миграции MCP серверов в MCP-Hub

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Перенести MCP серверы (telegram, tavily, playwright, google_workspace) в централизованное управление через MCP-Hub. Удалить отдельные systemd сервисы.

**Не переносим:** ctags (остаётся как stdio в ~/.claude/mcp.json)

---

## Task 1: Обновить mcp_settings.json

**Files:**
- Edit: `mcp_settings.json`

**Step 1: Прочитать текущий mcp_settings.json**

**Step 2: Заменить содержимое на:**

```json
{
  "mcpServers": {
    "telegram": {
      "command": "mcp-telegram",
      "args": [],
      "env": {
        "TELEGRAM_BOT_TOKEN": "${TELEGRAM_BOT_TOKEN}"
      }
    },
    "tavily": {
      "command": "npx",
      "args": ["-y", "@tavily/mcp-server"],
      "env": {
        "TAVILY_API_KEY": "${TAVILY_API_KEY}"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless", "--isolated"]
    },
    "google_workspace": {
      "command": "uvx",
      "args": ["workspace-mcp", "--tools", "drive", "docs", "sheets"],
      "env": {
        "GOOGLE_OAUTH_CLIENT_ID": "${GOOGLE_OAUTH_CLIENT_ID}",
        "GOOGLE_OAUTH_CLIENT_SECRET": "${GOOGLE_OAUTH_CLIENT_SECRET}"
      }
    }
  }
}
```

**Step 3: Проверить JSON валидность**

Run: `cat mcp_settings.json | python3 -m json.tool`

**Step 4: Commit**

```bash
git add mcp_settings.json
git commit -m "feat: add telegram, tavily, playwright, google_workspace MCP servers"
```

---

## Task 2: Обновить .env.example и .env

**Files:**
- Edit: `.env.example`
- Edit: `.env`

**Step 1: Добавить в .env.example новые переменные:**

```bash
# Telegram MCP
TELEGRAM_BOT_TOKEN=your-bot-token

# Tavily MCP
TAVILY_API_KEY=your-api-key

# Google Workspace MCP
GOOGLE_OAUTH_CLIENT_ID=your-client-id
GOOGLE_OAUTH_CLIENT_SECRET=your-client-secret
```

**Step 2: Скопировать реальные значения в .env**

Значения взять из:
- TELEGRAM_BOT_TOKEN: `~/.claude/mcp.json` → mcpServers.telegram.env.TELEGRAM_BOT_TOKEN
- TAVILY_API_KEY: `~/.claude/settings.json` → env.TAVILY_API_KEY
- GOOGLE_OAUTH_CLIENT_ID: `~/.config/systemd/user/workspace-mcp.service` → Environment
- GOOGLE_OAUTH_CLIENT_SECRET: `~/.config/systemd/user/workspace-mcp.service` → Environment

**Step 3: Commit .env.example (НЕ .env!)**

```bash
git add .env.example
git commit -m "feat: add environment variables for MCP servers"
```

---

## Task 3: Остановить и удалить старые systemd сервисы

**Step 1: Остановить сервисы**

```bash
systemctl --user stop playwright-mcp workspace-mcp
```

**Step 2: Отключить автозапуск**

```bash
systemctl --user disable playwright-mcp workspace-mcp
```

**Step 3: Удалить unit файлы**

```bash
rm ~/.config/systemd/user/playwright-mcp.service
rm ~/.config/systemd/user/workspace-mcp.service
```

**Step 4: Перезагрузить systemd**

```bash
systemctl --user daemon-reload
```

**Step 5: Проверить что сервисы удалены**

Run: `systemctl --user list-units --type=service | grep -E "(playwright|workspace)"`
Expected: Пусто

---

## Task 4: Запустить MCP-Hub и проверить

**Step 1: Перезапустить MCP-Hub**

```bash
cd ~/code/mcp-hub
make stop
make start
```

**Step 2: Подождать запуска серверов**

```bash
sleep 10
```

**Step 3: Проверить статус**

```bash
make status
```

**Step 4: Проверить что серверы доступны**

```bash
curl -s http://localhost:9700/api/servers | python3 -m json.tool
```

Expected: Список серверов (telegram, tavily, playwright, google_workspace)

---

## Task 5: Обновить ~/.claude/mcp.json

**Files:**
- Edit: `~/.claude/mcp.json`

**Step 1: Создать backup**

```bash
cp ~/.claude/mcp.json ~/.claude/mcp.json.backup
```

**Step 2: Заменить содержимое на:**

```json
{
  "mcpServers": {
    "ctags": {
      "command": "ctags-mcp",
      "args": []
    },
    "telegram": {
      "type": "http",
      "url": "http://localhost:9700/mcp/telegram"
    },
    "tavily": {
      "type": "http",
      "url": "http://localhost:9700/mcp/tavily"
    },
    "playwright": {
      "type": "http",
      "url": "http://localhost:9700/mcp/playwright"
    },
    "google_workspace": {
      "type": "http",
      "url": "http://localhost:9700/mcp/google_workspace"
    }
  }
}
```

**Step 3: Проверить JSON валидность**

Run: `cat ~/.claude/mcp.json | python3 -m json.tool`

---

## Task 6: Финальная проверка и push

**Step 1: Перезапустить Claude Code сессию**

Пользователь должен перезапустить Claude Code чтобы подхватить новый mcp.json

**Step 2: Push изменений**

```bash
cd ~/code/mcp-hub
git push origin master
```

---

## Summary

| Task | Description |
|------|-------------|
| 1 | Добавить MCP серверы в mcp_settings.json |
| 2 | Добавить env переменные |
| 3 | Удалить старые systemd сервисы |
| 4 | Запустить MCP-Hub |
| 5 | Обновить ~/.claude/mcp.json |
| 6 | Финальная проверка и push |

## Rollback

Если что-то пойдёт не так:

```bash
# Восстановить mcp.json
cp ~/.claude/mcp.json.backup ~/.claude/mcp.json

# Восстановить systemd сервисы (если нужно)
# Unit файлы были в:
# ~/.config/systemd/user/playwright-mcp.service
# ~/.config/systemd/user/workspace-mcp.service
```
