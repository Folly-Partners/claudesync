# Things Today Panel - UX Enhancements Plan

## Overview

Add keyboard navigation and quality-of-life improvements to the Things Today Panel while maintaining its minimal, focused design philosophy.

**User Preferences:**
- **Workflow:** Mixed viewing + light editing
- **Top Priority:** Keyboard navigation (arrow keys, vim-style)
- **Philosophy:** Stay minimal and fast
- **Desired QoL Features:** Customizable hotkey, undo/redo, completion celebration, productivity stats

---

## Immediate Fixes

### 1. Fix Menu Bar Item (5 min)

**Problem:** Menu bar shows wrong keyboard command (⌘T instead of ⌘⇧Y) and doesn't toggle between "Show Panel" / "Hide Panel"

**Solution:**
```swift
// ThingsTodayPanelApp.swift - setupMenuBar()
menu.addItem(NSMenuItem(title: panelTitle(), action: #selector(togglePanel), keyEquivalent: "y"))
  .keyEquivalentModifierMask = [.command, .shift]

func panelTitle() -> String {
    if floatingPanel?.isVisible == true {
        return "Hide Panel"
    } else {
        return "Show Panel"
    }
}

// Update menu item title in togglePanel() before showing/hiding
statusItem?.menu?.item(at: 0)?.title = panelTitle()
```

**Files:**
- `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/ThingsTodayPanelApp.swift`

---

## Phase 1: Keyboard Navigation (HIGH PRIORITY)

### 1.1 Arrow Key Navigation (30 min)

**Goal:** Navigate tasks with ↑/↓ arrows, maintain focus, wrap at boundaries

**Implementation:**

1. **Add NavigationController** to manage focus state
```swift
// New file: NavigationController.swift
class NavigationController: ObservableObject {
    @Published var selectedTaskId: String?
    @Published var allTaskIds: [String] = []

    func selectNext() {
        guard let current = selectedTaskId,
              let index = allTaskIds.firstIndex(of: current),
              index < allTaskIds.count - 1 else {
            selectedTaskId = allTaskIds.first
            return
        }
        selectedTaskId = allTaskIds[index + 1]
    }

    func selectPrevious() {
        guard let current = selectedTaskId,
              let index = allTaskIds.firstIndex(of: current),
              index > 0 else {
            selectedTaskId = allTaskIds.last
            return
        }
        selectedTaskId = allTaskIds[index - 1]
    }
}
```

2. **Integrate with ContentView**
```swift
// ContentView.swift
@StateObject private var navigation = NavigationController()

.onKeyPress(.downArrow) { _ in
    navigation.selectNext()
    return .handled
}
.onKeyPress(.upArrow) { _ in
    navigation.selectPrevious()
    return .handled
}

// Update navigation.allTaskIds when tasks change
.onChange(of: incompleteTasks) { tasks in
    navigation.allTaskIds = tasks.map { $0.id }
}
```

3. **Update TaskRowView to use navigation state**
```swift
// TaskRowView.swift - pass navigation controller
var isSelectedByNav: Bool {
    navigationController.selectedTaskId == task.id
}

// Update background to show navigation selection
.background(isSelectedByNav ? Color.thingsBlue.opacity(0.15) : ...)
```

**User Experience:**
- Press ↓ to move down the task list
- Press ↑ to move up
- Wraps to top when reaching bottom, and vice versa
- Visual feedback with blue highlight
- Works even when panel doesn't have focus

### 1.2 Vim-Style Navigation (10 min)

**Goal:** Support j/k for down/up (vim keybindings)

**Implementation:**
```swift
// ContentView.swift - add alongside arrow keys
.onKeyPress(.init("j")) { _ in
    navigation.selectNext()
    return .handled
}
.onKeyPress(.init("k")) { _ in
    navigation.selectPrevious()
    return .handled
}
```

**User Experience:**
- `j` moves down (same as ↓)
- `k` moves up (same as ↑)
- Familiar for vim users
- Works everywhere in the panel

### 1.3 Quick Actions on Selected Task (15 min)

**Goal:** Perform actions on keyboard-selected task

**Keyboard Shortcuts:**
- **Space** - Toggle completion
- **Enter/Return** - Open in Things
- **Delete/Backspace** - Delete task
- **E** - Start editing task title

**Implementation:**
```swift
// ContentView.swift - add key handlers
.onKeyPress(.space) { _ in
    if let id = navigation.selectedTaskId,
       let task = tasks.first(where: { $0.id == id }) {
        dataService.toggleTask(task)
        return .handled
    }
    return .ignored
}

.onKeyPress(.return) { _ in
    if let id = navigation.selectedTaskId,
       let task = tasks.first(where: { $0.id == id }) {
        dataService.openTaskInThings(task)
        return .handled
    }
    return .ignored
}

// Similar for delete and edit
```

