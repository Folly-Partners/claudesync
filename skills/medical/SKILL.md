# Medical Records Query Skill

This skill provides cited, thorough answers from Andrew's medical records using semantic search.

**Trigger patterns:** "medical records", "health history", "lab results", "my labs", "NutrEval", "bloodwork", "medical question", "health data"

## Records Location

`/Users/andrewwilkinson/Library/Mobile Documents/com~apple~CloudDocs/Manual Library/Medical records`

## MCP Tools

Use the `medical-rag` MCP server:
- `mcp__medical-rag__query_documents` - Semantic search across indexed records
- `mcp__medical-rag__list_files` - List all indexed files
- `mcp__medical-rag__ingest_file` - Add new files to index
- `mcp__medical-rag__status` - Check index status

## Query Workflow

### 1. Check Index Status
First, check if records are indexed:
```
mcp__medical-rag__status
```

If empty, offer to run ingestion.

### 2. Semantic Search
Query the index with the user's question:
```
mcp__medical-rag__query_documents with query: "user's question"
```

### 3. Read Source Documents
For each relevant result, read the full document to extract precise information:
```
Read the PDF file at the path returned
```

### 4. Build Response with Citations

**REQUIRED FORMAT:**

Every non-trivial claim MUST include:
- **Source document** (filename)
- **Date** (from filename or document content)
- **Specific value or finding**

Example:
> Your vitamin D was 32 ng/mL (AW NutrEval Report - June 2022.pdf, page 3), up from 24 ng/mL (AW - NutrEval report - November 2020.pdf).

### 5. Timeline Building

When appropriate, present findings chronologically:

| Date | Test | Finding | Source |
|------|------|---------|--------|
| Nov 2020 | NutrEval | Vitamin D: 24 ng/mL | AW - NutrEval report - November 2020.pdf |
| Jun 2021 | NutrEval | Vitamin D: 32 ng/mL | AW NutrEval Report - June 2021.pdf |

### 6. Separate Facts vs Interpretations

**Facts (from records):**
- Lab values, diagnoses, medications as documented

**Interpretations (clearly labeled):**
- Trends you observe
- Possible implications
- Recommendations for follow-up

## Output Structure

```markdown
## Summary
[2-3 sentence answer to the question]

## Detailed Findings

### [Category 1]
[Findings with inline citations]

### [Category 2]
[Findings with inline citations]

## Timeline
[Chronological table if applicable]

## Sources Referenced
- [List of documents used]

## Suggested Follow-ups
[Questions that might help clarify or additional records to review]
```

## Red Flags

If you find concerning values (critically high/low labs, urgent findings), flag them prominently but don't alarm - suggest discussing with a healthcare provider.

## Privacy

All processing happens locally. No medical data leaves the computer.

## When to Use Dr. Ralph Instead

For full diagnostic workflows (new symptoms, treatment planning, SOAP reports), use:
```
/dr-ralph:diagnose "symptoms" --patient "Andrew"
```

This skill is for quick queries against existing records, not new diagnostic sessions.
