# Plan: One-Time Otter.ai Historical Enrichment

## Overview
Enrich existing 2025 journal entries with historical Otter.ai meeting transcripts. This is a one-time backfill operation - future meetings will use Fireflies.ai (already implemented).

## Data Available
**Otter Export**: 204 .txt files with transcripts (no date metadata in files)
**Mapping Data**: User-provided list of ~90 meetings with explicit dates and titles (Jan-Aug 2025)

## Simplified Approach
Instead of matching to calendar, we have an **explicit date→title mapping** from the user. This makes matching straightforward:

1. Store the mapping as a JSON/CSV file
2. For each Otter file, normalize the title and look up the date
3. Enrich the corresponding journal entry

## Otter Export Format
```
Speaker Name  MM:SS
Transcript text here...

Speaker 2  MM:SS
More transcript text...
```
- Filename contains meeting title with emoji prefix (e.g., "📊 Level 10 Meeting.txt")
- Numbered suffixes for recurring meetings: "(1)", "(2)", etc.

## Mapping Data (User Provided)
~90 meetings from January to August 2025, examples:
- January 31, 2025: LifeSupport company update
- February 10, 2025: Level 10 Meeting
- March 31, 2025: Level 10 Weekly Meeting
- July 25, 2025: Bi-Weekly: Andrew / Chris / Jordan

For recurring meetings (Level 10, Bi-Weekly, etc.), dates are provided for each instance.

## Matching Strategy

### Step 1: Create Mapping File
Store user-provided data as `data/otter_mapping.json`:
```json
{
  "meetings": [
    {"date": "2025-01-31", "title": "LifeSupport company update"},
    {"date": "2025-01-28", "title": "Tiny Board Meeting – 2025 AOP"},
    ...
  ]
}
```

### Step 2: Parse Otter Files
- Extract title from filename (remove emoji prefix, .txt extension)
- Parse transcript content (speakers, text)
- Handle numbered suffixes for recurring meetings

### Step 3: Match Using Fuzzy Title Lookup
For each Otter file:
1. Normalize title (lowercase, remove punctuation, normalize spaces)
2. Find best matching title in mapping data using fuzzy matching
3. For recurring meetings, match by chronological order:
   - "Level 10 Meeting.txt" → first Level 10 date
   - "Level 10 Meeting(1).txt" → second Level 10 date
   - etc.

### Step 4: Enrich Journal Entries
For each matched (transcript, date) pair:
1. Read existing journal entry
2. Generate meeting notes from transcript using Claude
3. Append to Meeting Notes section
4. Update frontmatter with speakers
5. Save

## Implementation

### Step 1: Create Mapping File
**File:** `data/otter_mapping.json`

Parse user's text block into structured JSON with ~90 date-title pairs.

### Step 2: New File - `journal/otter_import.py`

```python
@dataclass
class OtterTranscript:
    filename: str
    title: str  # Cleaned title (no emoji, no .txt, no suffix)
    speakers: list[str]
    transcript: str
    instance_number: int | None  # From (1), (2) suffix

class OtterImporter:
    def __init__(self, export_dir: str, mapping_file: str):
        self.export_dir = Path(export_dir)
        self.mapping = self._load_mapping(mapping_file)

    def _load_mapping(self, path: str) -> dict[str, list[date]]:
        """Load mapping and build title → [dates] index."""
        # Normalize titles and group by base title
        # "Level 10 Meeting" → [date1, date2, date3, ...]
        # "Level 10 Weekly Meeting" → [date1, date2, ...]

    def parse_all(self) -> list[tuple[OtterTranscript, date | None]]:
        """Parse all files and match to dates."""

    def normalize_title(self, filename: str) -> tuple[str, int | None]:
        """Extract clean title and instance number."""
        # "📊  Level 10 Meeting(2).txt" → ("Level 10 Meeting", 2)

    def match_to_date(self, title: str, instance: int | None) -> date | None:
        """Find date using mapping and instance number."""
```

### Step 3: New File - `journal/otter_enrichment.py`

```python
class OtterEnricher:
    def __init__(
        self,
        summarizer: JournalSummarizer,
        storage: JournalStorage,
    ):
        self.summarizer = summarizer
        self.storage = storage

    def generate_meeting_notes(self, transcript: OtterTranscript, meeting_title: str) -> MeetingNotes:
        """Use Claude to extract structured meeting notes."""

    def enrich_entry(self, entry_date: date, meeting_notes: MeetingNotes):
        """Add meeting notes to existing journal entry."""
        # Read entry → append notes → save

    def run(self, transcripts: list[tuple[OtterTranscript, date]]) -> dict:
        """Process all matched transcripts."""
```

### Step 4: CLI Command - `journal enrich-otter`

```python
def cmd_enrich_otter(args):
    """One-time Otter enrichment."""
    # args: --export-dir, --mapping, --dry-run
    importer = OtterImporter(args.export_dir, args.mapping)
    matched = importer.parse_all()

    if args.dry_run:
        # Just print matches
        return

    enricher = OtterEnricher(summarizer, storage)
    results = enricher.run(matched)
    # Report stats
```

## Files to Create/Modify

| File | Change |
|------|--------|
| `data/otter_mapping.json` | **NEW** - Date-title mapping from user data |
| `journal/otter_import.py` | **NEW** - Otter parser + matcher |
| `journal/otter_enrichment.py` | **NEW** - Entry enrichment |
| `journal/cli.py` | Add `enrich-otter` command |
| `journal/summarizer.py` | Add `summarize_otter_transcript()` method |

## Workflow

```
1. Create otter_mapping.json from user's text
      ↓
2. Parse Otter Export (204 files)
      ↓
3. Match Phase (using mapping):
   - Normalize Otter filename → title
   - Look up in mapping → get date(s)
   - For recurring: use instance number to pick correct date
      ↓
4. Enrich Phase (for ~90 matched transcripts):
   - Load existing journal entry
   - Generate MeetingNotes via Claude
   - Append to entry
   - Save
      ↓
5. Report:
   - X transcripts matched and enriched
   - Y Otter files not in mapping (skipped)
```

## Edge Cases

1. **Otter file not in mapping**: Skip with warning (user only provided ~90 of 204)
2. **Multiple Otter files for same date**: Merge all meeting notes
3. **Entry doesn't exist for date**: Create minimal entry with Otter content
4. **Title variations**: Fuzzy match (underscores, slashes, punctuation)

## Testing

1. `--dry-run` to preview matches without modifying
2. Check match rate against expected ~90
3. Spot-check enriched entries

## Notes

- ~90 meetings will be enriched (those in mapping)
- ~114 Otter files will be skipped (not in mapping)
- Claude costs: ~90 summarization calls
- One-time operation
