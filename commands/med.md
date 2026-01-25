---
name: med
description: Query medical records with semantic search and cited answers
argument-hint: "QUERY"
---

# Medical Records Query

Search Andrew's medical records and provide cited, thorough answers.

## Instructions

### 1. Search the Index

Use the medical-rag MCP server to find relevant documents:

```
Use ToolSearch to load: mcp__medical-rag__query_documents
Then call: mcp__medical-rag__query_documents with query: "$ARGUMENTS"
```

### 2. Read Relevant Documents

For each relevant result returned, read the source document to get precise information:

```
Read the PDF file at the path returned by the query
```

Read up to 5 most relevant documents. If PDFs are large, focus on extracting the specific sections that match the query.

### 3. Build Response with Citations

**MANDATORY CITATION FORMAT:**

Every factual claim MUST include:
- Source filename
- Date (from filename or content)
- Specific value/finding

**Example:**
> Vitamin D was 32 ng/mL (AW NutrEval Report - June 2022.pdf) up from 24 ng/mL (AW - NutrEval report - November 2020.pdf).

### 4. Timeline (when applicable)

If the query involves tracking values over time, create a chronological table:

| Date | Test | Value | Source |
|------|------|-------|--------|
| Nov 2020 | NutrEval | 24 ng/mL | AW - NutrEval report - November 2020.pdf |
| Jun 2022 | NutrEval | 32 ng/mL | AW NutrEval Report - June 2022.pdf |

### 5. Separate Facts vs Interpretations

**Facts (from records):** Direct quotes and values from documents

**Interpretations (clearly labeled):** Trends, possible meanings, suggestions for follow-up

### Response Format

```markdown
## Summary
[2-3 sentence direct answer]

## Detailed Findings
[Findings with inline citations]

## Timeline (if applicable)
[Chronological table]

## Sources
- [List of documents referenced]

## Suggested Follow-ups
[Questions or additional records to review]
```

### If Index is Empty

If the query returns no results or the index appears empty:

```
The medical records index appears to be empty. Run `/medical-ingest` to index your records first.
```

### If Query is Diagnostic

If the user is asking about new symptoms or needs a full diagnostic workup, suggest:

```
For a full diagnostic analysis with treatment planning, use:
/dr-ralph:diagnose "your symptoms" --patient "Andrew"
```

## Privacy Note

All searches run locally via mcp-local-rag. No medical data leaves your computer.
