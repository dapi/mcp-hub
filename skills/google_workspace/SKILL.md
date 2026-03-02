---
name: google_workspace
description: >
  Interact with Google Drive, Docs, and Sheets via the google_workspace CLI (alias: gw).
  Use this skill whenever the user mentions Google Drive, Google Docs, Google Sheets,
  spreadsheets, documents, or wants to search/create/edit files in Google Workspace.
  Also trigger on "find a doc", "create a spreadsheet", "share file", "export to PDF",
  "my Google files", or anything about Google Workspace content.
  Even if the user just says "open that doc" or "check the spreadsheet" — use this skill.
---

# Google Workspace CLI

CLI for Google Drive, Docs, and Sheets. Runs through MCPHub (localhost:9700).
Commands available as `google_workspace` or shorthand `gw`.

```
gw <subcommand> [flags]
```

**Default email:** `danilpismenny@gmail.com` — always pass as `--user-google-email`.

## Interactive Workflow

Guide the user step-by-step. Start with search or listing, then drill into specific files.

### Finding files

```bash
# Search across Drive
gw google-workspace-search-drive-files \
  --user-google-email danilpismenny@gmail.com --query "quarterly report"

# List files in root
gw google-workspace-list-drive-items \
  --user-google-email danilpismenny@gmail.com

# List files in folder
gw google-workspace-list-drive-items \
  --user-google-email danilpismenny@gmail.com --folder-id FOLDER_ID

# Search docs specifically
gw google-workspace-search-docs \
  --user-google-email danilpismenny@gmail.com --query "meeting notes"
```

Present results as a list with name, type, last modified. Ask user which file to open.

### Reading content

```bash
# Doc as markdown (best for reading)
gw google-workspace-get-doc-as-markdown \
  --user-google-email danilpismenny@gmail.com --document-id DOC_ID

# Doc as plain text
gw google-workspace-get-doc-content \
  --user-google-email danilpismenny@gmail.com --document-id DOC_ID

# Read spreadsheet values
gw google-workspace-read-sheet-values \
  --user-google-email danilpismenny@gmail.com \
  --spreadsheet-id SHEET_ID --range "Sheet1!A1:D10"

# Spreadsheet info (list of sheets, metadata)
gw google-workspace-get-spreadsheet-info \
  --user-google-email danilpismenny@gmail.com --spreadsheet-id SHEET_ID

# Drive file content (any file)
gw google-workspace-get-drive-file-content \
  --user-google-email danilpismenny@gmail.com --file-id FILE_ID
```

### Creating content

```bash
# Create doc
gw google-workspace-create-doc \
  --user-google-email danilpismenny@gmail.com \
  --title "Title" --content "Body text"

# Create doc in folder
gw google-workspace-create-doc \
  --user-google-email danilpismenny@gmail.com \
  --title "Title" --content "Body" --folder-id FOLDER_ID

# Create spreadsheet
gw google-workspace-create-spreadsheet \
  --user-google-email danilpismenny@gmail.com --title "Title"

# Create folder
gw google-workspace-create-drive-folder \
  --user-google-email danilpismenny@gmail.com \
  --folder-name "Name" --parent-folder-id PARENT_ID

# Create file
gw google-workspace-create-drive-file \
  --user-google-email danilpismenny@gmail.com \
  --file-name "Name" --mime-type "text/plain" --content "content"
```

### Editing content

```bash
# Edit doc text (insert/replace/delete operations)
gw google-workspace-modify-doc-text \
  --user-google-email danilpismenny@gmail.com --document-id DOC_ID \
  --raw '{"operations": [{"action": "insert", "text": "Hello", "index": 1}]}'

# Find and replace in doc
gw google-workspace-find-and-replace-doc \
  --user-google-email danilpismenny@gmail.com \
  --document-id DOC_ID --find "old text" --replace "new text"

# Write spreadsheet values
gw google-workspace-modify-sheet-values \
  --user-google-email danilpismenny@gmail.com \
  --spreadsheet-id SHEET_ID --range "Sheet1!A1" \
  --raw '{"values": [["a","b"],["c","d"]]}'

# Format spreadsheet range
gw google-workspace-format-sheet-range \
  --user-google-email danilpismenny@gmail.com \
  --spreadsheet-id SHEET_ID --range "Sheet1!A1:D1" --raw '{"bold": true}'
```

### Sharing & permissions

```bash
# Share file
gw google-workspace-share-drive-file \
  --user-google-email danilpismenny@gmail.com \
  --file-id FILE_ID --share-with-email someone@example.com --role reader

# Get shareable link
gw google-workspace-get-drive-shareable-link \
  --user-google-email danilpismenny@gmail.com --file-id FILE_ID

# Check permissions
gw google-workspace-get-drive-file-permissions \
  --user-google-email danilpismenny@gmail.com --file-id FILE_ID
```

### Export & other

```bash
# Export doc to PDF
gw google-workspace-export-doc-to-pdf \
  --user-google-email danilpismenny@gmail.com --document-id DOC_ID

# Copy file
gw google-workspace-copy-drive-file \
  --user-google-email danilpismenny@gmail.com \
  --file-id FILE_ID --new-name "Copy Name"

# Comments on doc
gw google-workspace-read-document-comments \
  --user-google-email danilpismenny@gmail.com --document-id DOC_ID

# Add comment
gw google-workspace-create-document-comment \
  --user-google-email danilpismenny@gmail.com \
  --document-id DOC_ID --comment "Comment text"
```

## Commands Reference

| Group | Commands |
|-|-|
| Drive | search-drive-files, list-drive-items, get-drive-file-content, get-drive-file-download-url, create-drive-folder, create-drive-file, copy-drive-file, update-drive-file, import-to-google-doc |
| Sharing | share-drive-file, batch-share-drive-file, get-drive-shareable-link, get-drive-file-permissions, check-drive-file-public-access, set-drive-file-permissions, update-drive-permission, remove-drive-permission, transfer-drive-ownership |
| Docs | search-docs, get-doc-content, get-doc-as-markdown, list-docs-in-folder, create-doc, modify-doc-text, find-and-replace-doc, insert-doc-elements, insert-doc-image, update-doc-headers-footers, batch-update-doc, inspect-doc-structure, create-table-with-data, export-doc-to-pdf, update-paragraph-style |
| Sheets | list-spreadsheets, get-spreadsheet-info, read-sheet-values, modify-sheet-values, format-sheet-range, add-conditional-formatting, update-conditional-formatting, delete-conditional-formatting, create-spreadsheet, create-sheet |
| Comments | read-document-comments, create-document-comment, reply-to-document-comment, resolve-document-comment, read-spreadsheet-comments, create-spreadsheet-comment, reply-to-spreadsheet-comment, resolve-spreadsheet-comment |
| Auth | start-google-auth |

All commands prefixed with `google-workspace-`. If auth fails: `gw google-workspace-start-google-auth --service-name drive`

## Tips

- Use `--raw '{"key": "value"}'` for complex parameters (operations, values, formatting)
- File/folder IDs come from search or list commands — run those first
- `get-doc-as-markdown` is better than `get-doc-content` for readable output
- MCPHub must be running: `make status` in `/home/danil/code/mcp-hub`
- When presenting files, summarize key info — don't dump raw output
