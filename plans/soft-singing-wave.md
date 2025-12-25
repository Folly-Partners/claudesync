# Redesign Assessment Section Header with Sticky Progress Bar

## Problem

The current section header in the assessment wizard:
- Nothing is sticky - users lose context when scrolling through long sections (up to 36 questions)
- Progress bar is thin (h-1.5) and easy to miss
- Visual hierarchy is flat
- Description is verbose for repeat viewing

**Current Structure (Wizard.tsx LikertTest, lines ~276-321):**
```
Title ("Social Sensitivity")        Counter ("0/36")
Description paragraph...
┌─────────────────────────────────────┐
│ 📋 Timeframe header (amber box)     │
└─────────────────────────────────────┘
Progress bar (thin, h-1.5)
"Questions 1-10 of 36"
[Questions...]
```

---

## Design Goals

1. **Sticky progress context** - Keep title + progress visible while scrolling
2. **Glass morphism** - Use backdrop blur for elegant sticky header
3. **Better progress visualization** - More prominent, satisfying progress bar
4. **Clean separation** - Description/timeframe scroll away (read once), progress stays

---

## New Design

### Visual Structure

```
┌─────────────────────────────────────────────────────────┐
│ STICKY HEADER (sticks when scrolling)                   │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 🎭 Social Sensitivity                    12 of 36   │ │
│ │ ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │ │
│ └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│ SCROLLABLE CONTENT (scrolls away)                       │
│                                                         │
│ Description text... (if present)                        │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 📋 Timeframe header (amber box)                     │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ Questions 1-10 of 36                                    │
│                                                         │
│ [Questions start here...]                               │
└─────────────────────────────────────────────────────────┘
```

### Visual Treatment

**Sticky Header:**
- Background: `bg-white/90 dark:bg-slate-900/90` with `backdrop-blur-md`
- Border: `border-b border-slate-200/50 dark:border-slate-700/50`
- Padding: `py-3 px-4` with negative margin `-mx-4` to extend edge-to-edge
- z-index: `z-30` (above content)

**Progress Bar:**
- Height: `h-2` (was h-1.5 - slightly more visible)
- Rounded: `rounded-full`
- Background: `bg-slate-200 dark:bg-slate-700`
- Fill: `bg-gradient-to-r from-blue-500 to-blue-600`
- Transition: `transition-all duration-300 ease-out`

**Title Row:**
- Title: `text-lg font-semibold` with optional emoji
- Counter: `text-sm font-medium text-slate-500` with "X of Y" format
- Use `tabular-nums` for stable counter width

---

## Implementation

### File: `components/Wizard.tsx`

#### Change: Restructure LikertTest header (lines ~276-321)

**Before:**
```tsx
{/* Header */}
<div className="mb-6">
  <div className="flex items-center justify-between mb-1">
    <h3 className="text-xl font-bold text-slate-800 dark:text-white">
      {meta?.title || section}
    </h3>
    <span className="text-sm text-slate-500 dark:text-slate-400">
      {answeredCount}/{totalItems}
    </span>
  </div>
  {meta?.description && (
    <p className="text-slate-500 dark:text-slate-400 text-sm mb-3">{meta.description}</p>
  )}
  {meta?.timeframeHeader && (...)}
  <div className="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-1.5 mt-3">
    <div className="bg-blue-600 h-1.5 rounded-full..." />
  </div>
  {showChunking && (...)}
</div>
```