**User Experience:**
- Navigate with j/k or arrows
- Press Space to complete without clicking
- Press Enter to open full task in Things
- Press Delete to remove
- Press E to rename inline
- Keyboard-only workflow

**Files:**
- New: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/NavigationController.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/ContentView.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/TaskRowView.swift`

---

## Phase 2: Customizable Hotkey (MEDIUM PRIORITY)

### 2.1 Hotkey Preferences UI (30 min)

**Goal:** Let users customize the global hotkey via Settings

**Implementation:**

1. **Add HotkeyRecorder view**
```swift
// New file: HotkeyRecorderView.swift
struct HotkeyRecorderView: View {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    @State private var isRecording = false

    var body: some View {
        Button(isRecording ? "Press keys..." : displayString) {
            isRecording = true
            // Start recording next key press
        }
        .onKeyPress { event in
            if isRecording {
                keyCode = event.keyCode
                modifiers = event.modifierFlags
                isRecording = false
                return .handled
            }
            return .ignored
        }
    }

    var displayString: String {
        // Convert keyCode + modifiers to readable string
        // e.g., "⌘⇧Y", "⌘⌥T", etc.
    }
}
```

2. **Update SettingsView**
```swift
// SettingsView.swift - add hotkey section
Section(header: Text("Global Hotkey")) {
    HotkeyRecorderView(
        keyCode: $hotkeyKeyCode,
        modifiers: $hotkeyModifiers
    )

    Text("Click to record new hotkey")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

3. **Store preferences in UserDefaults**
```swift
// UserDefaultsKeys.swift
extension UserDefaults.Keys {
    static let hotkeyKeyCode = "hotkeyKeyCode"
    static let hotkeyModifiers = "hotkeyModifiers"
}

extension UserDefaults {
    var hotkeyKeyCode: UInt32 {
        get { UInt32(integer(forKey: Keys.hotkeyKeyCode)) }
        set { set(Int(newValue), forKey: Keys.hotkeyKeyCode) }
    }

    var hotkeyModifiers: UInt32 {
        get { UInt32(integer(forKey: Keys.hotkeyModifiers)) }
        set { set(Int(newValue), forKey: Keys.hotkeyModifiers) }
    }
}
```

4. **Update hotkey registration to use preferences**
```swift
// ThingsTodayPanelApp.swift - setupGlobalHotkey()
let modifiers = UserDefaults.standard.hotkeyModifiers
let keyCode = UserDefaults.standard.hotkeyKeyCode

// Re-register when settings change
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("HotkeyChanged"),
    object: nil,
    queue: .main
) { _ in
    unregisterHotkey()
    setupGlobalHotkey()
}
```

**User Experience:**
- Settings panel has "Global Hotkey" section
- Click to start recording
- Press desired key combination
- Shows readable format (⌘⇧Y)
- Updates immediately
- Tooltip in menu bar updates too

**Files:**
- New: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/HotkeyRecorderView.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/SettingsView.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/ThingsTodayPanelApp.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/UserDefaultsKeys.swift`

---

## Phase 3: Undo/Redo Support (MEDIUM PRIORITY)

### 3.1 Undo Manager Integration (40 min)

**Goal:** Support ⌘Z to undo accidental completions/deletions

**Implementation:**

1. **Create UndoManager**
```swift
// ThingsDataService.swift
let undoManager = UndoManager()

func toggleTask(_ task: ThingsTask) {
    // Register undo
    undoManager.registerUndo(withTarget: self) { service in
        service.toggleTask(task) // Toggle back
    }
    undoManager.setActionName("Toggle Task")

    // Perform action
    performToggle(task)
}

func deleteTask(_ task: ThingsTask) {
    // Store task data for undo
    let taskCopy = task

    undoManager.registerUndo(withTarget: self) { service in
        service.restoreTask(taskCopy)
    }
    undoManager.setActionName("Delete Task")

    // Perform deletion
    performDelete(task)
}

func restoreTask(_ task: ThingsTask) {
    // Re-create task via URL scheme
    let urlString = "things:///add?title=\(encoded)&..."
    // ...

    // Register redo
    undoManager.registerUndo(withTarget: self) { service in
        service.deleteTask(task)
    }
}
```

2. **Connect to window's undo manager**
```swift
// FloatingPanelWindow.swift
override var undoManager: UndoManager? {
    return dataService.undoManager
}
```

3. **Add menu items**
```swift
// ThingsTodayPanelApp.swift - setupMenuBar()
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(NSMenuItem(title: "Undo", action: #selector(NSResponder.undo(_:)), keyEquivalent: "z"))
editMenu.addItem(NSMenuItem(title: "Redo", action: #selector(NSResponder.redo(_:)), keyEquivalent: "Z"))
  .keyEquivalentModifierMask = [.command, .shift]
```

**User Experience:**
- Complete a task accidentally → Press ⌘Z to undo
- Delete a task → Press ⌘Z to restore
- Press ⌘⇧Z to redo
- Menu shows "Undo Toggle Task" or "Undo Delete Task"
- Stack up to 10 undo levels
- Clear stack when panel is hidden

**Limitations:**
- Can't undo task creation (Things URL scheme doesn't return ID)
- Can only restore deleted tasks if they're cached
- Undo stack clears on app restart

**Files:**
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/ThingsDataService.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/FloatingPanelWindow.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/ThingsTodayPanelApp.swift`

---

## Phase 4: Task Completion Celebration (LOW PRIORITY)

### 4.1 Subtle Animation + Sound (20 min)

**Goal:** Positive feedback when completing tasks

**Implementation:**

1. **Add celebration animation**
```swift
// TaskRowView.swift - CheckboxView
@State private var showCelebration = false

Button(action: {
    onToggle()

    if !isCompleted {
        // Trigger celebration
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCelebration = true
        }

        // Play sound
        NSSound(named: "Ping")?.play()

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCelebration = false
        }
    }
}) {
    // Checkbox UI
}
.overlay(
    // Confetti or sparkle effect
    Image(systemName: "sparkles")
        .font(.system(size: 24))
        .foregroundColor(.yellow)
        .opacity(showCelebration ? 1 : 0)
        .scaleEffect(showCelebration ? 1.5 : 0.5)
        .offset(y: showCelebration ? -20 : 0)
)
```

2. **Add setting to disable**
```swift
// SettingsView.swift
Toggle("Completion celebration", isOn: $celebrateCompletions)

// UserDefaultsKeys.swift
extension UserDefaults {
    var celebrateCompletions: Bool {
        get { bool(forKey: "celebrateCompletions") }
        set { set(newValue, forKey: "celebrateCompletions") }
    }
}
```

**User Experience:**
- Complete a task → sparkle appears and floats up
- Subtle "Ping" sound plays (system sound)
- Very brief (0.5s) so not annoying
- Can be disabled in Settings
- Only triggers on completion, not un-completion

**Alternative (even more subtle):**
- Just a gentle scale pulse (1.0 → 1.2 → 1.0) on the checkmark
- No sound unless enabled
- Minimal visual clutter

**Files:**
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/TaskRowView.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/SettingsView.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/UserDefaultsKeys.swift`

---

## Phase 5: Quick Stats (LOW PRIORITY)

### 5.1 Completion Rate & Streak Display (25 min)

**Goal:** Show productivity metrics subtly in header

**Implementation:**

1. **Track completion stats**
```swift
// StatsTracker.swift - new file
class StatsTracker: ObservableObject {
    @Published var todayCompletedCount: Int = 0
    @Published var todayTotalCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0

    func updateStats(tasks: [ThingsTask]) {
        todayCompletedCount = tasks.filter { $0.isCompleted }.count
        todayTotalCount = tasks.count

        // Calculate streak from UserDefaults history
        calculateStreak()
    }

    private func calculateStreak() {
        // Load completion history from UserDefaults
        // Count consecutive days with at least 1 completion
        // Store in currentStreak
    }

    var completionRate: Double {
        guard todayTotalCount > 0 else { return 0 }
        return Double(todayCompletedCount) / Double(todayTotalCount)
    }
}
```

2. **Add to header**
```swift
// ContentView.swift - HeaderView
HStack {
    // Existing: Today, task count

    Spacer()

    // NEW: Stats button (click to expand)
    Button(action: { showStats.toggle() }) {
        HStack(spacing: 4) {
            Image(systemName: "chart.bar.fill")
            Text("\(Int(stats.completionRate * 100))%")
        }
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
    .popover(isPresented: $showStats) {
        StatsPopoverView(stats: stats)
    }
}
```

3. **Stats popover details**
```swift
// StatsPopoverView.swift
struct StatsPopoverView: View {
    let stats: StatsTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                Text("\(stats.todayCompletedCount)/\(stats.todayTotalCount)")
                    .foregroundColor(.secondary)
            }

            ProgressView(value: stats.completionRate)
                .tint(.thingsBlue)

            Divider()

            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Current Streak")
                Spacer()
                Text("\(stats.currentStreak) days")
                    .font(.system(.body, design: .rounded))
            }

            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Longest Streak")
                Spacer()
                Text("\(stats.longestStreak) days")
                    .font(.system(.body, design: .rounded))
            }
        }
        .padding()
        .frame(width: 220)
    }
}
```

4. **Store history in UserDefaults**
```swift
// UserDefaultsKeys.swift
extension UserDefaults {
    var completionHistory: [Date: Int] {
        get {
            guard let data = data(forKey: "completionHistory"),
                  let dict = try? JSONDecoder().decode([Date: Int].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: "completionHistory")
            }
        }
    }
}
```

**User Experience:**
- Header shows completion percentage (e.g., "67%")
- Click to see popover with:
  - Progress bar
  - Current streak (🔥 5 days)
  - Longest streak (🏆 12 days)
- Updates in real-time as tasks are completed
- Minimal visual footprint (just a small percentage)
- Opt-out via Settings if desired

**Files:**
- New: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/StatsTracker.swift`
- New: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/StatsPopoverView.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/ContentView.swift`
- Modified: `/Users/andrewwilkinson/ThingsTodayPanelXcode/Things Today Panel/Things Today Panel/UserDefaultsKeys.swift`

---

## Implementation Order

### Priority 1: Quick Wins (15 min)
1. Fix menu bar item text & keyboard command ✅
2. Add vim j/k navigation ✅

### Priority 2: Core Keyboard Navigation (60 min)
3. Arrow key navigation with NavigationController
4. Quick actions on selected task (Space, Enter, Delete, E)

### Priority 3: Customization (30 min)
5. Customizable hotkey UI in Settings

### Priority 4: Quality of Life (85 min)
6. Undo/redo support
7. Task completion celebration
8. Quick stats display

**Total Implementation Time:** ~3 hours

---

## Design Principles

1. **Minimal First** - No feature should add visual clutter
2. **Keyboard-Centric** - Every action has a keyboard shortcut
3. **Instant Feedback** - Animations confirm actions
4. **Customizable** - Settings for celebration, stats, hotkey
5. **Non-Blocking** - Nothing interrupts the core workflow
6. **Familiar Patterns** - Use standard macOS conventions (⌘Z, ⌘⇧Z, etc.)

---

## Testing Checklist

### Menu Bar Fix
- [ ] Menu shows "Hide Panel" when panel is visible
- [ ] Menu shows "Show Panel" when panel is hidden
- [ ] Keyboard shortcut shows ⌘⇧Y (not ⌘T)
- [ ] Clicking menu item toggles panel correctly

### Keyboard Navigation
- [ ] ↓ arrow selects next task
- [ ] ↑ arrow selects previous task
- [ ] j/k vim keys work identically
- [ ] Wraps at top/bottom of list
- [ ] Selected task has visual highlight
- [ ] Space toggles completion on selected task
- [ ] Enter opens selected task in Things
- [ ] Delete removes selected task
- [ ] E starts editing selected task title
- [ ] Works when panel doesn't have system focus

### Customizable Hotkey
- [ ] Settings shows current hotkey
- [ ] Click to record shows "Press keys..."
- [ ] Recording captures key press
- [ ] Displays in readable format (⌘⇧Y)
- [ ] Hotkey updates globally after saving
- [ ] Menu bar tooltip updates
- [ ] Invalid combinations are rejected

### Undo/Redo
- [ ] ⌘Z undoes last completion
- [ ] ⌘Z undoes last deletion
- [ ] ⌘⇧Z redoes undone action
- [ ] Menu shows action name ("Undo Toggle Task")
- [ ] Stack clears when panel hidden
- [ ] Multiple undo levels work (up to 10)

### Celebration
- [ ] Sparkle appears on task completion
- [ ] Sound plays (if enabled)
- [ ] Animation is brief (0.5s)
- [ ] Doesn't trigger on un-completion
- [ ] Can be disabled in Settings
- [ ] No performance impact

### Stats
- [ ] Completion % shows in header
- [ ] Click opens popover
- [ ] Progress bar updates in real-time
- [ ] Streak calculation is correct
- [ ] History persists across restarts
- [ ] Minimal visual footprint
- [ ] Can be hidden via Settings

---

## Future Enhancements (Not in This Plan)

These were considered but deprioritized based on "stay minimal" philosophy:

- **Inline deadline management** - Would add UI complexity
- **Task details on hover** - Rich tooltips are heavy
- **Bulk actions** - Multi-select adds interaction complexity
- **Snooze/defer** - Requires modal UI or complex gestures
- **Advanced filtering** - Tag/project filters add chrome
- **Drag to reorder** - Things doesn't expose reorder API reliably

If user wants these later, they can be added incrementally.

---

## Summary

This plan adds **powerful keyboard navigation** while keeping the UI **minimal and fast**. Users can:

1. Navigate tasks without touching the mouse (j/k or arrows)
2. Perform all actions via keyboard (Space, Enter, Delete, E)
3. Customize the global hotkey to their preference
4. Undo mistakes with standard ⌘Z
5. Get positive feedback on task completion
6. Track productivity with subtle stats

All features respect the "stay minimal" philosophy with:
- No added visual clutter
- Fast keyboard-first interactions
- Customizable celebrations/stats
- Clean, focused interface

The result is a **delightfully fast task viewer** that rewards keyboard users while staying out of the way.
