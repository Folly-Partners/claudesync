# Replace Emojis with Lucide SVG Icons in AI Reports

## Overview

Replace all emojis in AI personality reports with elegant Lucide SVG icons rendered at the React level. The codebase already has `lucide-react` installed and infrastructure for icon mapping.

## Architecture

**Two-part approach:**
1. **Prompts** - Remove emojis, use plain text section titles
2. **React Components** - Detect section titles and render appropriate Lucide icons

## Current Infrastructure

- **lucide-react** v0.468.0 already installed
- **react-markdown** renders AI analysis with custom `MarkdownComponents`
- **BentoTOC.tsx** already maps section titles to Lucide icons
- **Dashboard.tsx** has conditional h2/h3 icon rendering

## Files to Modify

| File | Changes |
|------|---------|
| `/services/analyze/prompts.ts` | Remove all emojis from section titles |
| `/components/Dashboard.tsx` | Extend MarkdownComponents for section icons |
| `/components/BentoTOC.tsx` | Update icon mapping (remove emoji detection) |
| `/app/share/[code]/page.tsx` | Mirror Dashboard MarkdownComponents changes |

## Implementation

### Step 1: Update AI Prompts (prompts.ts)

Remove emojis from all 14 clinical section titles:

| Before | After |
|--------|-------|
| `"🧠 How Your Mind Works Differently"` | `"How Your Mind Works Differently"` |
| `"🧩 Your Autistic Neurotype"` | `"Your Autistic Neurotype"` |
| etc. | etc. |

Also add prompt instruction:
```
FORMATTING: Do NOT use emojis in headers or tables. Use plain text only.
For tables, use simple headers like "Gifts" and "Challenges" without symbols.
```

### Step 2: Create Section Icon Mapping (Dashboard.tsx)

Add a mapping function to select icons based on section title content:

```typescript
import { Brain, Puzzle, Sparkles, CloudRain, Flame, Sprout,
         Theater, Battery, Target, Users, Link2, AlertTriangle,
         Repeat, Heart, Briefcase, Home, Star, Shield, Swords } from 'lucide-react';

const getSectionIcon = (title: string): React.ReactNode => {
  const lower = title.toLowerCase();

  // Clinical sections
  if (lower.includes('mind works') || lower.includes('adhd')) return <Brain className="w-5 h-5" />;
  if (lower.includes('autistic') || lower.includes('neurotype')) return <Puzzle className="w-5 h-5" />;
  if (lower.includes('senses') || lower.includes('heightened')) return <Sparkles className="w-5 h-5" />;
  if (lower.includes('anxiety')) return <AlertTriangle className="w-5 h-5" />;
  if (lower.includes('heavy') || lower.includes('depression')) return <CloudRain className="w-5 h-5" />;
  if (lower.includes('past') || lower.includes('trauma') || lower.includes('ptsd')) return <Flame className="w-5 h-5" />;
  if (lower.includes('weight') || lower.includes('carrying') || lower.includes('ace')) return <Sprout className="w-5 h-5" />;
  if (lower.includes('shadow') || lower.includes('dark')) return <Theater className="w-5 h-5" />;
  if (lower.includes('empty') || lower.includes('burnout')) return <Battery className="w-5 h-5" />;
  if (lower.includes('good enough') || lower.includes('perfectionism')) return <Target className="w-5 h-5" />;
  if (lower.includes('judged') || lower.includes('social anxiety')) return <Users className="w-5 h-5" />;
  if (lower.includes('lose yourself') || lower.includes('codependency')) return <Link2 className="w-5 h-5" />;
  if (lower.includes('coping') || lower.includes('vulnerabilities')) return <Shield className="w-5 h-5" />;
  if (lower.includes('habits') || lower.includes('control') || lower.includes('compulsive')) return <Repeat className="w-5 h-5" />;

  // Main sections
  if (lower.includes('superpowers') || lower.includes('strengths')) return <Star className="w-5 h-5" />;
  if (lower.includes('growth')) return <Sprout className="w-5 h-5" />;
  if (lower.includes('ideal life')) return <Home className="w-5 h-5" />;
  if (lower.includes('relationship') || lower.includes('romantic')) return <Heart className="w-5 h-5" />;
  if (lower.includes('work') || lower.includes('career')) return <Briefcase className="w-5 h-5" />;
  if (lower.includes('conflict') || lower.includes('friction')) return <Swords className="w-5 h-5" />;

  return null;
};
```

