---
name: tavily
description: >
  Web search, content extraction, site crawling, and deep research via Tavily API.
  Use this skill when the user needs to search the web, extract content from URLs,
  crawl websites, map site structure, or do deep research on a topic.
  Trigger on: web search, find online, extract page, crawl site, research topic,
  "what's happening with X", site map, scrape URL, or any request for current web information.
  Prefer this over built-in WebSearch/WebFetch when you need advanced features:
  domain filtering, date ranges, image extraction, deep research, or site crawling.
---

# Tavily CLI

CLI for web search, extraction, crawling, and research. Runs through MCPHub (localhost:9700).

```
tavily <subcommand> [flags]
```

All commands support `-o text|json|markdown|raw` (default: text).

## Interactive Workflow

Choose the right tool based on what the user needs:

### Quick web search

For current information, news, facts:

```bash
# Basic search
tavily tavily-tavily-search --query "kubernetes 1.32 new features"

# Recent news only (last week)
tavily tavily-tavily-search --query "anthropic claude" --time-range week

# Search specific sites
tavily tavily-tavily-search --query "react server components" \
  --raw '{"include_domains": ["react.dev", "github.com"]}'

# Advanced search (more thorough, slower)
tavily tavily-tavily-search --query "MCP protocol specification" \
  --search-depth advanced --max-results 10

# Ultra-fast (low latency, high relevance)
tavily tavily-tavily-search --query "bitcoin price" --search-depth ultra-fast
```

Present results with titles, snippets, and source URLs. Ask the user if they want to extract full content from any result.

### Extract content from URLs

When user provides a URL or wants full page content:

```bash
# Single URL
tavily tavily-tavily-extract --urls "https://example.com/article"

# Multiple URLs
tavily tavily-tavily-extract --urls "https://url1.com,https://url2.com"

# Advanced extraction (for LinkedIn, protected sites, tables)
tavily tavily-tavily-extract --urls "https://linkedin.com/in/someone" \
  --extract-depth advanced

# With images
tavily tavily-tavily-extract --urls "https://example.com" --include-images true
```

### Crawl a website

When user needs content from multiple pages on a site:

```bash
# Basic crawl
tavily tavily-tavily-crawl --url "https://docs.example.com" \
  --max-depth 2 --limit 10

# Crawl with instructions
tavily tavily-tavily-crawl --url "https://docs.example.com" \
  --instructions "only return API reference pages" --limit 20

# Crawl specific paths
tavily tavily-tavily-crawl --url "https://example.com" \
  --raw '{"select_paths": ["/docs/.*", "/api/.*"]}'
```

### Map site structure

To see what pages exist without extracting content:

```bash
tavily tavily-tavily-map --url "https://docs.example.com" \
  --max-depth 3 --limit 50
```

### Deep research

For comprehensive multi-source research on complex topics:

```bash
# Quick research
tavily tavily-tavily-research \
  --input "Compare Kubernetes vs Nomad for container orchestration in 2026" --model mini

# Thorough research (broad topic)
tavily tavily-tavily-research \
  --input "State of WebAssembly adoption in production systems" --model pro
```

## Commands Reference

| Command | Purpose | Key Flags |
|-|-|-|
| `tavily-tavily-search` | Web search | `--query TEXT` `--search-depth basic\|advanced\|fast\|ultra-fast` `--time-range day\|week\|month\|year` `--max-results N` |
| `tavily-tavily-extract` | Extract page content | `--urls URL1,URL2` `--extract-depth basic\|advanced` `--format markdown\|text` |
| `tavily-tavily-crawl` | Crawl website pages | `--url URL` `--max-depth N` `--max-breadth N` `--limit N` `--instructions TEXT` |
| `tavily-tavily-map` | Map site URL structure | `--url URL` `--max-depth N` `--limit N` |
| `tavily-tavily-research` | Deep multi-source research | `--input TEXT` `--model mini\|pro\|auto` |

## When to use Tavily vs built-in tools

| Need | Use |
|-|-|
| Quick factual search | Built-in WebSearch (faster) |
| Domain-filtered or date-filtered search | Tavily search |
| Extract full page content | Tavily extract (better than WebFetch for protected sites) |
| Crawl multiple pages | Tavily crawl (no built-in equivalent) |
| Map site structure | Tavily map (no built-in equivalent) |
| Deep multi-source research | Tavily research (no built-in equivalent) |

## Tips

- Use `--raw '{"key": "value"}'` for complex parameters like `include_domains`, `exclude_domains`, `select_paths`
- `--search-depth ultra-fast` is great for quick factual lookups
- `--extract-depth advanced` handles LinkedIn, paywalls, and embedded content better
- `tavily-research --model pro` takes longer but covers more sources — use for broad topics
- MCPHub must be running: `make status` in `/home/danil/code/mcp-hub`
