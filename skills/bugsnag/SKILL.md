---
name: bugsnag
description: >
  Interact with Bugsnag error monitoring via the SmartBear CLI.
  Use this skill whenever the user mentions Bugsnag, error monitoring, exceptions,
  stacktraces, error tracking, crash reports, or wants to investigate production errors.
  Also trigger when user asks about project errors, error events, or exception chains.
  Even if the user just says "check errors" or "what's breaking in production" — use this skill.
---

# Bugsnag CLI

CLI tool for querying Bugsnag error data. Runs through MCPHub (must be running on localhost:9700).

```
smartbear <subcommand> [flags]
```

All commands support `-o text|json|markdown|raw` (default: text). Use `-o json` when you need to extract IDs for subsequent commands.

## Interactive Workflow

Guide the user step-by-step through error investigation. At each step, present the results and let the user choose what to drill into next.

### Step 1: Identify the project

Start by listing organizations, then projects. Present projects as a numbered list so the user can pick one.

```bash
smartbear smartbear-list-organizations -o json
smartbear smartbear-list-projects --organization-id ORG_ID -o json
```

Cache `organization_id` and `project_id` — they're reused in all subsequent calls.

If there's only one organization, skip the choice and proceed automatically.

### Step 2: Show errors

List errors and present them to the user. Default to open errors, newest first, limit 10.

```bash
smartbear smartbear-list-errors \
  --project-id PROJECT_ID --status open --sort newest --limit 10 -o json
```

Present as a summary table: error class, message, count, first/last seen. Ask the user which error to investigate, or let them search:

```bash
smartbear smartbear-search-issues \
  --project-id PROJECT_ID --query "timeout" -o json
```

### Step 3: Dive into the error

Once the user picks an error, show the latest event and stacktrace together:

```bash
smartbear smartbear-view-latest-event \
  --error-id ERROR_ID -o json

smartbear smartbear-view-stacktrace \
  --project-id PROJECT_ID --event-id EVENT_ID --include-code true -o json
```

Present a clear summary: what happened, where in code, how often.

Then offer next steps:
- **Exception chain** — if the error might wrap a root cause
- **Full tabs** — for complete context (app, device, user, request, breadcrumbs)
- **Other events** — to see if the error manifests differently across occurrences
- **Back to error list** — to look at other errors

### Step 4: Deep-dive (on user's choice)

```bash
# Exception chain — nested/wrapped exceptions
smartbear smartbear-view-exception-chain \
  --project-id PROJECT_ID --event-id EVENT_ID -o json

# Full context — app, device, user, request, breadcrumbs, metadata, stacktrace
smartbear smartbear-view-tabs \
  --project-id PROJECT_ID --event-id EVENT_ID --include-code true -o json

# Other occurrences of the same error
smartbear smartbear-list-error-events \
  --project-id PROJECT_ID --error-id ERROR_ID --limit 5 -o json

# Specific event by ID
smartbear smartbear-view-event \
  --project-id PROJECT_ID --event-id EVENT_ID -o json
```

## Commands Reference

### Discovery

| Command | Flags | Returns |
|-|-|-|
| `smartbear-list-organizations` | none | org list with IDs |
| `smartbear-list-projects` | `--organization-id ID` | projects in org |

### Error Investigation

| Command | Required | Optional |
|-|-|-|
| `smartbear-list-errors` | `--project-id` | `--status open\|fixed\|ignored` `--sort newest\|oldest\|priority` `--limit N` |
| `smartbear-view-error` | `--error-id` | — |
| `smartbear-search-issues` | `--project-id` | `--query TEXT` `--error-class CLASS` `--app-version VER` |

### Event Deep-Dive

| Command | Required | Optional |
|-|-|-|
| `smartbear-list-error-events` | `--project-id` `--error-id` | `--limit N` |
| `smartbear-view-latest-event` | `--error-id` | — |
| `smartbear-view-event` | `--project-id` `--event-id` | — |
| `smartbear-view-stacktrace` | `--project-id` `--event-id` | `--include-code true` |
| `smartbear-view-exception-chain` | `--project-id` `--event-id` | — |
| `smartbear-view-tabs` | `--project-id` `--event-id` | `--include-code true` |

## Tips

- `view-tabs` is the most comprehensive — use when user needs full context
- `--include-code true` shows source code around each stack frame (if available)
- MCPHub must be running: `make status` in `/home/danil/code/mcp-hub`
- When presenting errors to user, summarize key fields (class, message, count) — don't dump raw JSON