### Step 3: Update MarkdownComponents h2 Renderer

```typescript
h2: ({ children }) => {
  const text = String(children);
  const icon = getSectionIcon(text);

  return (
    <h2 className="text-xl font-bold mt-8 mb-4 flex items-center gap-2 text-white">
      {icon && <span className="text-blue-400">{icon}</span>}
      {text}
    </h2>
  );
}
```

### Step 4: Update Table Header Rendering for Gifts/Challenges

```typescript
th: ({ children }) => {
  const text = String(children).toLowerCase();
  let icon = null;
  let colorClass = 'text-gray-300';

  if (text.includes('gift') || text.includes('strength')) {
    icon = <Star className="w-4 h-4" />;
    colorClass = 'text-emerald-400';
  } else if (text.includes('challenge') || text.includes('growth')) {
    icon = <AlertTriangle className="w-4 h-4" />;
    colorClass = 'text-amber-400';
  } else if (text.includes('match')) {
    icon = <Check className="w-4 h-4" />;
    colorClass = 'text-emerald-400';
  } else if (text.includes('mismatch') || text.includes('friction')) {
    icon = <X className="w-4 h-4" />;
    colorClass = 'text-rose-400';
  }

  return (
    <th className={`px-4 py-3 font-semibold ${colorClass} flex items-center gap-2`}>
      {icon}
      {children}
    </th>
  );
}
```

### Step 5: Update BentoTOC Icon Mapping

Remove emoji detection from `getIconAndStyle()`, use title-based matching only.

## Icon Selection Guide

| Section Type | Lucide Icon | Rationale |
|--------------|-------------|-----------|
| ADHD | `Brain` | Cognitive/mental |
| Autism | `Puzzle` | Neurodiversity |
| Sensory | `Sparkles` | Heightened perception |
| Anxiety | `AlertTriangle` | Warning/alert |
| Depression | `CloudRain` | Heavy weather |
| PTSD/Trauma | `Flame` | Intense/burning |
| ACE | `Sprout` | Growth from adversity |
| Dark Triad | `Theater` | Masks/persona |
| Burnout | `Battery` | Energy depletion |
| Perfectionism | `Target` | Precision |
| Social Anxiety | `Users` | Social context |
| Codependency | `Link2` | Connection/attachment |
| Substance Risk | `Shield` | Protection |
| Compulsive | `Repeat` | Cycles |
| Gifts | `Star` | Positive highlight |
| Challenges | `AlertTriangle` | Amber caution |
| Match | `Check` | Confirmation |
| Mismatch | `X` | Conflict |

## Checklist

### Prompts (prompts.ts)
- [ ] Remove emoji from ADHD section title
- [ ] Remove emoji from Autism section title
- [ ] Remove emoji from Sensory section title
- [ ] Remove emoji from Anxiety section title
- [ ] Remove emoji from Depression section title
- [ ] Remove emoji from PTSD section title
- [ ] Remove emoji from ACE section title
- [ ] Remove emoji from Dark Triad section title
- [ ] Remove emoji from Burnout section title
- [ ] Remove emoji from Perfectionism section title
- [ ] Remove emoji from Social Anxiety section title
- [ ] Remove emoji from Codependency section title
- [ ] Remove emoji from Substance Risk section title
- [ ] Remove emoji from Compulsive section title
- [ ] Add "no emoji" formatting instruction to prompts
- [ ] Remove emoji table markers (✅⚠️❌) from example tables

### Dashboard.tsx
- [ ] Add getSectionIcon() function
- [ ] Import additional Lucide icons
- [ ] Update h2 component to use icons
- [ ] Update th component for table headers
- [ ] Update h3 to remove emoji handling

### BentoTOC.tsx
- [ ] Update getIconAndStyle() to remove emoji matching
- [ ] Use title-based icon selection only

### Share Page
- [ ] Mirror all Dashboard.tsx MarkdownComponents changes

### Testing
- [ ] Regenerate a report to verify no emojis appear
- [ ] Verify icons render correctly in sections
- [ ] Verify table headers show appropriate icons
- [ ] Test comparison report rendering
