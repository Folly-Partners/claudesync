# Fix Things MCP Silent: Move to Project Not Working

## Problem
The Things MCP tool silently fails when moving todos to projects. The AppleScript returns "success" but the todo remains in the Inbox.

## Root Cause
The `update-todo.applescript` uses the wrong AppleScript command:
- **Current (broken):** `move targetTodo to project id newListId` → Error 301
- **Correct:** `set project of targetTodo to project id newListId` → Works

Per [official Things AppleScript docs](https://culturedcode.com/things/support/articles/4562654/#move-to-parent), moving a todo to a project requires setting the `project` property, not using the `move` command.

## File to Edit
`/Users/andrewwilkinson/Projects/things-mcp-silent/src/scripts/update-todo.applescript`

## Changes Required

### Lines 90-113: Replace move logic with set property approach

**Before:**
```applescript
-- Handle list assignment (by ID)
if newListId is not "" then
    try
        move targetTodo to project id newListId
    on error
        try
            move targetTodo to area id newListId
        end try
    end try
else if newList is not "" then
    if newList is "inbox" or newList is "Inbox" then
        move targetTodo to list "Inbox"
    else
        try
            set targetProject to first project whose name is newList
            move targetTodo to targetProject
        on error
            try
                set targetArea to first area whose name is newList
                move targetTodo to targetArea
            end try
        end try
    end if
end if
```

**After:**
```applescript
-- Handle list assignment (by ID)
if newListId is not "" then
    try
        set project of targetTodo to project id newListId
    on error
        try
            set area of targetTodo to area id newListId
        end try
    end try
else if newList is not "" then
    if newList is "inbox" or newList is "Inbox" then
        -- To move to Inbox, detach from current project/area
        try
            delete project of targetTodo
        end try
        try
            delete area of targetTodo
        end try
    else
        try
            set project of targetTodo to project newList
        on error
            try
                set area of targetTodo to area newList
            end try
        end try
    end if
end if
```

## Key Changes
1. Replace `move X to project id Y` with `set project of X to project id Y`
2. Replace `move X to area id Y` with `set area of X to area id Y`
3. For Inbox: use `delete project of X` to detach from parent (per docs)
4. For name lookups: use `set project of X to project "Name"` syntax

## Testing
After edit, verify with:
```bash
# Test move by ID
osascript -e 'tell application "Things3"
    set td to first to do of list "Inbox"
    set project of td to project id "LDhUsibk3dp2ZPioQySSiu"
end tell'

# Verify it moved
osascript -e 'tell application "Things3"
    set td to first to do of project id "LDhUsibk3dp2ZPioQySSiu"
    return name of td
end tell'
```
