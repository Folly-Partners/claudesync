# Book Library Audit & Rebuild Plan

## Summary
Full audit of `lib/curated-books.ts` to remove books by controversial authors and replace with evidence-based recommendations from top clinical researchers.

---

## Books to REMOVE (4 total)

### 1. Gabor Maté - "Scattered Minds" (lines 139-151)
**Category:** ADHD
**Why remove:**
- Dismisses genetic evidence for ADHD (highly heritable condition)
- Attributes ADHD entirely to early environment/trauma
- Implicitly anti-medication
- Russell Barkley and top ADHD researchers consider this view unscientific

### 2. Gabor Maté - "The Myth of Normal" (lines 386-397)
**Category:** Trauma
**Why remove:**
- Overextends trauma explanation to all illness including cancer/MS
- Dismisses genetic factors entirely
- "No single addiction gene" claim is factually false

### 3. Gabor Maté - "In the Realm of Hungry Ghosts" (lines 601-613)
**Category:** Addiction
**Why remove:**
- Same anti-genetic, trauma-only framework
- Better evidence-based addiction books available

### 4. Johann Hari - "Lost Connections" (lines 259-271)
**Category:** Depression
**Why remove:**
- Author has documented plagiarism/fabrication history (resigned from The Independent 2012)
- Anti-medication stance criticized by researchers
- "Is everything Johann Hari knows about depression wrong?" - Guardian science blog
- Not a clinician or researcher

---

## Books to ADD (8 new entries)

### ADHD
| Book | Author | Year | ISBN | Why Add |
|------|--------|------|------|---------|
| 12 Principles for Raising a Child with ADHD | Russell Barkley | 2020 | 9781462542550 | Latest from THE ADHD authority |

### Depression
| Book | Author | Year | ISBN | Why Add |
|------|--------|------|------|---------|
| Get Out of Your Mind and Into Your Life | Steven Hayes | 2005 | 9781572244252 | ABCT recommended; ACT founder |

### Anxiety/OCD
| Book | Author | Year | ISBN | Why Add |
|------|--------|------|------|---------|
| Getting Over OCD (2nd ed) | Jonathan Abramowitz | 2018 | 9781462529704 | ABCT recommended; leading OCD researcher |

### Trauma
| Book | Author | Year | ISBN | Why Add |
|------|--------|------|------|---------|
| Reclaiming Your Life from a Traumatic Experience | Barbara Rothbaum & Edna Foa | 2019 | 9780190926892 | Prolonged Exposure workbook; VA/APA first-line |
| Cognitive Processing Therapy for PTSD | Patricia Resick et al. | 2016 | 9781462528646 | CPT workbook; APA-recommended |

### Sleep
| Book | Author | Year | ISBN | Why Add |
|------|--------|------|------|---------|
| Goodnight Mind | Colleen Carney | 2013 | 9781608826186 | ABCT recommended; CBT-I specialist |
| End the Insomnia Struggle | Colleen Carney | 2016 | 9781626253438 | Evidence-based CBT-I |

### Addiction
| Book | Author | Year | ISBN | Why Add |
|------|--------|------|------|---------|
| Controlling Your Drinking | William Miller | 2013 | 9781462507597 | ABCT recommended; Motivational Interviewing developer |

---

## Update: getBookConstraintInstruction() (lines 873-895)

Current function lists "Scattered Minds" - must update.

**Line 875 change:**
```diff
- 'ADHD: Driven to Distraction, ADHD 2.0, Taking Charge of Adult ADHD, Scattered Minds',
+ 'ADHD: Driven to Distraction, ADHD 2.0, Taking Charge of Adult ADHD, 12 Principles for Raising a Child with ADHD',
```

**Line 877 change:**
```diff
- 'Depression: Feeling Good, Lost Connections, The Upward Spiral, The Mindful Way Through Depression',
+ 'Depression: Feeling Good, The Upward Spiral, The Mindful Way Through Depression, Get Out of Your Mind and Into Your Life',
```

**Add new lines for added categories:**
```typescript
'Sleep: The Sleep Solution, Say Good Night to Insomnia, Goodnight Mind, End the Insomnia Struggle',
'Addiction: Dopamine Nation, This Naked Mind, Controlling Your Drinking',
```

---

## Implementation Steps

1. Remove `Scattered Minds` entry (Gabor Maté, ADHD)
2. Remove `The Myth of Normal` entry (Gabor Maté, Trauma)
3. Remove `In the Realm of Hungry Ghosts` entry (Gabor Maté, Addiction)
4. Remove `Lost Connections` entry (Johann Hari, Depression)
5. Add 8 new book entries with full structure
6. Update `getBookConstraintInstruction()` approved list

---

## File Modified

| File | Changes |
|------|---------|
| `lib/curated-books.ts` | Remove 5 books, add 8 books, update constraint function |

---

## Verification

After implementation:
- `grep -r "Maté\|Mate" lib/` → 0 results
- `grep -r "Hari" lib/` → 0 results
- `getBooksForCondition('adhd')` → Should not return Scattered Minds
- `getBookConstraintInstruction()` → Should not mention removed books
