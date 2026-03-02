---
name: krisp
description: >
  Access Krisp meeting data — meetings, transcripts, action items, activities, and upcoming calendar.
  Use this skill whenever the user mentions Krisp, meetings, meeting notes, transcripts,
  action items, follow-ups, upcoming calls, or wants to find what was discussed in a meeting.
  Also trigger on "what meetings do I have", "what did we discuss", "my action items",
  "meeting summary", or anything about meeting history and agendas.
---

# Krisp CLI

CLI for querying Krisp meeting intelligence. Runs through MCPHub (localhost:9700).

```
krisp <subcommand> [flags]
```

All commands support `-o text|json|markdown|raw` (default: text).

## Interactive Workflow

Guide the user through meeting data exploration. At each step, present results and let the user choose what to drill into.

### Quick actions (no IDs needed)

These commands work immediately — use them as entry points:

```bash
# What meetings do I have this week?
krisp krisp-list-upcoming-meetings

# What meetings in next 3 days?
krisp krisp-list-upcoming-meetings --days 3

# My pending action items
krisp krisp-list-action-items --assigned-to-me true --completed false

# Recent activities / notifications
krisp krisp-list-activities

# Current date/time (with timezone)
krisp krisp-date-time
```

### Search and drill-down

When user asks about a specific meeting or topic:

**Step 1: Search meetings** by text, date range, or participant domains.

```bash
# By text
krisp krisp-search-meetings --search "quarterly planning" -o json

# By date range
krisp krisp-search-meetings --after "2026-02-01" --before "2026-02-28" -o json

# With specific fields
krisp krisp-search-meetings --search "standup" \
  --fields name,date,action_items,key_points -o json
```

Present results as a summary: meeting name, date, attendees. Ask user which meeting to explore.

**Step 2: Get full meeting content** — transcript, notes, action items.

```bash
krisp krisp-get-multiple-documents --ids MEETING_ID -o json
```

This returns the unabridged transcript plus all notes. Summarize key points for the user, then offer to show full transcript, specific action items, or related meetings.

## Commands Reference

| Command | Purpose | Key Flags |
|-|-|-|
| `krisp-list-upcoming-meetings` | Calendar lookahead | `--days N` (1-14, default 7) |
| `krisp-search-meetings` | Find meetings by text/date/domain | `--search TEXT` `--after DATE` `--before DATE` `--fields FIELDS` `--limit N` |
| `krisp-get-multiple-documents` | Full meeting content with transcript | `--ids ID1,ID2` (max 10) |
| `krisp-list-action-items` | Tasks from meetings | `--completed true\|false` `--assigned-to-me true\|false` `--limit N` |
| `krisp-list-activities` | Activity feed / notifications | `--limit N` |
| `krisp-get-user-preferences` | User name, timezone, company | none |
| `krisp-date-time` | Current date/time or date range | `--start-date DATE` `--end-date DATE` |

## Tips

- `search-meetings` returns summaries only — use `get-multiple-documents` for full transcript
- `--fields` in search accepts: name, date, url, attendees, speakers, meeting_notes, key_points, action_items, detailed_summary
- Document IDs are 32-char hex strings (UUID without dashes)
- MCPHub must be running: `make status` in `/home/danil/code/mcp-hub`
- When presenting meeting data, summarize key points and action items — don't dump raw JSON
