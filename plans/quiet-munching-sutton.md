# Implementation Plan: Switch Things Today Panel from AppleScript to SQLite

## Overview

Re-architect the Things Today Panel app to use direct SQLite database access instead of AppleScript, eliminating the macOS permission dialog issues that currently prevent the app from loading tasks.

## Problem

The current AppleScript-based implementation requires macOS Automation permissions that never prompt correctly, leaving the app unable to fetch today's tasks from Things 3. Despite multiple attempts (entitlements, TCC resets, bundle ID exceptions), the permission dialog never appears.

## Solution

Access the Things database directly via SQLite. This approach:
- ✅ No permission dialogs required (direct file access to Group Container)
- ✅ Faster queries (native SQLite vs AppleScript overhead)
- ✅ More reliable (no dependency on Things app being responsive)
- ✅ Access to all fields including deadline (AppleScript couldn't expose this)
- ✅ Works when Things is closed (doesn't need to launch the app)

## Database Information

**Location:** `~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/ThingsData-*/Things Database.thingsdatabase/main.sqlite`

**Key Tables:**
- `TMTask` - Main tasks table (41 columns)
- `TMTag` - Tag definitions
- `TMTaskTag` - Junction table linking tasks to tags
- `TMChecklistItem` - Checklist items for tasks
- `TMArea` - Area definitions

**Today's Tasks Query:**
```sql
SELECT * FROM TMTask
WHERE status = 0 AND start = 1 AND trashed = 0
ORDER BY todayIndex
```

**Status Codes:**
- `0` = incomplete
- `2` = canceled
- `3` = completed

**Date Format:** Core Data Reference Date (seconds since 2001-01-01)

## Implementation Steps

### 1. Add SQLite.swift Package Dependency (10 min)

**Via Xcode UI:**
1. Open `Things Today Panel.xcodeproj` in Xcode
2. File → Add Packages...
3. Enter: `https://github.com/stephencelis/SQLite.swift`
4. Select "Up to Next Major" version 0.15.3
5. Add to "Things Today Panel" target

**Verification:** Build project (⌘B) to ensure package resolves

### 2. Implement SQLiteHelper Class (60 min)

**File:** `ThingsDataService.swift` (lines 214-293)

Replace the mock implementation with:

**a) Database Path Discovery**
```swift
static func thingsDatabasePath() -> String? {
    // Search for ThingsData-* directory dynamically
    // Return path to main.sqlite
}
```

**b) Main Query Method**
```swift
static func queryTodayTasks() throws -> [ThingsTask] {
    // Open database connection (readonly)
    // Query TMTask WHERE status=0 AND start=1 AND trashed=0
    // For each task:
    //   - Fetch tags via TMTaskTag join
    //   - Fetch checklist items from TMChecklistItem
    //   - Resolve area title from TMArea
    //   - Resolve project title from TMTask (projects are tasks too)
    //   - Convert timestamp to Date
    //   - Map status code to TaskStatus enum
    // Return [ThingsTask]
}
```

**c) Helper Methods**
- `fetchTags(for taskUuid:, db:)` - Get task's tags via junction table
- `fetchChecklist(for taskUuid:, db:)` - Get checklist items
- `fetchAreaTitle(for uuid:, db:)` - Resolve area name
- `fetchProjectTitle(for uuid:, db:)` - Resolve project name

**d) Error Handling**
- Custom `SQLiteError` enum with helpful messages
- Retry logic for database lock (SQLITE_BUSY)
- Fallback to mock data on failure

### 3. Update ThingsDataService Integration (15 min)

**File:** `ThingsDataService.swift` (line ~32)

**Add new method:**
```swift
private func fetchFromSQLite() {
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let tasks = try SQLiteHelper.queryTodayTasks()
            DispatchQueue.main.async {
                self.tasks = tasks
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            // Handle error, fallback to mock data
        }
    }
}
```

**Update fetchTasks() method:**
```swift
func fetchTasks() {
    isLoading = true
    errorMessage = nil

    switch ThingsConfig.dataSource {
    case .sqlite:
        fetchFromSQLite()
    case .appleScript:
        fetchFromThingsAppleScript()
    // ... other cases
    }
}
```

### 4. Update Configuration (5 min)

**File:** `Config.swift` (lines 18-24)

**Add to DataSource enum:**
```swift
enum DataSource {
    case appleScript
    case sqlite       // NEW: Direct SQLite database access
    case urlScheme
    case mcpServer
}

static let dataSource: DataSource = .sqlite  // Change default
```

### 5. Test Implementation (30 min)

**Test cases:**
- ✓ Database path found correctly
- ✓ Basic task query returns data
- ✓ Tags associated correctly
- ✓ Checklist items fetched
- ✓ Project/area names resolved
- ✓ Deadline dates converted correctly
- ✓ Status codes mapped (incomplete/completed/canceled)
- ✓ Tasks sorted by todayIndex
- ✓ Empty list handled gracefully
- ✓ Database lock handled with retry
- ✓ Missing database shows helpful error
- ✓ UI updates correctly
- ✓ Toggle/open task still works (URL scheme)

## Critical Files to Modify

1. **`/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/ThingsDataService.swift`**
   - Replace SQLiteHelper.queryTodayTasks() implementation (lines 214-293)
   - Add fetchFromSQLite() method (~line 32)
   - Update fetchTasks() to switch on dataSource

2. **`/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/Config.swift`**
   - Add .sqlite to DataSource enum (line 18)
   - Change default to .sqlite (line 24)

3. **`/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel.xcodeproj/project.pbxproj`**
   - Add SQLite.swift package dependency (via Xcode UI)

## Key Technical Details

**Table Definitions (SQLite.swift):**
```swift
// TMTask columns
private static let uuid = Expression<String>("uuid")
private static let title = Expression<String>("title")
private static let notes = Expression<String?>("notes")
private static let status = Expression<Int64>("status")
private static let start = Expression<Int64>("start")
private static let todayIndex = Expression<Int64>("todayIndex")
private static let deadline = Expression<Int64?>("deadline")
private static let projectUuid = Expression<String?>("project")
private static let areaUuid = Expression<String?>("area")
private static let trashed = Expression<Int64>("trashed")
```

**Date Conversion:**
```swift
Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp))
```
Core Data uses 2001-01-01 as reference, not 1970-01-01.

**Database Lock Handling:**
Implement retry logic (3 attempts, 100ms delay) for SQLITE_BUSY errors.

**Join Queries:**
- Tags: `TMTag JOIN TMTaskTag ON tagUuid = tags WHERE tasks = taskUuid`
- Projects are stored in TMTask with type=1

## Benefits

- **No Permissions Required**: Direct file access to Group Container
- **Better Performance**: Native SQLite vs AppleScript overhead
- **More Reliable**: Independent of Things app state
- **Complete Data**: Access to deadline field (missing in AppleScript)
- **Better Errors**: Specific SQLite errors vs generic AppleScript failures

## Backward Compatibility

- Keep existing AppleScript code as fallback option
- Config-driven data source selection
- Mock data fallback on any error
- Graceful error messages in UI

## Estimated Time

**Total: ~2 hours**
- Add package: 10 min
- Implement SQLiteHelper: 60 min
- Integrate into service: 15 min
- Update config: 5 min
- Testing: 30 min
- Polish: 10 min