**After:**
```tsx
{/* Sticky Header */}
<div className="sticky top-0 z-30 -mx-4 px-4 py-3 mb-4 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md border-b border-slate-200/50 dark:border-slate-700/50">
  <div className="flex items-center justify-between mb-2">
    <h3 className="text-lg font-semibold text-slate-800 dark:text-white flex items-center gap-2">
      {meta?.emoji && <span>{meta.emoji}</span>}
      {meta?.title || section}
    </h3>
    <span className="text-sm font-medium text-slate-500 dark:text-slate-400 tabular-nums">
      {answeredCount} of {totalItems}
    </span>
  </div>
  <div className="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-2">
    <div
      className="bg-gradient-to-r from-blue-500 to-blue-600 h-2 rounded-full transition-all duration-300 ease-out"
      style={{ width: `${progress}%` }}
    />
  </div>
</div>

{/* Scrollable intro content */}
<div className="mb-6">
  {meta?.description && (
    <p className="text-slate-600 dark:text-slate-400 text-sm mb-3 leading-relaxed">
      {meta.description}
    </p>
  )}
  {meta?.timeframeHeader && (
    <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800/50 rounded-lg px-3 py-2 mb-3">
      <p className="text-amber-800 dark:text-amber-200 text-sm font-medium">
        📋 {meta.timeframeHeader}
      </p>
    </div>
  )}
  {showChunking && (
    <p className="text-xs text-slate-400 dark:text-slate-500 font-medium">
      Questions {startItem + 1}–{Math.min(startItem + CHUNK_SIZE, totalItems)} of {totalItems}
    </p>
  )}
</div>
```

### File: `config/wizard-sections.ts`

#### Change: Add emoji field to SectionMeta and set for all sections

Add `emoji?: string` to `SectionMeta` interface (line 12), then add emoji to each section:

```typescript
// Add to each section in SECTION_META:
'ipip_50':           { emoji: '🧠', ... }  // Brain - personality foundation
'personality_styles': { emoji: '🎭', ... }  // Masks - behavioral patterns
'ecr_s':             { emoji: '💞', ... }  // Hearts - attachment
'csi_16':            { emoji: '💑', ... }  // Couple - relationship
'ders_16':           { emoji: '⚡', ... }  // Zap - emotional regulation
'onet_mini':         { emoji: '💼', ... }  // Briefcase - career
'pvq_21':            { emoji: '⭐', ... }  // Star - values
'weims':             { emoji: '🔥', ... }  // Fire - motivation
'ace':               { emoji: '🛡️', ... }  // Shield - childhood experiences
'gad_7':             { emoji: '😰', ... }  // Anxious - anxiety
'phq_9':             { emoji: '💭', ... }  // Thought - mood
'pcl_5':             { emoji: '🌊', ... }  // Wave - stress/trauma
'dts':               { emoji: '💪', ... }  // Strength - distress tolerance
'rsq':               { emoji: '👥', ... }  // People - social sensitivity
'scs_sf':            { emoji: '🤗', ... }  // Hug - self-compassion
'asrs_18':           { emoji: '🎯', ... }  // Target - focus/attention
'aq_10':             { emoji: '🔮', ... }  // Crystal - social processing
'cat_q':             { emoji: '🦎', ... }  // Chameleon - social adaptation
'sensory_processing': { emoji: '👁️', ... }  // Eye - sensory
'swls':              { emoji: '✨', ... }  // Sparkles - life satisfaction
'ucla_3':            { emoji: '🤝', ... }  // Handshake - connection
'perma':             { emoji: '🌈', ... }  // Rainbow - wellbeing
```

---

## Summary of Changes

| Location | Change |
|----------|--------|
| `Wizard.tsx` lines ~276-321 | Split header into sticky + scrollable parts |
| Sticky header | Add backdrop blur, gradient progress bar |
| Counter format | `X/Y` → `X of Y` for readability |
| Progress bar | `h-1.5` → `h-2`, add gradient fill |
| `wizard-sections.ts` interface | Add `emoji?: string` to SectionMeta |
| `wizard-sections.ts` sections | Add emoji to all 22 sections |

**Total: ~50 lines changed in 2 files**

---

## Expected Result

**Before scrolling:** Full header visible with emoji + title, description, timeframe, progress

**After scrolling:** Clean sticky header with:
- 👥 Social Sensitivity (emoji + title)
- "12 of 36" counter
- Prominent gradient progress bar
- Glass morphism blur effect (semi-transparent with backdrop blur)

The description and timeframe instructions scroll away since they only need to be read once. The sticky header provides constant progress context while feeling integrated with the design.
