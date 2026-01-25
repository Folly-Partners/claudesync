---
name: medical-ingest
description: Index all medical records into the local RAG system for semantic search
---

# Medical Records Ingestion

Index all medical records from iCloud into the mcp-local-rag semantic search system.

## Instructions

### 1. Check Current Status

First, use the medical-rag MCP server to check index status:

```
Use ToolSearch to load: mcp__medical-rag__status
Then call: mcp__medical-rag__status
```

### 2. List Records to Index

Get all PDF files in the medical records folder:

```bash
find "/Users/andrewwilkinson/Library/Mobile Documents/com~apple~CloudDocs/Manual Library/Medical records" -type f -name "*.pdf" 2>/dev/null | sort
```

Also check for other document types:
```bash
find "/Users/andrewwilkinson/Library/Mobile Documents/com~apple~CloudDocs/Manual Library/Medical records" -type f \( -name "*.rtf" -o -name "*.txt" -o -name "*.doc*" \) 2>/dev/null | sort
```

### 3. Ingest Each File

For each PDF file, use the mcp-local-rag ingest tool:

```
Use ToolSearch to load: mcp__medical-rag__ingest_file
Then for each file: mcp__medical-rag__ingest_file with path: "/path/to/file.pdf"
```

**Important:**
- Process files one at a time
- Report progress: "Ingesting file X of Y: filename"
- If a file fails, log the error and continue with the next file
- Skip files larger than 10MB (note them for manual handling)

### 4. Verify Ingestion

After all files are processed:

```
mcp__medical-rag__list_files
```

Report:
- Total files indexed
- Any files that failed
- Any files skipped due to size

### 5. Test the Index

Run a quick test query:

```
mcp__medical-rag__query_documents with query: "vitamin D levels"
```

Confirm results are returning relevant documents.

## Output

Provide a summary:

```markdown
## Medical Records Ingestion Complete

**Indexed:** X files
**Failed:** Y files (list if any)
**Skipped:** Z files >10MB (list if any)

### Test Query Results
Query: "vitamin D levels"
Top results: [list top 3 documents]

The medical records are now searchable. Use `/med` or ask questions about your health history.
```

## Re-Indexing

To force re-index all files (e.g., after adding new records):

1. The mcp-local-rag server handles deduplication automatically
2. Just run this command again - existing files will be skipped or updated
